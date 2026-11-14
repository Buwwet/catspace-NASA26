## A class that has to be implemented by each mode.
@abstract class_name AbstractMode extends Node2D

## Normal ready function. Use to setup self.
@abstract func _ready();

## Ran when mode is over. Save to GameManager if needed.
@abstract func on_close();

func change_mode(mode: GameManager.Mode):
	on_close();

	pass
	
