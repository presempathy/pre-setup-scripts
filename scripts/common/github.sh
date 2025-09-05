#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

github_check_username_exists() {
  local username="$1"
  if curl -fsSL "https://api.github.com/users/${username}" >/dev/null 2>&1; then
    say "${GREEN}${CHECK} GitHub user exists: ${username}${RESET}"
    return 0
  else
    say "${RED}${CROSS} GitHub user not found: ${username}${RESET}"
    return 1
  fi
}

github_upload_ssh_key_with_pat() {
  local pat="$1"
  local title="$2"
  local pubkey_path="${HOME}/.ssh/id_ed25519.pub"
  [ -f "${pubkey_path}" ] || { say "${RED}${CROSS} Missing public key at ${pubkey_path}${RESET}"; return 1; }
  local key
  key="$(cat "${pubkey_path}")"
  say "${BLUE}${DOT} Uploading SSH key to GitHub via API${RESET}"
  run "curl -fsSL -H \"Authorization: token ${pat}\" -H \"Accept: application/vnd.github+json\" -X POST https://api.github.com/user/keys -d '{\"title\":\"${title}\",\"key\":\"${key}\"}' >/dev/null"
}
