@tool
extends Node2D

@export var title = "TITLE";
@export var id = "debug";
@export var icon: Texture2D;

# Por si lo movemos
@onready var my_mode: ConstructionMode = get_parent().get_parent().get_parent();

func _ready() -> void:
	$Button.text = title;
	$Button.icon = icon;
	
	$Button.button_down.connect(func(): 
		my_mode.create_tile(id);
	);
