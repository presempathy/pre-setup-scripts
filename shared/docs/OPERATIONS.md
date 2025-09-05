# Operations

This document enumerates the exact commands and actions we run, per step, across OSes. The scripts echo these in real time and log them to ~/.presempathy-setup/logs.

Key operations
- uv installation: curl https://astral.sh/uv/install.sh | sh (Unix), install.ps1 (Windows)
- uv upgrade: uv self update
- Python latest: uv python install --latest; uv python select --global latest
- Git setup: install via native manager (with consent); configure best practices and identity
- SSH: ssh-keygen -t ed25519; update ~/.ssh/config; ssh-add; permissions; ssh -T test
- GitHub API: POST /user/keys with PAT when provided
- Validation: git clone git@github.com:presempathy/setup-local-dev.git
