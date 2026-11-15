## The part of the game that manages everything
extends Node

enum Mode {
  StartMenu,
  Intro, #delayed
  MissionSelection, 
  MissionInfo,
  MissionPlanning,
  Construccion,
  Expedition,
  MissionClear
}

var current_mode_type = Mode.StartMenu;
var current_mode: AbstractMode;

var craft: Craft;
var current_mission_plan: MissionPlan;

## Se guardan todos los modos para tenerlos listos.
var modes: Dictionary[Mode, PackedScene] = {
	Mode.StartMenu: preload("res://src/modes/startmenu/StartMenuMode.tscn"),
	Mode.MissionSelection: preload("res://src/UI/mission_card_test.tscn"),
	Mode.MissionPlanning: preload("res://src/modes/Mission_Planning/RoutePlanning.tscn"),
	Mode.Construccion: preload("res://src/modes/construction/ConstructionMode.tscn"),
	Mode.Expedition: preload("res://src/modes/expedition/ExpeditionMode.tscn")
};

## Because we are a singleton stuff is weird.
func get_main_scene() -> Node:
	return get_tree().current_scene;

func _init() -> void:
	pass;

func change_mode(type: Mode):
	# Borramos el viejo
	if current_mode != null:
		current_mode.queue_free();
	
	print("MODE")
	print(type)
	if not modes.has(type):
		push_error("Modo aun no es implementado");
		return;
	
	# Cargamos el nuevo
	var scene: PackedScene = modes.get(type);
	current_mode = scene.instantiate();
	get_main_scene().add_child(current_mode);
