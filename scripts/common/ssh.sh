#!/usr/bin/env bash
set -euo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ssh_ensure_permissions() {
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  [ -f "${HOME}/.ssh/config" ] && chmod 600 "${HOME}/.ssh/config" || true
}

ssh_generate_key_if_missing() {
  local key="${HOME}/.ssh/id_ed25519"
  if [ -f "${key}" ]; then
    say "${GREEN}${CHECK} SSH key exists: ${key}${RESET}"
  else
    say "${BLUE}${DOT} Generating SSH key (ed25519)${RESET}"
    local email="$1"
    run "ssh-keygen -t ed25519 -C \"${email}\" -f \"${key}\" -N \"\"" || return 1
  fi
  if [ -f "${key}" ]; then chmod 600 "${key}"; fi
  if [ -f "${key}.pub" ]; then chmod 644 "${key}.pub"; fi
}

ssh_configure_github() {
  local key="${HOME}/.ssh/id_ed25519"
  ssh_ensure_permissions
  local cfg="${HOME}/.ssh/config"
  touch "${cfg}"
  chmod 600 "${cfg}"
  awk 'BEGIN{skip=0}
    /# >>> prese github >>>/ {skip=1}
    /# <<< prese github <<</ {skip=0; next}
    skip==0{print}' "${cfg}" > "${cfg}.tmp" || true
  mv "${cfg}.tmp" "${cfg}"
  {
    echo "# >>> prese github >>>"
    cat <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ${key}
  IdentitiesOnly yes
  AddKeysToAgent yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
EOF
    if [ "$(uname -s)" = "Darwin" ]; then
      echo "  UseKeychain yes"
    fi
    echo "# <<< prese github <<<"
  } >> "${cfg}"
  say "${GREEN}${CHECK} ssh config updated for GitHub${RESET}"
}

ssh_add_to_agent() {
  if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
  fi
  if [ -f "${HOME}/.ssh/id_ed25519" ]; then
    run "ssh-add -q \"${HOME}/.ssh/id_ed25519\"" || true
  fi
}

ssh_test_github() {
  say "${BLUE}${DOT} Testing GitHub SSH connectivity${RESET}"
  set +e
  out="$(ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1)"
  code="$?"
  set -e
  say "$out"
  if echo "$out" | grep -qi "successfully authenticated" || echo "$out" | grep -qi "Hi .*! You've successfully authenticated"; then
    return 0
  fi
  return "$code"
}
