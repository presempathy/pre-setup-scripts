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
  local tmp_headers
  tmp_headers="$(mktemp)"
  local tmp_body
  tmp_body="$(mktemp)"
  if bash -lc "curl -sS -D '${tmp_headers}' -o '${tmp_body}' -H 'Authorization: token ${pat}' -H 'Accept: application/vnd.github+json' -X POST https://api.github.com/user/keys -d '{\"title\":\"${title}\",\"key\":\"${key}\"}'"; then
    local status
    status="$(head -n1 "${tmp_headers}" | awk '{print $2}')"
    local remain
    remain="$(awk -F': ' 'tolower($1)==\"x-ratelimit-remaining\"{gsub(/\\r/,\"\",$2); print $2}' "${tmp_headers}" | tail -n1)"
    if [ "${status}" = "201" ] || [ "${status}" = "200" ]; then
      say "${GREEN}${CHECK} Key uploaded${RESET}"
      rm -f "${tmp_headers}" "${tmp_body}"
      return 0
    else
      say "${YELLOW}${DOT} GitHub API returned status ${status}${RESET}"
      if [ -n "${remain:-}" ] && [ "${remain}" = "0" ]; then
        say "${YELLOW}Rate limit reached. Please wait and retry, or upload manually at https://github.com/settings/keys.${RESET}"
      fi
      say "Response:"
      sed -e 's/[[:cntrl:]]//g' "${tmp_body}" | head -n 20 || true
      rm -f "${tmp_headers}" "${tmp_body}"
      return 1
    fi
  else
    say "${RED}${CROSS} API call failed. Please upload manually at https://github.com/settings/keys.${RESET}"
    say "Public key path: ${pubkey_path}"
    rm -f "${tmp_headers}" "${tmp_body}"
    return 1
  fi
}
