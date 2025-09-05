# Presempathy Setup Scripts — Rules and Reference

Purpose
- Enterprise-grade, zero-external-dependency onboarding scripts for Windows, macOS, and Linux (Ubuntu, Debian, Manjaro/Arch, NixOS, Debian-in-Docker).
- Primary auth is GitHub over SSH, fully verified end-to-end by cloning presempathy/setup-local-dev.
- ANSI-first interactive UI with arrow keys and beautiful minimal output; text-only fallback for dumb terminals.
- Idempotent, safe, explicit user consent for privileged changes; echo exact commands executed; robust error handling.

Operating Systems
- Windows: Current and major supported versions via PowerShell (pwsh/cmd compatible invocation).
- macOS: Current and major supported versions via POSIX shell (bash/zsh).
- Linux: Ubuntu, Debian, Manjaro/Arch, NixOS, and Debian-in-Docker via POSIX shell.

Core Goals
1) uv installed/updated to latest; in PATH; optionally set as default package manager.
2) Latest stable Python installed via uv; optionally set as global default.
3) PATH persisted across shells (bash/zsh/fish/pwsh) idempotently.
4) git installed and configured with best-practice defaults; user.name/email set.
5) SSH: secure ed25519 key generation; ssh-agent/Keychain integration; ~/.ssh/config best-practice entries; permissions validated.
6) GitHub SSH auth: upload public key via API (device/PAT when available) or guide manual; verify ssh -T git@github.com.
7) Validate by cloning https://github.com/presempathy/setup-local-dev.
8) If access denied, craft an email to awb@presempathy.com with a user-editable note.

UX Standards
- ANSI-first TUI: arrow keys for menus, clear prompts, progress spinners, success/failure badges.
- Minimal redraw: single-screen dashboard; no spammy scrolling.
- Text-only fallback: plain prompts when ANSI not supported.
- HITL checkpoints: ask for consent for sudo/privileged ops and environment changes.
- Always display exact commands when actions are taken; also save to ~/.presempathy-setup/logs.

Security & Privacy
- Never store tokens unencrypted on disk. Prefer in-memory usage only.
- SSH keys: ed25519, correct permissions, added to agent only for current user; optional Keychain on macOS.
- ~/.ssh/config entries limited in scope and idempotent.
- Logs: redact secrets; store locally under ~/.presempathy-setup/logs.

Git Best Practices (defaults)
- init.defaultBranch: main
- pull.rebase: false
- fetch.prune: true
- core.autocrlf: input on macOS/Linux; true on Windows
- commit.gpgSign: prompt user; don’t enable by default without keys
- credential.helper:
  - macOS: osxkeychain (if available)
  - Linux: libsecret (if available), otherwise none
  - Windows: manager-core (if available)
- user.name / user.email: prompt and validate; ensure GitHub email matches supplied value.

SSH Best-Practice Defaults
- Key type: ed25519 (fallback to rsa -b 4096 only if ed25519 unsupported)
- ~/.ssh/config entries:
  Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes        (macOS only)
    ServerAliveInterval 60
    ServerAliveCountMax 3
- Permissions: ~/.ssh 700, private key 600, public key 644, config 600
- Agent: launch as appropriate per OS; ensure key is loaded.

GitHub SSH Key Upload
- Preferred: OAuth device flow or PAT with “Manage SSH keys” scope to POST /user/keys.
- Fallback: manual guide with copied key and link to https://github.com/settings/keys.
- Verify: ssh -T git@github.com must greet with username.

Behavioral Guarantees
- Safe to re-run: all steps check current state, only make necessary changes.
- Clear errors with actionable remediation; loop to failed step.
- Dry-run mode: show planned actions and commands without changing system.
- Per-OS variations encapsulated in shared library functions for reuse.

Repository Layout
- scripts/
  - common/
    - lib.sh        (ANSI UI, logging, prompts, idempotent helpers)
    - detect.sh     (OS/shell detection)
    - github.sh     (device flow, API calls)
    - ssh.sh        (keygen, config, agent)
    - git.sh        (install/verify/configure)
    - uv.sh         (install/verify/update/python)
  - linux/
    - setup-ubuntu.sh
    - setup-debian.sh
    - setup-arch.sh    (Manjaro/Arch)
    - setup-nixos.sh
    - setup-linux.sh   (dispatcher/auto-detect)
  - macos/
    - setup-macos.sh
  - windows/
    - setup-windows.ps1
- shared/
  - templates/
    - email_request.txt
    - ssh_config_snippet
  - docs/
    - OPERATIONS.md
    - UX.md
    - TROUBLESHOOTING.md
- LICENSE (proprietary; provided by user)
- README.md (usage and quick one-liners)

Testing & Validation
- Dry-run and full-run on fresh and already-configured environments.
- PATH validation in new shells.
- uv and Python latest validation via uv commands.
- ssh-agent and ssh -T validation.
- Clone test repo; on failure, email crafting flow.

Conventions
- No external runtime deps required to start scripts.
- Ask user before installing packages via native managers (apt/pacman/dnf/brew/win-get), and provide command preview.
- All file edits marked with clear comment markers and are idempotent.
