#Requires -Version 5
<#
  Traktor Pro 4 - Kontrol S3 "Loop/FX pad bank" installer

  Repurposes the S3's unused SAMPLES button (dead weight on a 4-track-deck
  setup) into a Loop In/Out + key-transpose pad bank, adds a jogwheel-ring
  "spinning beat counter" + load animation, and lets you pick your own
  4 deck colors (used for jogwheel rings, pad LEDs, etc.).

  This patches/replaces files that ship with Traktor Pro 4 and adds one new
  file:
    Resources64\qml\CSI\S3\S3Side.qml          (patched, .orig backup kept)
    Resources64\qml\CSI\S3\S3Deck.qml          (replaced, .orig backup kept)
    Resources64\qml\CSI\S3\S3LoopFX.qml        (new file, copied in)
    Resources64\qml\CSI\Common\DeckHelpers.js  (replaced, .orig backup kept)

  Must be run as Administrator (Program Files is write-protected).
  Re-running this script is safe - it detects if it's already applied.

  -Force: restores each file from its .orig backup first (if one exists)
  before patching, so it doesn't matter whether the file currently on disk
  is untouched, already patched, or was hand-edited - it's always patched
  fresh from a known-original baseline. Also re-prompts for deck colors
  (normally skipped once already configured). Use this after editing
  payload\S3LoopFX.qml, or to repair a file you broke by hand.

  -DeckColors "Name1,Name2,Name3,Name4": skip the interactive color prompt
  and use these 4 colors for decks 1-4 (comma-separated, no spaces). Valid
  names: White, Black, Blue, Red, Green, Yellow, LightOrange, Purple, Mint,
  Cyan, Plum, Fuchsia.
#>

