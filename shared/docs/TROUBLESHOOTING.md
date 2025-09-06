# Troubleshooting

Common issues
- uv not found after install: ensure ~/.local/bin, ~/.cargo/bin, or ~/.uv/bin are in PATH; restart shell.
- Python latest fails to install: re-run uv python install --latest; check network/proxy.
- git missing: install via native package manager or Git for Windows installer.
- SSH permission denied: verify public key is in GitHub; run ssh -T git@github.com; ensure agent has the key loaded.
- Clone denied: confirm GitHub org membership; send access request email.

macOS
- Command Line Tools prompt loops: run `xcode-select --reset` then `xcode-select --install`, reboot if needed.
- Keychain: ensure `UseKeychain yes` appears under the github.com host block in ~/.ssh/config.

Windows
- ExecutionPolicy: launch PowerShell as Administrator, run `Set-ExecutionPolicy -Scope CurrentUser Bypass`.
- OpenSSH client missing: install Optional Feature "OpenSSH Client"; ensure `ssh.exe` is on PATH.
- Git Credential Manager: install Git for Windows; verify `git credential-manager-core --version`.

NixOS
- Prefer user-profile installs: `nix profile install nixpkgs#git`.
- Avoid system mutations without Nix; revert PATH edits by removing the marked section from your shell rc.
- uv: use the official installer; ensure ~/.uv/bin is in PATH.

Docker Debian
- Non-interactive apt: set `DEBIAN_FRONTEND=noninteractive`; install `curl ca-certificates git openssh-client`.
- SSH StrictHostKeyChecking: first `ssh -o StrictHostKeyChecking=accept-new -T git@github.com`.

Rate limits and GitHub API
- If uploading SSH key via PAT fails with 403 or remaining=0, wait a few minutes and retry, or upload manually at https://github.com/settings/keys.
