#!/usr/bin/env bash
set -euo pipefail

PRESEMPATHY_BRAND="Presempathy"
LOG_DIR="${HOME}/.presempathy-setup/logs"
LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${LOG_DIR}"

SHOW_COMMANDS="${SHOW_COMMANDS:-0}"
NO_ANSI="${NO_ANSI:-0}"

if [ -t 1 ] && [ "${NO_ANSI}" != "1" ] && command -v tput >/dev/null 2>&1; then
  tput colors >/dev/null 2>&1 || true
  BOLD="$(tput bold || true)"; RESET="$(tput sgr0 || true)"
  BLUE="$(tput setaf 33 || true)"; CYAN="$(tput setaf 6 || true)"
  GREEN="$(tput setaf 2 || true)"; YELLOW="$(tput setaf 3 || true)"; RED="$(tput setaf 1 || true)"
else
  BOLD=""; RESET=""; BLUE=""; CYAN=""; GREEN=""; YELLOW=""; RED=""
fi
CHECK="✔"; CROSS="✖"; DOT="•"; ARROW="➜"

log() {
  printf "%s\n" "$*" | sed -e "s/\x1b\[[0-9;]*m//g" >> "${LOG_FILE}"
}
say() { printf "%b\n" "$*"; log "$*"; }
hr() { say "${BLUE}────────────────────────────────────────────────────────────${RESET}"; }

title() {
  clear || true
  hr
  say "${BOLD}${BLUE}Welcome to ${PRESEMPATHY_BRAND}${RESET}"
  hr
}

confirm() {
  local prompt="${1:-Proceed?} [Y/n]: "
  read -r -p "$(printf "%b" "${BOLD}${prompt}${RESET}")" ans || true
  case "${ans:-Y}" in
    y|Y|yes|YES|"") return 0 ;;
    *) return 1 ;;
  esac
}

render_dashboard() {
  clear || true
  hr
  say "${BOLD}${BLUE}Welcome to ${PRESEMPATHY_BRAND}${RESET}"
  hr
  if command_exists uv; then
    say "uv: $(uv --version 2>/dev/null || echo found)"
  else
    say "uv: not found"
  fi
  if command_exists python3; then
    say "python3: $(python3 --version 2>/dev/null || echo found)"
  else
    say "python3: not found"
  fi
  if command_exists git; then
    say "git: $(git --version 2>/dev/null || echo found)"
  else
    say "git: not found"
  fi
  if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
    say "ssh key: present"
  else
    say "ssh key: missing"
  fi
}
pause() { read -r -p "Press Enter to continue..." _ || true; }

show_cmd() {
  if [ "${SHOW_COMMANDS}" = "1" ]; then
    say "${CYAN}${ARROW} ${1}${RESET}"
  fi
  log "\$ $1"
}

run() {
  show_cmd "$*"
  if [ "${DRY_RUN:-false}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
    say "${YELLOW}${DOT} dry-run, command not executed${RESET}"
    return 0
  fi
  if eval "$@"; then
    say "${GREEN}${CHECK} ok${RESET}"
    return 0
  else
    say "${RED}${CROSS} failed${RESET}"
    return 1
  fi
}

ensure_line_once() {
  local file="$1"; shift
  local line="$*"
  [ -f "${file}" ] || touch "${file}"
  if ! grep -Fqs -- "${line}" "${file}"; then
    printf "%s\n" "${line}" >> "${file}"
  fi
}

require_sudo() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    say "${YELLOW}${DOT} This action requires elevated privileges.${RESET}"
    confirm "Use sudo?" || return 1
  fi
  return 0
}

detect_shell_rc_files() {
  [ -n "${HOME:-}" ] || return 0
  [ -f "${HOME}/.bashrc" ] && echo "${HOME}/.bashrc"
  [ -f "${HOME}/.zshrc" ] && echo "${HOME}/.zshrc"
  [ -f "${HOME}/.profile" ] && echo "${HOME}/.profile"
  [ -f "${HOME}/.bash_profile" ] && echo "${HOME}/.bash_profile"
  [ -f "${HOME}/.config/fish/config.fish" ] && echo "${HOME}/.config/fish/config.fish"
}

path_export_snippet() {
  local dir="$1"
  cat <<EOF
if [ -d "${dir}" ] && ! echo ":\$PATH:" | grep -q ":\${dir}:"; then
  export PATH="\${PATH}:${dir}"
fi
EOF
}

persist_path_dir() {
  local dir="$1"
  detect_shell_rc_files | while read -r rc; do
    local tmp
    tmp="$(mktemp)"
    if [ -f "${rc}" ]; then
      awk 'BEGIN{skip=0} />>> prese setup PATH >>>/{skip=1} /<<< prese setup PATH <<</{skip=0; next} skip==0{print}' "${rc}" > "${tmp}" || true
      mv "${tmp}" "${rc}"
    fi
    path_export_snippet "${dir}" >> "${rc}"
  done
  say "${GREEN}${CHECK} PATH updated to include ${dir}${RESET}"
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

menu_select() {
  local title="$1"; shift
  local options=("$@")
  local selected=0 key
  stty -echo -icanon time 0 min 1 2>/dev/null || true
  trap 'stty echo icanon >/dev/null 2>&1 || true; echo' EXIT
  while true; do
    printf "\033[H\033[2J" || true
    hr; say "${BOLD}${title}${RESET}"; hr
    for i in "${!options[@]}"; do
      if [ "$i" -eq "$selected" ]; then
        say "${CYAN}> ${options[$i]}${RESET}"
      else
        say "  ${options[$i]}"
      fi
    done
    IFS= read -rsn1 key || key=""
    case "$key" in
      $'\x1b')
        read -rsn2 key || true
        case "$key" in
          "[A") [ $selected -gt 0 ] && selected=$((selected-1)) ;;
          "[B") [ $selected -lt $((${#options[@]}-1)) ] && selected=$((selected+1)) ;;
        esac
        ;;
      $'\x0a'|$'\x0d')
        stty echo icanon >/dev/null 2>&1 || true
        trap - EXIT
        echo "$selected"
        return 0
        ;;
      q|Q)
        stty echo icanon >/dev/null 2>&1 || true
        trap - EXIT
        return 1
        ;;
    esac
  done
}

validate_email() {
  local email="$1"
  case "$email" in
    *"@"*.*) return 0 ;;
    *) return 1 ;;
  esac
}
