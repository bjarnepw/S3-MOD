# Traktor Pro 4 - Kontrol S3 Loop/FX Pad Bank

A small mod for the Native Instruments Kontrol S3 on Traktor Pro 4.

## What it does

1. **Turns the unused SAMPLES button into a second pad bank.** On a 4
   (track-)deck setup, SAMPLES normally does nothing — it only lights up if
   the *other* physical deck happens to be loaded with a Remix Set. This mod
   makes it always switch a deck's 8 pads into a Loop/Key pad bank instead.
2. **Jogwheel ring "spinning beat counter."** The LED ring around each
   jogwheel chases around in time with the beat (or shows a loop indicator
   while a loop is active), plus a spin animation while a track is loading.
3. **Custom deck colors.** Pick your own color for each of the 4 decks
   (used for the jogwheel rings, pad LEDs, etc.) instead of Traktor's
   stock colors.

## Quick start

1. Download/clone this whole folder.
2. Right-click `install.ps1` → **Run with PowerShell**.
   - It will ask for admin rights (a Windows popup) — say yes. This is
     needed because the files it changes live under `Program Files`.
   - A console window opens. It'll show you a recommended set of deck
     colors and ask if you want to use them — press Enter (or `y`) to
     accept, or `n` to pick your own per deck from a preview list.
3. Fully quit Traktor Pro 4 (check it isn't still running in the
   background/system tray) and relaunch it.

That's it. Press **SAMPLES** on the S3 to switch a deck into the new pad
bank, **HOTCUES** to switch back.

If you ever want to undo everything: right-click `uninstall.ps1` →
**Run with PowerShell**.

## The pad bank

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

## Requirements

- Traktor Pro 4 (tested against the version installed at the time this was
  written; see "If the patch doesn't apply" below for other versions)
- A Kontrol S3
- Windows, with the ability to run PowerShell as Administrator

## Credit / not all original work

This mod is built on top of files that already existed on my own Traktor
install — I'd modified Traktor's stock S3 mapping myself a while back
(deck colors, and the jogwheel-ring spin/beat-counter behavior), and at
this point I honestly don't remember where the jogwheel-ring QML
originally came from — likely adapted from a mapping I found online
somewhere (possibly a forum post or another user's shared mod) rather than
something I wrote from scratch. If you recognize this code and know the
original source, please open an issue so I can credit it properly.

What I can say for sure is original to this repo:
- Repurposing SAMPLES into a pad bank (`S3Side.qml` patch)
- The Loop In/Out + key-transpose pad bank itself (`S3LoopFX.qml`)
- The interactive/scriptable installer and deck-color picker

The jogwheel-ring spin/beat-counter and load animation (in `S3Deck.qml`)
predate this repo and aren't guaranteed to be my own original work.

## More details

<details>
<summary>Command-line options</summary>

- If Traktor is installed somewhere other than the default
  `C:\Program Files\Native Instruments\Traktor Pro 4`, run from a
  PowerShell prompt so you can pass the path:
  ```powershell
  .\install.ps1 -InstallPath "D:\Native Instruments\Traktor Pro 4"
  ```
- To skip the interactive color prompt entirely, pass your colors up
  front (valid names: White, Black, Blue, Red, Green, Yellow,
  LightOrange, Purple, Mint, Cyan, Plum, Fuchsia):
  ```powershell
  .\install.ps1 -DeckColors "Mint,Cyan,Plum,Fuchsia"
  ```
- `-Force` restores `S3Side.qml` / `S3Deck.qml` / `DeckHelpers.js` from
  their `.orig` backups first (if one exists), then patches fresh — so it
  doesn't matter whether the file on disk is untouched, already patched,
  or hand-edited. It also re-prompts for deck colors instead of keeping
  your previous choice. Use this after editing anything under `payload\`,
  or to repair a file you broke by hand:
  ```powershell
  .\install.ps1 -Force -InstallPath "D:\Native Instruments\Traktor Pro 4" -DeckColors "Mint,Cyan,Plum,Fuchsia"
  ```

It's safe to re-run plainly (no flags) — it detects whether each patch is
already applied and skips it instead of double-patching, and remembers
you've already picked deck colors so it won't re-prompt.

</details>

<details>
<summary>What files it touches</summary>

```
Resources64\qml\CSI\S3\S3Side.qml          (patched, original saved as S3Side.qml.orig)
Resources64\qml\CSI\S3\S3Deck.qml          (replaced, original saved as S3Deck.qml.orig)
Resources64\qml\CSI\S3\S3LoopFX.qml        (new file)
Resources64\qml\CSI\Common\DeckHelpers.js  (replaced, original saved as DeckHelpers.js.orig)
```

**Heads up**: `DeckHelpers.js` lives under `Resources64\qml\CSI\Common\`,
a shared folder used by *every* NI controller's mapping, not just the S3.
If you also use another Native Instruments controller (S4 MK3, S8, etc.)
on the same Traktor install, its deck colors will change too, since they
likely call the same `colorForDeck()` function.

</details>

<details>
<summary>Why pads 3/4/8 are still open</summary>

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

</details>

<details>
<summary>Why not continuous loop-edge nudging?</summary>

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

</details>

<details>
<summary>If the patch doesn't apply (Traktor update changed the stock files)</summary>

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

**`S3Deck.qml`** — replace the whole file with `payload\S3Deck.qml`, then
inside its `Module { ... }` block, right after the `S3Samples { ... }`
submodule, add:
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

**`DeckHelpers.js`** — copy `payload\DeckHelpers.js` over
`Resources64\qml\CSI\Common\DeckHelpers.js`, editing the four
`return Color.XXX;` lines in `colorForDeck()` to whatever colors you want
per deck first.

</details>

## Notes

- This edits files inside your Traktor installation directly (there's no
  supported plugin system for this — Traktor's S-series controller
  integration is compiled into the app's QML resources). A Traktor
  update may overwrite these files and require reinstalling this mod.
- `S3Deck.qml` and `DeckHelpers.js` are replaced wholesale rather than
  patched as fragments (both are short/self-contained enough that a full
  replace is simpler and more reliable). If you've made your *own* other
  edits to either file beyond deck colors and the jogwheel-ring behavior
  described here, merge them into `payload\S3Deck.qml` /
  `payload\DeckHelpers.js` before installing, or they'll be overwritten.
- `S3Side.qml` is patched as a small fragment and won't touch anything
  else in that file.
