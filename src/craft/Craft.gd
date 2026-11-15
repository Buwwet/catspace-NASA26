class_name Craft extends Node2D

var map: TileGraph;

func _ready() -> void:
	pass;


# Para calcular usamos una función con depth search. 


class Stats extends Resource:
	# en kg
	var weight: float = 0.0;
	# en N
	var thrust: int = 0;
	# Para simplificar, 1 thrust = 1 engine
	# Es como 3000N por kg de fuel por segundo
	
	# en kg
	var fuel: float = 0.0;
	
	# cantidad de instrumentos scientificos
	var science_capability = 0.0;
	
	# cantidad de equipo electrico
	var power_ammount = 0.0;
