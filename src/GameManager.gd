## The part of the game that manages everything
extends Resource

enum Mode {
  StartMenu,
  Intro,
  MissionSelection,
  MissionPlanning,
  Construccion,
  Expedition,
  MissionClear
}

var current_mode = Mode.StartMenu;

## Se guardan todos los modos para tenerlos listos.
var modes: Dictionary[Mode, PackedScene] = {};

func _init() -> void:
	# Load the modes.
	pass;
