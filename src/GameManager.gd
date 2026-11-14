## The part of the game that manages everything
extends Node

enum Mode {
  StartMenu,
  Intro,
  MissionSelection,
  MissionPlanning,
  Construccion,
  Expedition,
  MissionClear
}

var current_mode_type = Mode.StartMenu;
var current_mode: AbstractMode;

## Se guardan todos los modos para tenerlos listos.
var modes: Dictionary[Mode, PackedScene] = {};

## Because we are a singleton stuff is weird.
func get_main_scene() -> Node:
	return get_tree().current_scene;

func _init() -> void:
	# Load the modes.
	
	pass;



func change_mode(type: Mode):
	# Borramos el viejo
	if current_mode != null:
		current_mode.queue_free();
	
	if not modes.has(type):
		push_error("Modo aun no es implementado");
		return;
	
	# Cargamos el nuevo
	var scene: PackedScene = modes.get(type);
	current_mode = scene.instantiate();
	get_main_scene().add_child(current_mode);