param(
  [string]$InstallPath = "$Env:ProgramFiles\Native Instruments\Traktor Pro 4",
  [switch]$Force,
  [string]$DeckColors
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
  if ($DeckColors) { $args += "-DeckColors"; $args += "`"$DeckColors`"" }
  Start-Process powershell -ArgumentList $args -Verb RunAs
  exit
}

$s3Dir           = Join-Path $InstallPath "Resources64\qml\CSI\S3"
$commonDir       = Join-Path $InstallPath "Resources64\qml\CSI\Common"
$sidePath        = Join-Path $s3Dir "S3Side.qml"
$deckPath        = Join-Path $s3Dir "S3Deck.qml"
$loopFxSrc       = Join-Path $PSScriptRoot "payload\S3LoopFX.qml"
$loopFxDst       = Join-Path $s3Dir "S3LoopFX.qml"
$deckBaseSrc     = Join-Path $PSScriptRoot "payload\S3Deck.qml"
$deckHelpersPath = Join-Path $commonDir "DeckHelpers.js"
$deckHelpersSrc  = Join-Path $PSScriptRoot "payload\DeckHelpers.js"

Write-Host "Traktor install path: $InstallPath"

if (-not (Test-Path $sidePath) -or -not (Test-Path $deckPath) -or -not (Test-Path $deckHelpersPath)) {
  Write-Error "Could not find S3Side.qml / S3Deck.qml / DeckHelpers.js under `"$InstallPath`". Pass -InstallPath if Traktor is installed somewhere else, e.g.:`n  .\install.ps1 -InstallPath 'D:\Native Instruments\Traktor Pro 4'"
}

if (-not (Test-Path $loopFxSrc) -or -not (Test-Path $deckBaseSrc) -or -not (Test-Path $deckHelpersSrc)) {
  Write-Error "Missing payload files next to this script (need S3LoopFX.qml, S3Deck.qml, DeckHelpers.js under payload\)."
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
Backup-Once $deckHelpersPath

if ($Force) {
  Write-Host "`n-Force: resetting from backups before patching..."
  Reset-FromBackupIfForced $sidePath
  Reset-FromBackupIfForced $deckPath
  Reset-FromBackupIfForced $deckHelpersPath
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
# Replace S3Deck.qml with the ring-spin/load-animation base, then instantiate
# the S3LoopFX submodule on top of it
# ---------------------------------------------------------------------------

Write-Host "`nInstalling S3Deck.qml (jogwheel ring spin + load animation)..."
Copy-Item $deckBaseSrc $deckPath -Force
Write-Host "  done."

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

# ---------------------------------------------------------------------------
# DeckHelpers.js: pick 4 deck colors and generate the file
# ---------------------------------------------------------------------------

$validColors = @("White", "Black", "Blue", "Red", "Green", "Yellow", "LightOrange", "Purple", "Mint", "Cyan", "Plum", "Fuchsia")
$defaultColors = @{ 1 = "Mint"; 2 = "Cyan"; 3 = "Plum"; 4 = "Fuchsia" }
$deckHelpersMarker = "// --- deck colors set by traktor-s3-loopfx-mod installer ---"

function Test-ColorName {
  param([string]$Name)
  return ($validColors | Where-Object { $_ -ieq $Name.Trim() } | Select-Object -First 1)
}

function Read-DeckColor {
  param([int]$DeckNum, [string]$Default)
  while ($true) {
    $inp = Read-Host "  Deck $DeckNum color [$Default]"
    if ([string]::IsNullOrWhiteSpace($inp)) { return $Default }
    $match = Test-ColorName $inp
    if ($match) { return $match }
    Write-Host "    Not a recognized color. Choices: $($validColors -join ', ')"
  }
}

# Console doesn't have the exact S3 LED colors, so this is an approximation -
# enough to tell the options apart, not a color-accurate preview.
$colorSwatchMap = @{
  "White" = "White"; "Black" = "DarkGray"; "Blue" = "Blue"; "Red" = "Red"
  "Green" = "Green"; "Yellow" = "Yellow"; "LightOrange" = "DarkYellow"
  "Purple" = "DarkMagenta"; "Mint" = "Green"; "Cyan" = "Cyan"
  "Plum" = "Magenta"; "Fuchsia" = "Magenta"
}

function Show-ColorChoices {
  Write-Host ""
  foreach ($c in $validColors) {
    Write-Host "  ██ " -NoNewline -ForegroundColor $colorSwatchMap[$c]
    Write-Host $c
  }
  Write-Host ""
}

$chosenColors = $null

if ($DeckColors) {
  $parts = $DeckColors -split ","
  if ($parts.Count -ne 4) {
    Write-Warning "`n-DeckColors needs exactly 4 comma-separated values (deck1,deck2,deck3,deck4) - ignoring, will prompt/default instead."
  }
  else {
    $chosenColors = @{}
    for ($i = 0; $i -lt 4; $i++) {
      $m = Test-ColorName $parts[$i]
      if (-not $m) {
        Write-Warning "  '$($parts[$i])' isn't a recognized color for deck $($i+1) - using default ($($defaultColors[$i+1])) instead."
        $m = $defaultColors[$i+1]
      }
      $chosenColors[$i+1] = $m
    }
  }
}

if (-not $chosenColors) {
  $existingHelpers = Get-Content $deckHelpersPath -Raw
  if (-not $Force -and $existingHelpers.Contains($deckHelpersMarker)) {
    Write-Host "`nDeckHelpers.js already configured by this installer - keeping your existing deck colors (use -Force to reconfigure, or -DeckColors to set them non-interactively)."
  }
  else {
    Write-Host "`nRecommended deck colors (used for jogwheel rings, pad LEDs, etc.):"
    Write-Host "  1: $($defaultColors[1])   2: $($defaultColors[2])   3: $($defaultColors[3])   4: $($defaultColors[4])"
    $useDefault = Read-Host "Use these? [Y/n]"
    if ([string]::IsNullOrWhiteSpace($useDefault) -or $useDefault -imatch '^y') {
      $chosenColors = $defaultColors.Clone()
      Write-Host "  using recommended colors."
    }
    else {
      Write-Host "`nPick a color for each deck:"
      Show-ColorChoices
      Write-Host "Press Enter on any prompt to keep its default."
      $chosenColors = @{}
      foreach ($d in 1..4) {
        $chosenColors[$d] = Read-DeckColor -DeckNum $d -Default $defaultColors[$d]
      }
    }
  }
}

if ($chosenColors) {
  $deckHelpersTemplate = @'
// Returns a color for the specified Deck index
function colorForDeck(deckIdx)
{
    switch (deckIdx)
    {
      case 1:
        return Color.__DECK1__;
      case 2:
        return Color.__DECK2__;

      case 3:
        return Color.__DECK3__
      case 4:
        return Color.__DECK4__;
    }

    // Fall-through...
    return Color.Black;
}

// primary decks defualt to track, secondary decks default to remix
function defaultTypeForDeck(deckIdx)
{
    return (deckIdx > 2) ? DeckType.Remix : DeckType.Track
}

function deckTypeSupportsGridAdjust(deckType)
{
    return deckType == DeckType.Track || deckType == DeckType.Stem;
}

function linkedDeckIdx(deckIdx)
{
    switch (deckIdx)
    {
    // Deck A and C are linked
    case 0: return 2;
    case 2: return 0;
    // Deck B and D are linked
    case 1: return 3;
    case 3: return 1;
    }
}
'@

  $generated = $deckHelpersMarker + "`n" + $deckHelpersTemplate
  $generated = $generated.Replace("__DECK1__", $chosenColors[1])
  $generated = $generated.Replace("__DECK2__", $chosenColors[2])
  $generated = $generated.Replace("__DECK3__", $chosenColors[3])
  $generated = $generated.Replace("__DECK4__", $chosenColors[4])

  Set-NormalizedContent -Path $deckHelpersPath -Content $generated
  Write-Host "  wrote DeckHelpers.js - deck 1: $($chosenColors[1]), deck 2: $($chosenColors[2]), deck 3: $($chosenColors[3]), deck 4: $($chosenColors[4])"
}

Write-Host "`nAll set. Fully quit Traktor Pro 4 (check the system tray) and relaunch it."
Write-Host "Press SAMPLES on your Kontrol S3 to switch a deck's pads into Loop/FX mode."
Read-Host "`nPress Enter to close"
