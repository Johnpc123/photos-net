# photos-setup.ps1 — one-shot installer for photos-net (Windows)
#
# Usage (PowerShell):
#   irm <url>/photos-setup.ps1 | iex
#   or: .\photos-setup.ps1 -Name alice
#
# What it does:
#   1. Installs SyncTrayzor (Syncthing + friendly tray app) via winget
#   2. Creates ~\photos\<you>\ and ~\photos\network\
#   3. Starts SyncTrayzor (autostarts at login)
#   4. Declares your folders via the Syncthing API
#   5. Installs the PiGallery2 gallery via npm (no Docker Desktop needed)
#   6. Prints your device ID — send it to an existing member

param([string]$Name = "")
$ErrorActionPreference = "Stop"
function say($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function warn($m) { Write-Host "!! $m" -ForegroundColor Yellow }

if (-not $Name) { $Name = $env:USERNAME }
$Name = ($Name.ToLower() -replace '[^a-z0-9]+','-').Trim('-')
if (-not $Name) { throw "could not derive a member name — pass -Name" }
say "member name: $Name"

$PhotosDir = "$env:USERPROFILE\photos"
$EnvDir = "$env:USERPROFILE\.config\photos-net"
New-Item -ItemType Directory -Force $EnvDir | Out-Null
"MEMBER=$Name`nPHOTOS_DIR=$PhotosDir" | Out-File -Encoding ascii "$EnvDir\env"

# ---------- 1. syncthing via SyncTrayzor ----------
if (-not (Get-Command syncthing -ErrorAction SilentlyContinue)) {
  say "installing SyncTrayzor (includes Syncthing + tray UI)"
  winget install --id SyncTrayzor.SyncTrayzor -e --accept-package-agreements --accept-source-agreements
  $env:Path += ";$env:LOCALAPPDATA\SyncTrayzor\syncthing;$env:ProgramFiles\SyncTrayzor\syncthing"
  Start-Process "SyncTrayzor" -ErrorAction SilentlyContinue
}

# ---------- 2. folder layout ----------
New-Item -ItemType Directory -Force "$PhotosDir\$Name","$PhotosDir\network" | Out-Null
$RosterFile = "$PhotosDir\network\members.txt"
if (-not (Test-Path $RosterFile)) {
  "# photos-net roster - <name> <device-id>" | Out-File -Encoding ascii $RosterFile
}

# ---------- 3. wait for config, read identity ----------
$Cfg = "$env:LOCALAPPDATA\Syncthing\config.xml"
foreach ($i in 1..30) { if (Test-Path $Cfg) { break }; Start-Sleep 1 }
if (-not (Test-Path $Cfg)) { throw "syncthing config not found — open SyncTrayzor once, then re-run" }
$xml = [xml](Get-Content $Cfg)
$DeviceID = $xml.configuration.device.id
$ApiKey = $xml.configuration.gui.apikey
$Api = "http://127.0.0.1:8384/rest"
"DEVICE_ID=$DeviceID`nAPI_KEY=$ApiKey`nAPI=$Api" | Add-Content "$EnvDir\env"

$H = @{ "X-API-Key" = $ApiKey }
function St-Post($path, $body) {
  Invoke-RestMethod -Method Post -Uri "$Api$path" -Headers $H -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 6)
}

# ---------- 4. declare folders ----------
function New-Folder($id, $path, $type) {
  try { Invoke-RestMethod -Uri "$Api/config/folders/$id" -Headers $H | Out-Null; return }
  catch { }
  St-Post "/config/folders" @{
    id=$id; label=$id; path=$path; type=$type; fsWatcherEnabled=$true; rescanIntervalS=60
    versioning=@{ type="simple"; params=@{ keep="3" } }
    devices=@(@{ deviceID=$DeviceID })
  }
}
New-Folder "photos-$Name" "$PhotosDir\$Name" "sendreceive"
New-Folder "network" "$PhotosDir\network" "sendreceive"
say "folders declared: photos-$Name (yours), network (roster)"

# ---------- 5. gallery via npm ----------
if (Get-Command npm -ErrorAction SilentlyContinue) {
  say "installing PiGallery2 (npm)"
  npm install -g pigallery2
  warn "start it with: pigallery2 --config-path=$EnvDir\pigallery2.json"
} else {
  warn "node/npm not found — install Node LTS (winget install OpenJS.NodeJS.LTS) then re-run for the gallery"
}

Write-Host ""
say "DONE. Your device ID - send this to any existing member in the group chat:"
Write-Host ""
Write-Host "    $DeviceID" -ForegroundColor Green
Write-Host ""
say "syncthing gui: http://localhost:8384"
say "once a member accepts you, their photos appear under $PhotosDir\<name>\"
