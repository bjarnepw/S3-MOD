import CSI 1.0
import "../../Defines"

// Custom pad bank for the Kontrol S3's "SAMPLES" button.
//
//   Pad 1        -> Loop In   (freeform)
//   Pad 2        -> Loop Out  (freeform)
//   Shift+Pad 1  -> Exit / toggle the active loop off
//   Shift+Pad 2  -> Exit / toggle the active loop off
//   Pad 3        -> (unassigned, TBD)
//   Pad 4        -> (unassigned, TBD)
//   Pad 5        -> Key transpose down 1 semitone
//   Pad 6        -> Key transpose up 1 semitone
//   Pad 7        -> Key reset (back to the track's original key)
//   Pad 8        -> (unassigned, TBD)
//
// Key transpose/reset uses the exact pattern Traktor's own Pioneer CDJ
// integration uses (Common/Pioneer/KeyShift.qml): RelativePropertyAdapter
// with mode Increment/Decrement and step: 1 against
// app.traktor.decks.<deck>.track.key.transpose (same family as the
// select.1 wiring already confirmed working on this controller), and
// SetPropertyAdapter zeroing track.key.adjust for the reset.
//
// An earlier version of this pad bank tried giving pads 3/4 an effect-select
// role and pads 5-8 direct control of an FX unit's dry/wet and params.
// Effect select worked correctly, but turned out not to be practically
// useful without also being able to shape the effect by hand, and every
// attempt at that hit a real wall: dry_wet/knob1-3 on the FxUnit adapter
// only respond to a genuine declarative Wire from real absolute hardware,
// not to script-driven reads/writes (confirmed across several independent
// attempts), and the S3 has no absolute-position control free to dedicate
// to it. That whole feature was pulled in favor of this one.

Module
{
  id: module
  property bool shift: false
  property string surface: ""
  property int deckIdx: 0
  property bool active: false

  XDJLoop { name: "manualloop"; channel: module.deckIdx }

  WiresGroup
  {
    enabled: active

    WiresGroup
    {
      enabled: !module.shift
      Wire { from: "%surface%.pads.1"; to: "manualloop.loop_in" }
      Wire { from: "%surface%.pads.2"; to: "manualloop.loop_out" }
    }

    WiresGroup
    {
      enabled: module.shift
      Wire { from: "%surface%.pads.1"; to: TogglePropertyAdapter { path: "app.traktor.decks." + module.deckIdx + ".loop.active" } }
      Wire { from: "%surface%.pads.2"; to: TogglePropertyAdapter { path: "app.traktor.decks." + module.deckIdx + ".loop.active" } }
    }

    Wire { from: "%surface%.pads.5"; to: RelativePropertyAdapter { path: "app.traktor.decks." + module.deckIdx + ".track.key.transpose"; mode: RelativeMode.Decrement; step: 1; color: Color.Cyan } }
    Wire { from: "%surface%.pads.6"; to: RelativePropertyAdapter { path: "app.traktor.decks." + module.deckIdx + ".track.key.transpose"; mode: RelativeMode.Increment; step: 1; color: Color.Cyan } }
    Wire { from: "%surface%.pads.7"; to: SetPropertyAdapter { path: "app.traktor.decks." + module.deckIdx + ".track.key.adjust"; value: 0; color: Color.Cyan } }
  }
}
