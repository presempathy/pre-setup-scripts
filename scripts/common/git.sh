#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

git_detect() {
  if command_exists git; then
    say "${GREEN}${CHECK} git found: $(git --version)${RESET}"
    return 0
  else
    say "${YELLOW}${DOT} git not found${RESET}"
    return 1
  fi
}

git_install_native() {
  say "${BLUE}${DOT} Installing git using native package manager${RESET}"
  confirm "Attempt to install git?" || return 1
  if [ -f /etc/debian_version ]; then
    require_sudo || return 1
    run "sudo apt-get update" && run "sudo apt-get install -y git"
  elif command -v pacman >/dev/null 2>&1; then
    require_sudo || return 1
    run "sudo pacman -Sy --noconfirm git"
  elif command -v dnf >/dev/null 2>&1; then
    require_sudo || return 1
    run "sudo dnf install -y git"
  elif command -v zypper >/dev/null 2>&1; then
    require_sudo || return 1
    run "sudo zypper install -y git"
  elif [ "$(uname -s)" = "Darwin" ]; then
    say "${YELLOW}${DOT} On macOS, git may be installed via Xcode Command Line Tools.${RESET}"
    run "xcode-select --install" || true
  else
    say "${RED}${CROSS} Unsupported auto-install path for git on this OS.${RESET}"
    return 1
  fi
  git_detect
}

git_configure_best_practices() {
  local name="$1"; local email="$2"
  run "git config --global init.defaultBranch main"
  run "git config --global pull.rebase false"
  run "git config --global fetch.prune true"
  case "$(uname -s)" in
    Darwin) run "git config --global core.autocrlf input" ;;
    *) run "git config --global core.autocrlf input" ;;
  esac
  if [ -n "$name" ]; then run "git config --global user.name \"${name}\""; fi
  if [ -n "$email" ]; then run "git config --global user.email \"${email}\""; fi

  if [ "$(uname -s)" = "Darwin" ] && command_exists git && git help -a 2>/dev/null | grep -q osxkeychain; then
    run "git config --global credential.helper osxkeychain" || true
  elif command_exists git-credential-libsecret; then
    run "git config --global credential.helper libsecret" || true
  fi
}
