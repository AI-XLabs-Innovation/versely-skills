# sync-skills.ps1
# Re-syncs the 8 Versely skill folders from this repo to the user's
# Claude Code skills directory (~/.claude/skills/). Idempotent — wipes
# each destination skill first so deleted/renamed source files don't
# linger in the install.
#
# Usage (from any directory):
#   powershell -ExecutionPolicy Bypass -File "d:\WorkPlace\Versely\versely-skills\sync-skills.ps1"
#
# Or from this folder:
#   .\sync-skills.ps1
#
# Restart Claude Code afterwards so the new skill content is loaded.

$ErrorActionPreference = 'Stop'

$src  = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE '.claude\skills'

$skills = @(
  'versely-generate',
  'versely-social',
  'versely-slideshow',
  'versely-movie',
  'versely-ugc',
  'versely-content-pipeline',
  'versely-analytics',
  'versely-music'
)

if (-not (Test-Path $dest)) {
  New-Item -ItemType Directory -Path $dest -Force | Out-Null
  Write-Output "Created $dest"
}

$synced  = 0
$skipped = 0

foreach ($skill in $skills) {
  $srcPath  = Join-Path $src  $skill
  $destPath = Join-Path $dest $skill

  if (-not (Test-Path $srcPath)) {
    Write-Warning "Skipping $skill - source folder not found at $srcPath"
    $skipped++
    continue
  }

  if (Test-Path $destPath) {
    Remove-Item -Path $destPath -Recurse -Force
  }

  Copy-Item -Path $srcPath -Destination $destPath -Recurse -Force
  Write-Output "Synced $skill"
  $synced++
}

Write-Output ""
Write-Output "Done. $synced skill(s) synced, $skipped skipped."
Write-Output "Installed at: $dest"
Write-Output "Restart Claude Code to pick up changes."
