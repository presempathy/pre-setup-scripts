#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON="${DIR}/../common"

. "${COMMON}/lib.sh"
. "${COMMON}/detect.sh"
. "${COMMON}/uv.sh"
. "${COMMON}/git.sh"
. "${COMMON}/ssh.sh"
. "${COMMON}/github.sh"

DRY_RUN="${DRY_RUN:-false}"

main() {
  title
  say "${BOLD}This script will prepare your system for Presempathy development.${RESET}"
  say "It will install and configure uv, Python, git, and SSH for GitHub."
  hr

  read -r -p "What is your name? " full_name || full_name=""
  while [ -z "${full_name%% *}" ]; do
    read -r -p "Please enter at least a first name: " full_name || full_name=""
  done
  first_name="${full_name%% *}"

  read -r -p "Do you have a GitHub account? [Y/n]: " has_gh || has_gh="Y"
  case "${has_gh:-Y}" in n|N|no|NO)
    say "${YELLOW}Please create one at https://github.com/signup and rerun this script.${RESET}"
    exit 1;;
  esac

  read -r -p "What is your GitHub username? " gh_user || gh_user=""
  github_check_username_exists "${gh_user}" || { say "${RED}Cannot proceed without a valid GitHub username.${RESET}"; exit 1; }

  read -r -p "What is your GitHub email address? " gh_email || gh_email=""
  until validate_email "${gh_email}"; do
    read -r -p "That email looks invalid. Enter a valid email: " gh_email || gh_email=""
  done

  hr
  say "${BOLD}Status report:${RESET}"
  command_exists uv && say "uv: $(uv --version 2>/dev/null || echo found)" || say "uv: not found"
  command_exists python3 && say "python3: $(python3 --version 2>/dev/null || echo found)" || say "python3: not found"
  command_exists git && say "git: $(git --version 2>/dev/null || echo found)" || say "git: not found"
  [ -f "${HOME}/.ssh/id_ed25519.pub" ] && say "ssh key: present" || say "ssh key: missing"
  hr

  uv_detect || uv_install
  uv_upgrade_if_needed
  uv_python_latest_install_and_select || true

  git_detect || git_install_native
  git_configure_best_practices "${full_name}" "${gh_email}"

  ssh_ensure_permissions
  ssh_generate_key_if_missing "${gh_email}"
  ssh_configure_github
  ssh_add_to_agent

  hr
  say "${BOLD}GitHub SSH key upload:${RESET}"
  say "You can provide a short-lived Personal Access Token with permission to manage SSH keys."
  say "Alternatively, we’ll guide you to upload manually."
  read -r -s -p "Paste GitHub PAT (leave empty to skip): " gh_pat || gh_pat=""
  echo
  if [ -n "${gh_pat}" ]; then
    github_upload_ssh_key_with_pat "${gh_pat}" "Presempathy Setup ($(hostname))" || say "${YELLOW}Upload via API failed; will guide manual upload.${RESET}"
  fi
  if [ -z "${gh_pat}" ]; then
    say "${BLUE}Manual upload steps:${RESET}"
    say "1) Open https://github.com/settings/keys"
    say "2) Click New SSH key"
    say "3) Title: Presempathy Setup ($(hostname))"
    say "4) Key: paste the following:"
    say "----- BEGIN PUBLIC KEY -----"
    if [ -f "${HOME}/.ssh/id_ed25519.pub" ]; then
      cat "${HOME}/.ssh/id_ed25519.pub"
    else
      say "${RED}Public key not found.${RESET}"
    fi
    say "----- END PUBLIC KEY -----"
    pause
  fi

  ssh_test_github || {
    say "${YELLOW}SSH test did not succeed. We will continue to repo clone test which will likely fail.${RESET}"
  }

  hr
  say "${BOLD}Testing repository access (SSH):${RESET}"
  mkdir -p "${HOME}/presempathy-tests"
  cd "${HOME}/presempathy-tests"
  run "git clone git@github.com:presempathy/setup-local-dev.git" || {
    say "${RED}${CROSS} Clone failed. Likely access issue.${RESET}"
    say "${BOLD}We will craft an email to awb@presempathy.com requesting access.${RESET}"
    echo "To: awb@presempathy.com
Subject: Request access to presempathy/setup-local-dev

Hi Andrew,

This is ${full_name} (${gh_user}) requesting access to the repository presempathy/setup-local-dev.
I ran the onboarding script and SSH setup completed, but cloning was denied.

Personal note (fill in here):

Thanks!
" > "${HOME}/presempathy-tests/request-access-email.txt"
    say "Draft saved at: ${HOME}/presempathy-tests/request-access-email.txt"
    exit 1
  }

  say "${GREEN}${CHECK} All good, ${first_name}! Your environment is ready.${RESET}"
}

main "$@"
