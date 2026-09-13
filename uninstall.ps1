#Requires -Version 5
<#
  Reverts the Kontrol S3 Loop/FX pad bank mod: restores the original
  S3Side.qml / S3Deck.qml / DeckHelpers.js from their .orig backups and
  removes S3LoopFX.qml.

  Must be run as Administrator.
#>

param(
  [string]$InstallPath = "$Env:ProgramFiles\Native Instruments\Traktor Pro 4"
)

$ErrorActionPreference = "Stop"

function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
  Write-Host "Elevation required - relaunching as Administrator..."
  $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-InstallPath", "`"$InstallPath`"")
  Start-Process powershell -ArgumentList $args -Verb RunAs
  exit
}

$s3Dir           = Join-Path $InstallPath "Resources64\qml\CSI\S3"
$commonDir       = Join-Path $InstallPath "Resources64\qml\CSI\Common"
$sidePath        = Join-Path $s3Dir "S3Side.qml"
$deckPath        = Join-Path $s3Dir "S3Deck.qml"
$loopFxDst       = Join-Path $s3Dir "S3LoopFX.qml"
$deckHelpersPath = Join-Path $commonDir "DeckHelpers.js"

function Restore-Backup {
  param([string]$Path)
  $bak = "$Path.orig"
  if (Test-Path $bak) {
    Copy-Item $bak $Path -Force
    Write-Host "  restored $(Split-Path $Path -Leaf) from backup"
  }
  else {
    Write-Warning "  no backup found for $(Split-Path $Path -Leaf) - leaving it untouched"
  }
}

Write-Host "Restoring originals..."
Restore-Backup $sidePath
Restore-Backup $deckPath
Restore-Backup $deckHelpersPath

if (Test-Path $loopFxDst) {
  Remove-Item $loopFxDst -Force
  Write-Host "Removed S3LoopFX.qml"
}

Write-Host "`nDone. Fully quit Traktor Pro 4 and relaunch it."
Read-Host "Press Enter to close"
