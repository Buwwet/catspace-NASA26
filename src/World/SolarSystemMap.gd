class_name SolarSystemMap
extends Node2D

@onready var planets_container: Node2D = $Planets
@onready var map_camera: MapCamera = $MapCamera


func get_planets() -> Array[Planet]:
	var list: Array[Planet] = []
	for child in planets_container.get_children():
		if child is Planet:
			list.append(child)
	return list


## Calcula el descuento total de gasolina (0.0 a 0.75) que recibe el segmento p1 -> p2
func get_segment_gravity_discount(p1: Vector2, p2: Vector2) -> float:
	var total_discount: float = 0.0
	for planet in get_planets():
		var overlap: float = planet.get_segment_overlap_ratio(p1, p2)
		if overlap > 0.0:
			total_discount += overlap * planet.fuel_discount_ratio
	return clampf(total_discount, 0.0, 0.75)


func set_left_drag_enabled(enabled: bool) -> void:
	if map_camera:
		map_camera.allow_left_drag = enabled
