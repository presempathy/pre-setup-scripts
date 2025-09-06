# Presempathy — Pre-Setup Scripts

Welcome to Presempathy

This repository provides zero-dependency, enterprise-grade onboarding scripts for Windows, macOS, and Linux (Ubuntu, Debian, Manjaro/Arch, NixOS, Debian-in-Docker). The scripts install and configure uv and Python, set up Git and SSH for GitHub, and validate access by cloning the presempathy/setup-local-dev repository. They feature an ANSI-first interactive UI with a text-only fallback.

Quick Start
- macOS:
  - curl -fsSL https://raw.githubusercontent.com/presempathy/pre-setup-scripts/main/scripts/macos/setup-macos.sh | bash
- Linux:
  - curl -fsSL https://raw.githubusercontent.com/presempathy/pre-setup-scripts/main/scripts/linux/setup-linux.sh | bash
- Windows (PowerShell):
  - Invoke-WebRequest https://raw.githubusercontent.com/presempathy/pre-setup-scripts/main/scripts/windows/setup-windows.ps1 -UseBasicParsing | Invoke-Expression
Options & Tips
- Dry-run: DRY_RUN=1 scripts/linux/setup-linux.sh (preview actions without changes)
- Show commands: SHOW_COMMANDS=1 (echo exact commands executed; always logged to ~/.presempathy-setup/logs)
- No ANSI: NO_ANSI=1 (text-only fallback UI)
- Windows ExecutionPolicy: run PowerShell as Administrator and Set-ExecutionPolicy -Scope CurrentUser Bypass if needed
- PATH persistence: scripts add ~/.uv/bin, ~/.local/bin, ~/.cargo/bin idempotently to common shell rc files



Goals
- Install latest uv and stable Python via uv; ensure on PATH and optionally set as global default.
- Configure Git with best-practice defaults and your identity.
- Generate secure SSH keys, configure ~/.ssh/config, and upload to GitHub.
- Validate via ssh -T git@github.com and cloning presempathy/setup-local-dev.
- Provide clean, beautiful interactive UX with HITL checkpoints, exact command echoing, and robust error handling.

See RULES.md for the detailed contract and architecture.
