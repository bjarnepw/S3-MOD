#Requires -Version 5
<#
  Traktor Pro 4 - Kontrol S3 "Loop/FX pad bank" installer

  Repurposes the S3's unused SAMPLES button (dead weight on a 4-track-deck
  setup) into a Loop In/Out + key-transpose pad bank.

  This patches two files that ship with Traktor Pro 4 and adds one new file:
    Resources64\qml\CSI\S3\S3Side.qml   (patched in place, .orig backup kept)
    Resources64\qml\CSI\S3\S3Deck.qml   (patched in place, .orig backup kept)
    Resources64\qml\CSI\S3\S3LoopFX.qml (new file, copied in)

  Must be run as Administrator (Program Files is write-protected).
  Re-running this script is safe - it detects if it's already applied.

  -Force: restores each file from its .orig backup first (if one exists)
  before patching, so it doesn't matter whether the file currently on disk
  is untouched, already patched, or was hand-edited - it's always patched
  fresh from a known-original baseline. Use this after editing
  payload\S3LoopFX.qml, or to repair a file you broke by hand.
#>

param(
  [string]$InstallPath = "$Env:ProgramFiles\Native Instruments\Traktor Pro 4",
  [switch]$Force
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
  if ($Force) { $args += "-Force" }
  Start-Process powershell -ArgumentList $args -Verb RunAs
  exit
}

$s3Dir     = Join-Path $InstallPath "Resources64\qml\CSI\S3"
$sidePath  = Join-Path $s3Dir "S3Side.qml"
$deckPath  = Join-Path $s3Dir "S3Deck.qml"
$loopFxSrc = Join-Path $PSScriptRoot "payload\S3LoopFX.qml"
$loopFxDst = Join-Path $s3Dir "S3LoopFX.qml"

Write-Host "Traktor install path: $InstallPath"

if (-not (Test-Path $sidePath) -or -not (Test-Path $deckPath)) {
  Write-Error "Could not find S3Side.qml / S3Deck.qml under `"$s3Dir`". Pass -InstallPath if Traktor is installed somewhere else, e.g.:`n  .\install.ps1 -InstallPath 'D:\Native Instruments\Traktor Pro 4'"
}

if (-not (Test-Path $loopFxSrc)) {
  Write-Error "Missing payload\S3LoopFX.qml next to this script."
}

function Get-NormalizedContent {
  # Traktor's shipped .qml files use CRLF line endings; here-strings in this
  # script are LF-only. Normalize both sides to LF before comparing/replacing
  # so the anchor matches regardless of the file's actual line endings.
  param([string]$Path)
  return (Get-Content -Path $Path -Raw) -replace "`r`n", "`n"
}

function Set-NormalizedContent {
  param([string]$Path, [string]$Content)
  [System.IO.File]::WriteAllText($Path, $Content)
}

function Backup-Once {
  param([string]$Path)
  $bak = "$Path.orig"
  if (-not (Test-Path $bak)) {
    Copy-Item $Path $bak
    Write-Host "  backed up $(Split-Path $Path -Leaf) -> $(Split-Path $bak -Leaf)"
  }
}

function Reset-FromBackupIfForced {
  param([string]$Path)
  $bak = "$Path.orig"
  if ($Force -and (Test-Path $bak)) {
    Copy-Item $bak $Path -Force
    Write-Host "  -Force: reset $(Split-Path $Path -Leaf) from $(Split-Path $bak -Leaf) before patching"
  }
}

Write-Host "`nBacking up originals..."
Backup-Once $sidePath
Backup-Once $deckPath

if ($Force) {
  Write-Host "`n-Force: resetting from backups before patching..."
  Reset-FromBackupIfForced $sidePath
  Reset-FromBackupIfForced $deckPath
}

# ---------------------------------------------------------------------------
# Patch S3Side.qml: make the SAMPLES button always switch to the loop pad bank
# ---------------------------------------------------------------------------

$sideOldBlock = @'
    Wire
    {
        enabled: PadsMode.isPadsModeSupported(PadsMode.stems, focusedDeck().deckType);
        from: "%surface%.samples";
        to: SetPropertyAdapter  { path: propertiesPath + ".pads_mode"; value: PadsMode.stem; color: Helpers.colorForDeck(focusedDeckIdx) }
    }

    Wire
    {
        enabled: !PadsMode.isPadsModeSupported(PadsMode.stems, focusedDeck().deckType) && (PadsMode.isPadsModeSupported(PadsMode.remix, bottomDeck.deckType) || PadsMode.isPadsModeSupported(PadsMode.remix, topDeck.deckType));
        from: "%surface%.samples";
        to: SetPropertyAdapter  { path: propertiesPath + ".pads_mode"; value: PadsMode.remix; color: Helpers.colorForDeck(focusedDeckIdx) }
    }
'@

$sideNewBlock = @'
    Wire
    {
        enabled: true;
        from: "%surface%.samples";
        to: SetPropertyAdapter  { path: propertiesPath + ".pads_mode"; value: PadsMode.loop; color: Helpers.colorForDeck(focusedDeckIdx) }
    }
'@

Write-Host "`nPatching S3Side.qml..."
$side = Get-NormalizedContent $sidePath
if ($side.Contains('value: PadsMode.loop; color: Helpers.colorForDeck(focusedDeckIdx) }')) {
  Write-Host "  already patched, skipping."
}
elseif ($side.Contains($sideOldBlock)) {
  $side = $side.Replace($sideOldBlock, $sideNewBlock)
  Set-NormalizedContent -Path $sidePath -Content $side
  Write-Host "  done."
}
else {
  Write-Warning "  S3Side.qml doesn't match the expected stock text - skipped. See README.md 'Manual patch' section."
}

# ---------------------------------------------------------------------------
# Patch S3Deck.qml: instantiate the new S3LoopFX submodule
# ---------------------------------------------------------------------------

$deckAnchor = @'
  S3Samples
  {
    name: "samples"
    surface: module.surface
    deckIdx: module.deckIdx
    active: padsMode == PadsMode.remix && module.enablePads
    shift: module.shift
  }
'@

$deckInsert = @'
  S3Samples
  {
    name: "samples"
    surface: module.surface
    deckIdx: module.deckIdx
    active: padsMode == PadsMode.remix && module.enablePads
    shift: module.shift
  }

  S3LoopFX
  {
    id: loopfx
    name: "loopfx"
    surface: module.surface
    deckIdx: module.deckIdx
    active: padsMode == PadsMode.loop && module.enablePads
    shift: module.shift
  }
'@

Write-Host "`nPatching S3Deck.qml (submodule)..."
$deck = Get-NormalizedContent $deckPath
if ($deck.Contains("S3LoopFX")) {
  Write-Host "  already patched, skipping."
}
elseif ($deck.Contains($deckAnchor)) {
  $deck = $deck.Replace($deckAnchor, $deckInsert)
  Set-NormalizedContent -Path $deckPath -Content $deck
  Write-Host "  done."
}
else {
  Write-Warning "  S3Deck.qml doesn't match the expected stock text - skipped. See README.md 'Manual patch' section."
}

Write-Host "`nInstalling S3LoopFX.qml..."
Copy-Item $loopFxSrc $loopFxDst -Force
Write-Host "  done."

Write-Host "`nAll set. Fully quit Traktor Pro 4 (check the system tray) and relaunch it."
Write-Host "Press SAMPLES on your Kontrol S3 to switch a deck's pads into Loop/FX mode."
Read-Host "`nPress Enter to close"
