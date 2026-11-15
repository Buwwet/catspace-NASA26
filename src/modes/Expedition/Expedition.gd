class_name Expedition
extends Node2D

signal mission_completed
signal mission_failed(reason: String)

## TODO: Conectar con el Craft (ej. max_fuel y peso vendrán del Craft)
@export var ship_speed: float = 220.0
@export var max_fuel: float = 200.0
@export var arrival_threshold: float = 12.0

## Ruta por defecto si se ejecuta Expedition.tscn aislada con F6
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

var active_plan: MissionPlan
var current_waypoint_index: int = 1
var current_fuel: float = 0.0
var segment_start_pos: Vector2 = Vector2.ZERO
var segment_total_dist: float = 1.0
var segment_fuel_cost: float = 0.0
var last_segment_progress: float = 0.0
var is_running: bool = false
var is_finished: bool = false


func _ready() -> void:
	# Si ya se llamó load_mission_plan() antes de entrar al árbol, no sobrescribir
	if active_plan != null:
		return

	# Revisa si GameManager tiene un plan guardado
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and "current_mission_plan" in gm and gm.current_mission_plan != null:
		load_mission_plan(gm.current_mission_plan)
		return

	# Fallback MVP: crea un MissionPlan con la ruta por defecto
	var fallback_plan := MissionPlan.new()
	fallback_plan.waypoints = default_waypoints.duplicate()
	fallback_plan.target_waypoint_index = fallback_plan.waypoints.size() / 2
	fallback_plan.recalculate()
	load_mission_plan(fallback_plan)


## Método principal para recibir el objeto de ruta desde RoutePlanning o GameManager
func load_mission_plan(plan: MissionPlan) -> void:
	active_plan = plan
	if active_plan == null or active_plan.waypoints.size() < 2:
		push_warning("Expedition: MissionPlan inválido o con menos de 2 puntos.")
		return

	current_waypoint_index = 1
	current_fuel = max_fuel
	is_running = false
	is_finished = false

	route_line.clear_points()
	for point in active_plan.waypoints:
		route_line.add_point(point)

	# Posiciona los íconos de Inicio y Fin según lo definido en MissionPlan
	var target_idx: int = clampi(active_plan.target_waypoint_index, 0, active_plan.waypoints.size() - 1)
	start_planet.position = active_plan.waypoints[0]
	target_planet.position = active_plan.waypoints[target_idx]
	ship_mount.position = active_plan.waypoints[0]

	_prepare_segment(1)
	_update_hud(
		"Ruta cargada (Costo estimado: %.1f / Gasolina: %.1f)\nPresiona ESPACIO para iniciar | R para reiniciar"
		% [active_plan.total_fuel_cost, max_fuel]
	)


func _prepare_segment(index: int) -> void:
	segment_start_pos = active_plan.waypoints[index - 1]
	segment_total_dist = maxf(0.001, segment_start_pos.distance_to(active_plan.waypoints[index]))
	segment_fuel_cost = active_plan.segment_costs[index] if index < active_plan.segment_costs.size() else 0.0
	last_segment_progress = 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R and active_plan != null:
			load_mission_plan(active_plan)
		elif event.physical_keycode == KEY_SPACE and not is_finished and active_plan != null:
			is_running = not is_running


func _process(delta: float) -> void:
	if is_finished or active_plan == null or not is_running:
		return

	var target_point: Vector2 = active_plan.waypoints[current_waypoint_index]
	ship_mount.position = ship_mount.position.move_toward(target_point, ship_speed * delta)

	var direction: Vector2 = target_point - ship_mount.position
	if direction.length() > 1.0:
		ship_mount.rotation = direction.angle()

	# Descuenta gasolina proporcional al avance del tramo (incluye penalización por giro del tramo)
	var traveled: float = segment_start_pos.distance_to(ship_mount.position)
	var progress: float = clampf(traveled / segment_total_dist, 0.0, 1.0)
	var delta_progress: float = maxf(0.0, progress - last_segment_progress)
	last_segment_progress = progress

	current_fuel = maxf(0.0, current_fuel - segment_fuel_cost * delta_progress)

	if current_fuel <= 0.0 and ship_mount.position.distance_to(target_point) > arrival_threshold:
		_finish_mission(false, "Falla: Sin combustible antes de completar la ruta.")
		return

	_update_hud("En tránsito (Tramo %d/%d) | Gasolina: %.1f / %.1f" % [
		current_waypoint_index,
		active_plan.waypoints.size() - 1,
		current_fuel,
		max_fuel
	])

	if ship_mount.position.distance_to(target_point) <= arrival_threshold:
		current_waypoint_index += 1
		if current_waypoint_index >= active_plan.waypoints.size():
			_finish_mission(true, "¡Misión completada! Gasolina restante: %.1f" % current_fuel)
		else:
			_prepare_segment(current_waypoint_index)


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
