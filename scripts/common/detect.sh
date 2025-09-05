#!/usr/bin/env bash
set -euo pipefail

detect_os() {
  uname_s="$(uname -s 2>/dev/null || echo unknown)"
  case "$uname_s" in
    Linux*) echo "linux" ;;
    Darwin*) echo "macos" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

detect_linux_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    id_like_lc="$(echo "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"
    id_lc="$(echo "${ID:-}" | tr '[:upper:]' '[:lower:]')"
    echo "${id_lc}:${id_like_lc}:${VERSION_ID:-}"
  else
    echo "unknown::"
  fi
}

detect_nixos() {
  if [ -e /etc/NIXOS ] || [ -x /run/current-system/sw/bin/nix ]; then
    echo 1
  else
    echo 0
  fi
}

detect_container() {
  if [ -f /.dockerenv ]; then
    echo 1
    return
  fi
  if grep -qaE '(docker|lxc|containerd|kubepods)' /proc/1/cgroup 2>/dev/null; then
    echo 1
  else
    echo 0
  fi
}

detect_nixos() {
  if [ -e /etc/NIXOS ] || [ -x /run/current-system/sw/bin/nix ]; then
    echo 1
  else
    echo 0
  fi
}

detect_container() {
  if [ -f /.dockerenv ]; then
    echo 1
    return
  fi
  if grep -qaE '(docker|lxc|containerd|kubepods)' /proc/1/cgroup 2>/dev/null; then
    echo 1
  else
    echo 0
  fi
}
