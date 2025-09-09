#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

uv_detect() {
  if command_exists uv; then
    say "${GREEN}${CHECK} uv found: $(uv --version 2>/dev/null || echo unknown)${RESET}"
    return 0
  else
    say "${YELLOW}${DOT} uv not found${RESET}"
    return 1
  fi
}

uv_install() {
  say "${BLUE}${DOT} Installing/updating uv${RESET}"
  confirm "Install uv via official installer?" || return 1
  run "curl -fsSL https://astral.sh/uv/install.sh | sh" || return 1
  for d in "${HOME}/.local/bin" "${HOME}/.cargo/bin" "${HOME}/.uv/bin"; do
    [ -d "$d" ] && persist_path_dir "$d"
  done
  command_exists uv || export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${HOME}/.uv/bin:${PATH}"
  uv_detect
}

uv_upgrade_if_needed() {
  if command_exists uv; then
    say "${BLUE}${DOT} Checking uv upgrade${RESET}"
    run "uv self update" || true
    uv_detect
  fi
}

uv_python_latest_install_and_select() {
  say "${BLUE}${DOT} Installing latest stable Python via uv${RESET}"
  if confirm "Set latest Python as global default for uv?"; then
    run "uv python install --default" || return 1
  else
    run "uv python install" || return 1
  fi
  run "uv python list"
}
