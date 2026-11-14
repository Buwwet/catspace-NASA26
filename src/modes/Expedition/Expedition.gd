class_name Expedition
extends Node2D ##Cambiar a ModeManager

signal mission_completed
signal mission_failed(reason: String)

## TODO: Conectar con el Craft
@export var ship_speed: float = 220.0
@export var max_fuel: float = 150.0
@export var fuel_burn_rate: float = 12.0
@export var arrival_threshold: float = 12.0

## Índice manual para el planeta destino (-1 = calcular automáticamente la mitad del vector)
@export var target_waypoint_index: int = -1

## Ruta por defecto para el MVP (ida y vuelta)
@export var default_waypoints: Array[Vector2] = [
	Vector2(150, 520),
	Vector2(420, 340),
	Vector2(760, 260),
	Vector2(1080, 180),
	Vector2(768, 260),
	Vector2(420, 340),
	Vector2(150, 520)
]

@onready var route_line: Line2D = $RouteLine
@onready var start_planet: Node2D = $StartPlanet
@onready var target_planet: Node2D = $TargetPlanet
@onready var ship_mount: Node2D = $ShipMount
@onready var hud_label: Label = $CanvasLayer/HudLabel

var waypoints: Array[Vector2] = []
var current_waypoint_index: int = 0
var current_fuel: float = 0.0
var is_running: bool = false
var is_finished: bool = false


func _ready() -> void:
	print("Expedition iniciada. Puntos cargados: ", default_waypoints.size())
	setup_expedition(default_waypoints)


## Método público para inyectar cualquier ruta externa (ej. desde MissionPlan)
func setup_expedition(route_points: Array[Vector2]) -> void:
	waypoints = route_points.duplicate()
	if waypoints.size() < 2:
		push_warning("Expedition: Se necesitan al menos 2 puntos en la ruta (revisa Default Waypoints en el Inspector).")
		return

	current_waypoint_index = 1
	current_fuel = max_fuel
	is_running = false
	is_finished = false

	route_line.clear_points()
	for point in waypoints:
		route_line.add_point(point)

	# Calcula el índice del destino (por defecto, la mitad exacta del vector)
	var pivot_index: int = target_waypoint_index
	if pivot_index < 0 or pivot_index >= waypoints.size():
		pivot_index = waypoints.size() / 2

	start_planet.position = waypoints[0]
	target_planet.position = waypoints[pivot_index]
	ship_mount.position = waypoints[0]
	_update_hud("Presiona ESPACIO para iniciar ignición | R para reiniciar")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			print("Tecla R detectada: reiniciando ruta")
			setup_expedition(waypoints)
		elif event.physical_keycode == KEY_SPACE:
			print("Tecla ESPACIO detectada | is_finished=", is_finished, " | puntos=", waypoints.size())
			if not is_finished and not waypoints.is_empty():
				is_running = not is_running


func _process(delta: float) -> void:
	if is_finished or waypoints.is_empty() or not is_running:
		return

	if current_fuel <= 0.0:
		_finish_mission(false, "Falla: Sin combustible antes de llegar a órbita.")
		return

	current_fuel = max(0.0, current_fuel - fuel_burn_rate * delta)
	var target_point: Vector2 = waypoints[current_waypoint_index]
	ship_mount.position = ship_mount.position.move_toward(target_point, ship_speed * delta)

	var direction: Vector2 = target_point - ship_mount.position
	if direction.length() > 1.0:
		ship_mount.rotation = direction.angle()

	_update_hud("En tránsito | Combustible: %d%%" % int((current_fuel / max_fuel) * 100.0))

	if ship_mount.position.distance_to(target_point) <= arrival_threshold:
		current_waypoint_index += 1
		if current_waypoint_index >= waypoints.size():
			_finish_mission(true, "¡Misión completada! Regreso exitoso a base.")


func _finish_mission(success: bool, message: String) -> void:
	is_finished = true
	is_running = false
	_update_hud(message)
	if success:
		mission_completed.emit()
	else:
		mission_failed.emit(message)


func _update_hud(status_text: String) -> void:
	if hud_label:
		hud_label.text = status_text
