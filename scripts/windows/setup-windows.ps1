#requires -Version 5.1
# Presempathy Windows Setup (PowerShell) - zero external dependencies

$ErrorActionPreference = "Stop"

function Write-Section($Title) {
  Clear-Host
  Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Blue
  Write-Host ("Welcome to Presempathy") -ForegroundColor Blue
  Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Blue
  Write-Host $Title -ForegroundColor Cyan
}

function Show-Cmd($Cmd) {
  Write-Host ("➜ " + $Cmd) -ForegroundColor Cyan
}

function Run-Cmd($Cmd) {
  Show-Cmd $Cmd
  $res = & powershell -NoProfile -Command $Cmd 2>&1
  if ($LASTEXITCODE -eq 0) { Write-Host "✔ ok" -ForegroundColor Green } else {
    Write-Host "✖ failed" -ForegroundColor Red
    throw $res
  }
}

function Command-Exists($Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

function Ensure-Path($Dir) {
  if (-not (Test-Path $Dir)) { return }
  $envPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
  if ($envPath -notlike "*$Dir*") {
    [System.Environment]::SetEnvironmentVariable("Path", $envPath + ";" + $Dir, "User")
    Write-Host ("✔ PATH updated to include " + $Dir) -ForegroundColor Green
  }
}

Write-Section "This script will prepare your Windows system for Presempathy development."

$name = Read-Host "What is your name?"
while ([string]::IsNullOrWhiteSpace($name) -or -not ($name.Trim().Contains(" "))) {
  $name = Read-Host "Please enter at least a first name and last initial (e.g., Jane D.)"
}
$first = $name.Split(" ")[0]

$hasGh = Read-Host "Do you have a GitHub account? [Y/n]"
if ($hasGh -match "^[Nn]") {
  Write-Host "Please create one at https://github.com/signup and rerun this script." -ForegroundColor Yellow
  exit 1
}

$ghUser = Read-Host "What is your GitHub username?"
try {
  $resp = Invoke-WebRequest -UseBasicParsing -Uri ("https://api.github.com/users/" + $ghUser)
  Write-Host ("✔ GitHub user exists: " + $ghUser) -ForegroundColor Green
} catch {
  Write-Host ("✖ GitHub user not found: " + $ghUser) -ForegroundColor Red
  exit 1
}

$ghEmail = Read-Host "What is your GitHub email address?"
while ($ghEmail -notmatch ".+@.+\..+") {
  $ghEmail = Read-Host "That email looks invalid. Enter a valid email:"
}

Write-Host "Status report:"
if (Command-Exists "uv") { uv --version } else { Write-Host "uv: not found" }
if (Command-Exists "python") { python --version } else { Write-Host "python: not found" }
if (Command-Exists "git") { git --version } else { Write-Host "git: not found" }

# uv install/update
if (-not (Command-Exists "uv")) {
  Write-Host "Installing uv..." -ForegroundColor Blue
  # Windows installer (per uv docs) via powershell
  $cmd = "iwr https://astral.sh/uv/install.ps1 -UseBasicParsing | iex"
  Show-Cmd $cmd
  iex (iwr https://astral.sh/uv/install.ps1 -UseBasicParsing).Content
  Ensure-Path "$env:USERPROFILE\.uv\bin"
}
# Upgrade uv
try { uv self update | Out-Null } catch {}

# Python latest via uv
Run-Cmd "uv python install --latest"
$select = Read-Host "Set latest Python as global default? [Y/n]"
if ($select -notmatch "^[Nn]") { Run-Cmd "uv python select --global latest" }

# Git detect (install guidance; no external package manager requirement)
if (-not (Command-Exists "git")) {
  Write-Host "Please install Git for Windows (Git Credential Manager included): https://git-scm.com/download/win" -ForegroundColor Yellow
  Read-Host "Press Enter after installing Git to continue"
}
if (Command-Exists "git") { git --version }

# Git best practices
Run-Cmd "git config --global init.defaultBranch main"
Run-Cmd "git config --global pull.rebase false"
Run-Cmd "git config --global fetch.prune true"
Run-Cmd "git config --global core.autocrlf true"
Run-Cmd ("git config --global user.name '" + $name + "'")
Run-Cmd ("git config --global user.email '" + $ghEmail + "'")

# SSH key
$sshDir = "$env:USERPROFILE\.ssh"
$key = Join-Path $sshDir "id_ed25519"
if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
if (-not (Test-Path $key)) {
  Run-Cmd ("ssh-keygen -t ed25519 -C '" + $ghEmail + "' -f '" + $key + "' -N ''")
}
# ssh config
$config = Join-Path $sshDir "config"
$snippet = @"
# >>> prese github >>>
Host github.com
  HostName github.com
  User git
  IdentityFile $key
  IdentitiesOnly yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
# <<< prese github <<<
"@
if (Test-Path $config) {
  $content = Get-Content $config -Raw
  $content = $content -replace "(?s)# >>> prese github >>>.*?# <<< prese github <<<\r?\n?", ""
  Set-Content -Path $config -Value $content -NoNewline
}
Add-Content -Path $config -Value $snippet

# Upload key (optional PAT)
$pub = Get-Content ($key + ".pub") -Raw
$pat = Read-Host "Paste GitHub PAT with permission to manage SSH keys (leave empty to skip)"
if ($pat) {
  $body = @{ title = "Presempathy Setup ($env:COMPUTERNAME)"; key = $pub } | ConvertTo-Json
  try {
    Show-Cmd "POST /user/keys"
    Invoke-WebRequest -UseBasicParsing -Headers @{Authorization=("token " + $pat); "Accept"="application/vnd.github+json"} -Uri "https://api.github.com/user/keys" -Method Post -Body $body | Out-Null
    Write-Host "✔ Key uploaded" -ForegroundColor Green
  } catch {
    Write-Host "✖ Upload failed; please add key manually at https://github.com/settings/keys" -ForegroundColor Yellow
  }
} else {
  Write-Host "Manual upload: https://github.com/settings/keys" -ForegroundColor Blue
  Write-Host "Public key:" -ForegroundColor Blue
  Write-Host $pub
  Read-Host "Press Enter after uploading the key"
}

# Test SSH
try {
  Run-Cmd "ssh -o StrictHostKeyChecking=accept-new -T git@github.com"
} catch {
  Write-Host "SSH test failed; continuing to clone test." -ForegroundColor Yellow
}

# Clone test
$work = Join-Path $env:USERPROFILE "presempathy-tests"
if (-not (Test-Path $work)) { New-Item -ItemType Directory -Path $work | Out-Null }
Set-Location $work
try {
  Run-Cmd "git clone git@github.com:presempathy/setup-local-dev.git"
  Write-Host ("✔ All good, " + $first + "! Your environment is ready.") -ForegroundColor Green
} catch {
  Write-Host "✖ Clone failed. Drafting email to request access." -ForegroundColor Yellow
  $emailPath = Join-Path $work "request-access-email.txt"
  @"
To: awb@presempathy.com
Subject: Request access to presempathy/setup-local-dev

Hi Andrew,

This is $name ($ghUser) requesting access to the repository presempathy/setup-local-dev.
I ran the onboarding script and SSH setup completed, but cloning was denied.

Personal note (fill in here):

Thanks!
"@ | Set-Content -Path $emailPath -NoNewline
  Write-Host ("Draft saved at: " + $emailPath)
  exit 1
}
