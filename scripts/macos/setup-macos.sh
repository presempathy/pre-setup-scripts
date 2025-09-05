#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON="${DIR}/../common"

. "${COMMON}/lib.sh"
. "${COMMON}/uv.sh"
. "${COMMON}/git.sh"
. "${COMMON}/ssh.sh"
. "${COMMON}/github.sh"

main() {
  title
  say "${BOLD}macOS setup starting...${RESET}"
  if ! xcode-select -p >/dev/null 2>&1; then
    say "${BLUE}${DOT} Installing Xcode Command Line Tools${RESET}"
    xcode-select --install || true
    pause
  fi
  "${DIR}/../linux/setup-linux.sh"
}

main "$@"
