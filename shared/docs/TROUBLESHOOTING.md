# Troubleshooting

Common issues
- uv not found after install: ensure ~/.local/bin, ~/.cargo/bin, or ~/.uv/bin are in PATH; restart shell.
- Python latest fails to install: re-run uv python install --latest; check network/proxy.
- git missing: install via native package manager or Git for Windows installer.
- SSH permission denied: verify public key is in GitHub; run ssh -T git@github.com; ensure agent has the key loaded.
- Clone denied: confirm GitHub org membership; send access request email.
