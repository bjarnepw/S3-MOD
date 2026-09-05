# Traktor Pro 4 - Kontrol S3 Loop/FX Pad Bank

Repurposes the Kontrol S3's **SAMPLES** button. On a 4 (track-)deck setup
that button normally does nothing — it only ever activates if the *other*
physical deck happens to be loaded with a Remix Set. If you never use Remix
Decks, it's a dead button. This mod turns it into a second, useful pad bank:

| Pad            | Function                                                       |
|----------------|-----------------------------------------------------------------|
| 1              | Loop In (freeform — any length, not locked to the beat grid)    |
| 2              | Loop Out (freeform)                                              |
| Shift + 1 or 2 | Exit / toggle the active loop off                                |
| 3              | (unassigned, TBD)                                                |
| 4              | (unassigned, TBD)                                                |
| 5              | Key transpose down 1 semitone                                    |
| 6              | Key transpose up 1 semitone                                      |
| 7              | Key reset (back to the track's original key)                    |
| 8              | (unassigned, TBD)                                                |

Press **SAMPLES** to switch a deck's 8 pads into this bank, **HOTCUES** to
switch back.

### Why pads 3/4/8 are still open

An earlier version gave pads 3/4 an effect-select role (cycle through the
FX unit's effect list) and pads 5-8 direct control of that effect's
dry/wet and 3 parameters. Effect select worked correctly, but turned out
not to be practically useful without also being able to shape the effect
by hand — and every attempt at that hit a real wall: `dry_wet`/`knob1-3`
on the FX unit's native adapter only respond to a genuine declarative
`Wire` from real absolute-position hardware (like the dedicated FX knobs
on NI's own S4 MK3), not to script-driven reads/writes — confirmed across
several independent attempts (an accumulating encoder script, and a
button-driven nudge both silently did nothing; pointing
`RelativePropertyAdapter`'s path directly at the pin was worse, it broke
the whole S3 mapping outright, since that adapter validates its path
against real `app.traktor.*` engine properties and the pin isn't one). The
S3 has no free absolute-position control to dedicate to it, so that whole
feature was pulled in favor of key transpose. Pads 3, 4, and 8 are free
for whatever's next.

## Why not continuous loop-edge nudging?

The original ask this was built from also wanted: hold Loop In/Out and turn
the jogwheel to continuously shrink/grow the loop, instead of only fixed
beat-based sizes. That was checked against Traktor's own controller-scripting
API (the `.qml` files under `Resources64\qml\CSI\`) across *every* controller
NI ships mappings for, including their own flagship S8 and S4 MK3. None of
them expose a continuous/freeform loop-edge property — only fixed power-of-2
autoloop sizes, `loop.move`, and a freeform Loop-In/Loop-Out button pair.
So this mod gives you the freeform Loop In/Out buttons (arbitrary length,
not locked to the beat grid), which is the closest real equivalent — but not
a jogwheel-driven nudge, because Traktor doesn't expose that hook to any
controller.

## Requirements

- Traktor Pro 4 (tested against the version installed at the time this was
  written; see "If the patch doesn't apply" below for other versions)
- A Kontrol S3
- Windows, with the ability to run PowerShell as Administrator

## Install

1. Download/clone this whole folder.
2. Right-click `install.ps1` -> **Run with PowerShell** (it will
   self-elevate and prompt for admin — that's required because the target
   files live under `Program Files`).
   - If Traktor is installed somewhere other than the default
     `C:\Program Files\Native Instruments\Traktor Pro 4`, run it from a
     PowerShell prompt instead so you can pass the path:
     ```powershell
     .\install.ps1 -InstallPath "D:\Native Instruments\Traktor Pro 4"
     ```
3. Fully quit Traktor Pro 4 (check it isn't still running in the background)
   and relaunch it.

The installer only ever touches:
```
Resources64\qml\CSI\S3\S3Side.qml   (patched, original saved as S3Side.qml.orig)
Resources64\qml\CSI\S3\S3Deck.qml   (patched, original saved as S3Deck.qml.orig)
Resources64\qml\CSI\S3\S3LoopFX.qml (new file)
```
It's safe to re-run — it detects whether each patch is already applied and
skips it instead of double-patching.

### `-Force`

```powershell
.\install.ps1 -Force
```

Restores `S3Side.qml` / `S3Deck.qml` from their `.orig` backups first (if
one exists), then patches — so it doesn't matter whether the file on disk
right now is untouched, already patched, or was hand-edited, it always
patches fresh from the known-original baseline. Use this after editing
`payload\S3LoopFX.qml`, or to repair a file you broke by hand. Combine with
`-InstallPath` the same way:
```powershell
.\install.ps1 -Force -InstallPath "D:\Native Instruments\Traktor Pro 4"
```

## Uninstall

Right-click `uninstall.ps1` -> **Run with PowerShell**. It restores both
patched files from their `.orig` backups and deletes `S3LoopFX.qml`.

## If the patch doesn't apply (Traktor update changed the stock files)

The installer matches the *exact* stock text of the blocks it changes. If
NI ships an update that rewords those files, it will print a warning and
leave that file untouched rather than guessing. To patch by hand:

**`S3Side.qml`** — find the two `Wire { ... from: "%surface%.samples"; ... }`
blocks (they set `pads_mode` to `PadsMode.stem` / `PadsMode.remix`) and
replace both with a single:
```qml
Wire
{
    enabled: true;
    from: "%surface%.samples";
    to: SetPropertyAdapter  { path: propertiesPath + ".pads_mode"; value: PadsMode.loop; color: Helpers.colorForDeck(focusedDeckIdx) }
}
```

**`S3Deck.qml`** — inside the `Module { ... }` block, right after the
existing `S3Samples { ... }` submodule, add:
```qml
S3LoopFX
{
    id: loopfx
    name: "loopfx"
    surface: module.surface
    deckIdx: module.deckIdx
    active: padsMode == PadsMode.loop && module.enablePads
    shift: module.shift
}
```

Then copy `payload\S3LoopFX.qml` into `Resources64\qml\CSI\S3\S3LoopFX.qml`.

## Notes

- This edits files inside your Traktor installation directly (there's no
  supported plugin system for this — Traktor's S-series controller
  integration is compiled into the app's QML resources). A Traktor
  update may overwrite these files and require reinstalling this mod.
- If you're also running other S3 mods (e.g. custom deck colors), this
  patch is additive and shouldn't conflict — it only touches the trailing
  submodule list in `S3Deck.qml` and the SAMPLES-button wiring in
  `S3Side.qml`.
