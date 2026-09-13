import CSI 1.0
import QtQuick 2.5
import "../../Defines"
import "../Common"
import "../Common/DeckHelpers.js" as Helpers

Module
{
  id: module
  property bool active: false
  property bool enablePads: false
  property bool shift: false
  property string surface: ""
  property string deckPropertiesPath: ""
  property int deckIdx: 0
  property int deckType: deckTypeProp.value
  property bool deckPlaying: deckPlayingProp.value
  property int padsMode: 0
  property bool deckIsLoaded: false
  readonly property var deckColor: Helpers.colorForDeck(module.deckIdx)

  AppProperty
  {
    id: deckTypeProp;
    path: "app.traktor.decks." + deckIdx + ".type";
  }

  AppProperty
  {
    id: deckPlayingProp;
    path: "app.traktor.decks." + deckIdx + ".play";
  }

  //----------------------------------- Grid Adjust------------------------------------//

  // Grid Adjust //
  AppProperty { id: enableTick; path: "app.traktor.decks." + module.deckIdx + ".track.grid.enable_tick" }
  AppProperty { id: gridAdjust; path: "app.traktor.decks." + module.deckIdx + ".track.gridmarker.move" }
  AppProperty { id: gridLockedProp; path: "app.traktor.decks." + module.deckIdx + ".track.grid.lock_bpm" }

  MappingPropertyDescriptor
  {
    id: gridAdjustEnableProp;
    path: deckPropertiesPath + ".grid_adjust";
    type: MappingPropertyDescriptor.Boolean;
    value: false;
    onValueChanged: { enableTick.value = gridAdjustEnableProp.value; }
  }

  Wire
  {
    enabled: module.active && Helpers.deckTypeSupportsGridAdjust(deckTypeProp.value) && !gridLockedProp.value
    from: "%surface%.grid_adjust";
    to: HoldPropertyAdapter { path: deckPropertiesPath + ".grid_adjust"; value: true; color: deckColor }
  }

  Wire
  {
    enabled: gridAdjustEnableProp.value;
    from: "%surface%.jogwheel";
    to: EncoderScriptAdapter
    {
      onTick:
      {
        const minimalTickValue = 0.0035;
        const rotationScaleFactor = 20;
        if (value < -minimalTickValue || value > minimalTickValue)
          gridAdjust.value = value * rotationScaleFactor;
      }
    }
  }

  //-----------------------------------Jogwheel Beatcounter LED------------------------------------//

  AppProperty { id: deckElapsedTime; path: "app.traktor.decks." + deckIdx + ".track.player.elapsed_time" }
  AppProperty { id: deckGridOffset; path: "app.traktor.decks." + deckIdx + ".content.grid_offset" }
  AppProperty { id: deckMixerBpm; path: "app.traktor.decks." + deckIdx + ".tempo.base_bpm" }
  AppProperty { id: remixBeatPos; path: "app.traktor.decks." + deckIdx + ".remix.current_beat_pos" }

  // pick the one you like or enter a custom value
  // readonly property var jogwheelTurnSpeedFactor: deckMixerBpm.value / 4  // Tempo varies with track's bpm
  // readonly property var jogwheelTurnSpeedFactor: 33  // standard record speed (rounds per minute)
  readonly property var jogwheelTurnSpeedFactor: 45  // standard single record speed (rounds per minute

  readonly property var deckBeats: deckTypeProp.value != 1 ? (((deckElapsedTime.value * 1000 - deckGridOffset.value + 10) * jogwheelTurnSpeedFactor) / 7500.0) : parseInt(remixBeatPos.value) * 2
  readonly property var deckBeat: (deckBeats < 0.0) ? (8 - (parseInt(Math.abs(deckBeats) % 8))) : parseInt(Math.abs(deckBeats) % 8) + 1

  WiresGroup {
   enabled: !gridAdjustEnableProp.value && module.active && !deckLoading && deckIsLoaded
    Wire {
      enabled: !loopActive.value && deckBeat == 1;
      from: "%surface%.jogwheel_ring.1"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 1;
      from: "%surface%.jogwheel_ring.2"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 1;
      from: "%surface%.jogwheel_ring.3"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 2;
      from: "%surface%.jogwheel_ring.2"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 2;
      from: "%surface%.jogwheel_ring.3"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 2;
      from: "%surface%.jogwheel_ring.4"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 3;
      from: "%surface%.jogwheel_ring.3"; to: "turntable.lights" ;
	 }
	 Wire {
      enabled: !loopActive.value && deckBeat == 3;
      from: "%surface%.jogwheel_ring.4"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 3;
      from: "%surface%.jogwheel_ring.5"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 4;
      from: "%surface%.jogwheel_ring.4"; to: "turntable.lights" ;
	 }
	 Wire {
      enabled: !loopActive.value && deckBeat == 4;
      from: "%surface%.jogwheel_ring.5"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 4;
      from: "%surface%.jogwheel_ring.6"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 5;
      from: "%surface%.jogwheel_ring.5"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 5;
      from: "%surface%.jogwheel_ring.6"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 5;
      from: "%surface%.jogwheel_ring.7"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 6;
      from: "%surface%.jogwheel_ring.6"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 6;
      from: "%surface%.jogwheel_ring.7"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 6;
      from: "%surface%.jogwheel_ring.8"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 7;
      from: "%surface%.jogwheel_ring.7"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 7;
      from: "%surface%.jogwheel_ring.8"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 7;
      from: "%surface%.jogwheel_ring.1"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 8;
      from: "%surface%.jogwheel_ring.8"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 8;
      from: "%surface%.jogwheel_ring.1"; to: "turntable.lights" ;
	 }
    Wire {
      enabled: !loopActive.value && deckBeat == 8;
      from: "%surface%.jogwheel_ring.2"; to: "turntable.lights" ;
	 }
	Wire {
      enabled: loopActive.value && deckBeat == 1;
      from: "%surface%.jogwheel_ring.1"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 1;
      from: "%surface%.jogwheel_ring.2"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 1;
      from: "%surface%.jogwheel_ring.3"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 2;
      from: "%surface%.jogwheel_ring.2"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 2;
      from: "%surface%.jogwheel_ring.3"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 2;
      from: "%surface%.jogwheel_ring.4"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 3;
      from: "%surface%.jogwheel_ring.3"; to: "loop.active" ;
	 }
	     Wire {
      enabled: loopActive.value && deckBeat == 3;
      from: "%surface%.jogwheel_ring.4"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 3;
      from: "%surface%.jogwheel_ring.5"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 4;
      from: "%surface%.jogwheel_ring.4"; to: "loop.active" ;
	 }
	     Wire {
      enabled: loopActive.value && deckBeat == 4;
      from: "%surface%.jogwheel_ring.5"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 4;
      from: "%surface%.jogwheel_ring.6"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 5;
      from: "%surface%.jogwheel_ring.5"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 5;
      from: "%surface%.jogwheel_ring.6"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 5;
      from: "%surface%.jogwheel_ring.7"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 6;
      from: "%surface%.jogwheel_ring.6"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 6;
      from: "%surface%.jogwheel_ring.7"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 6;
      from: "%surface%.jogwheel_ring.8"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 7;
      from: "%surface%.jogwheel_ring.7"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 7;
      from: "%surface%.jogwheel_ring.8"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 7;
      from: "%surface%.jogwheel_ring.1"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 8;
      from: "%surface%.jogwheel_ring.8"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 8;
      from: "%surface%.jogwheel_ring.1"; to: "loop.active" ;
	 }
    Wire {
      enabled: loopActive.value && deckBeat == 8;
      from: "%surface%.jogwheel_ring.2"; to: "loop.active" ;
	 }
  }

  //-----------------------------------JogWheel Animation------------------------------------//

  AppProperty { id: deckLoadedSignal; path: "app.traktor.decks." + deckIdx + ".is_loaded_signal";
    onValueChanged: {
      if (value == true) {
        deckLoadingAnimationProp.value = 7
        deckLoading = true
      }
    }
  }
  property bool deckLoading: false
  MappingPropertyDescriptor { id: deckLoadingAnimationProp; path: "mapping.state.deck." + deckIdx + ".deckloadinganimation_value"; type: MappingPropertyDescriptor.Integer; value: 0; min: 0; max: 7 }
  Timer {
    id: loadJogAnimationTimer
    interval: 150 //milliseconds per step. reduce to speed up animation
    repeat: true
    running: deckLoading
    onTriggered: {
      deckLoadingAnimationProp.value = deckLoadingAnimationProp.value - 1;
      if ( deckLoading && deckLoadingAnimationProp.value < 1 ) {
        deckLoading = false;
        deckLoadingAnimationProp.value = 0;
		deckIsLoaded=true;
      }
    }
  }

  WiresGroup {
    enabled: !gridAdjustEnableProp.value && module.active && deckLoading
    Wire {
      enabled: (deckLoadingAnimationProp.value == 7 || deckLoadingAnimationProp.value == 6 || deckLoadingAnimationProp.value == 5 || deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.1"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 6 || deckLoadingAnimationProp.value == 5 || deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.2"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 6 || deckLoadingAnimationProp.value == 5 || deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.8"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 5 || deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.3"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 5 || deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.7"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.4"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 4 || deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.6"; to: "turntable.lights" ;
    }
    Wire {
      enabled: (deckLoadingAnimationProp.value == 3 || deckLoadingAnimationProp.value == 2 || deckLoadingAnimationProp.value == 1);
      from: "%surface%.jogwheel_ring.5"; to: "turntable.lights" ;
    }
  }

  //-----------------------------------JogWheel------------------------------------//

  // Jogwheel //

  MappingPropertyDescriptor {
    id: jogMode
    path: deckPropertiesPath + ".jog_mode"
    type: MappingPropertyDescriptor.Boolean;
  }

  Wire { from: "%surface%.jog_mode"; to: TogglePropertyAdapter{ path: deckPropertiesPath + ".jog_mode"; color: deckColor } enabled: module.active }

  Turntable { name: "turntable"; channel: module.deckIdx; color: deckColor }

  AppProperty { id: loopActive; path: "app.traktor.decks." + module.deckIdx + ".loop.is_in_active_loop" }

  WiresGroup {
    enabled: !gridAdjustEnableProp.value && module.active
    Wire { from: "%surface%.jogwheel.rotation"; to: "turntable.rotation" }
    Wire { from: "%surface%.jogwheel.speed"; to: "turntable.speed" }
    Wire { from: "%surface%.jogwheel.touch"; to: "turntable.touch"; enabled: !jogMode.value }
    Wire { from: "%surface%.shift"; to: "turntable.shift" }

    // WiresGroup
    // {
        // enabled: !loopActive.value && deckPlaying
        // Wire { from: "%surface%.jogwheel_ring.2"; to: "turntable.lights" }
        // Wire { from: "%surface%.jogwheel_ring.4"; to: "turntable.lights" }
        // Wire { from: "%surface%.jogwheel_ring.6"; to: "turntable.lights" }
        // Wire { from: "%surface%.jogwheel_ring.8"; to: "turntable.lights" }
    // }

    // WiresGroup
    // {
        // enabled: loopActive.value && deckPlaying
        // Wire { from: "%surface%.jogwheel_ring.2"; to: "loop.active" }
        // Wire { from: "%surface%.jogwheel_ring.4"; to: "loop.active" }
        // Wire { from: "%surface%.jogwheel_ring.6"; to: "loop.active" }
        // Wire { from: "%surface%.jogwheel_ring.8"; to: "loop.active" }
    // }
  }

  //------------------------------------LOOP-----------------------------------------------//

  Loop { name: "loop"; channel: module.deckIdx; numberOfLeds: 1; color: Color.Green }

  WiresGroup
  {
    enabled: module.active
    Wire { from: "%surface%.loop_size"; to: "loop.autoloop" }
    Wire { from: "%surface%.loop_move"; to: "loop.move"; enabled: !module.shift }
    Wire { from: "%surface%.loop_move"; to: "loop.one_beat_move"; enabled:  module.shift }
  }


  //------------------------------------SUBMODULES------------------------------------------//

  S3Transport
  {
    name: "transport"
    surface: module.surface
    deckIdx: module.deckIdx
    active: module.active
    shift: module.shift
  }

  ExtendedBrowserModule
  {
    name: "browse"
    surface: module.surface
    deckIdx: module.deckIdx
    active: module.active
  }

  HotcuesModule
  {
    name: "hotcues"
    shift: module.shift
    surface: module.surface
    deckIdx:  module.deckIdx
    active: padsMode == PadsMode.hotcues && module.enablePads
  }

  S3Samples
  {
    name: "samples"
    surface: module.surface
    deckIdx: module.deckIdx
    active: padsMode == PadsMode.remix && module.enablePads
    shift: module.shift
  }

}
