## Script to start the GameManager when a scene loads
extends Node2D

@export var start_scene: GameManager.Mode = GameManager.Mode.StartMenu;

func _ready() -> void:
	GameManager.change_mode(start_scene);
