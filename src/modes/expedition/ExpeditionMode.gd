class_name ExpeditionMode
extends AbstractMode

signal mission_completed
signal mission_failed(reason: String)

## TODO: Conectar con el Craft (ej. peso vendrá del Craft)
@export var ship_speed: float = 220.0
@export var max_fuel: float = 200.0
@export var arrival_threshold: float = 12.0

## Ruta por defecto si se ejecuta ExpeditionMode.tscn aislada con F6
@export var default_waypoints: Array[Vector2] = [
	Vector2(150, 520),
	Vector2(420, 340),
	Vector2(760, 260),
	Vector2(1080, 180),
	Vector2(768, 260),
	Vector2(420, 340),
	Vector2(150, 520)
]

@onready var solar_system: Node = get_node_or_null("SolarSystemMap")
@onready var route_line: Line2D = $RouteLine
@onready var start_planet: Node2D = $StartPlanet
@onready var target_planet: Node2D = $TargetPlanet
@onready var ship_mount: Node2D = $ShipMount
@onready var placeholder_sprite: Sprite2D = get_node_or_null("ShipMount/Sprite2D")
@onready var hud_label: Label = $CanvasLayer/HudLabel

var active_plan: MissionPlan
var current_waypoint_index: int = 1
var effective_max_fuel: float = 200.0
var current_fuel: float = 0.0
var segment_start_pos: Vector2 = Vector2.ZERO
var segment_total_dist: float = 1.0
var segment_fuel_cost: float = 0.0
var last_segment_progress: float = 0.0
var is_running: bool = false
var is_finished: bool = false

var craft: Craft = null


func _ready() -> void:
	# Cargar el Craft construido si existe en GameManager
	if GameManager != null and GameManager.craft != null:
		craft = GameManager.craft.duplicate() as Craft
		if craft != null:
			# duplicate() no copia variables sin @export como 'map', así que la transferimos
			craft.map = GameManager.craft.map
			ship_mount.add_child(craft)
			if placeholder_sprite != null:
				placeholder_sprite.visible = false

	# En expedición habilitamos también arrastrar el mapa con clic izquierdo
	if solar_system != null and solar_system.has_method("set_left_drag_enabled"):
		solar_system.set_left_drag_enabled(true)

	# Si ya se llamó load_mission_plan() antes de entrar al árbol, no sobrescribir
	if active_plan != null:
		return

	# Revisa si GameManager tiene un plan guardado
	if GameManager != null and GameManager.current_mission_plan != null:
		load_mission_plan(GameManager.current_mission_plan)
		return

	# Fallback MVP: crea un MissionPlan con la ruta por defecto (incluyendo descuentos de gravedad si hay mapa)
	var fallback_plan := MissionPlan.new()
	fallback_plan.waypoints = default_waypoints.duplicate()
	fallback_plan.target_waypoint_index = fallback_plan.waypoints.size() / 2
	fallback_plan.recalculate(0.04, 25.0, 5.0, 1.0, solar_system)
	load_mission_plan(fallback_plan)


## Usa el Delta-V del Craft si fue recibido; de lo contrario usa el max_fuel configurado
func _resolve_fuel_capacity() -> float:
	if craft != null:
		if craft.map != null:
			var stats: Craft.Stats = craft.get_stats()
			if stats != null and stats.weight > 0.0:
				return stats.get_deltav()
		return 0.0
	return max_fuel


## Método principal para recibir el objeto de ruta desde RoutePlanning o GameManager
func load_mission_plan(plan: MissionPlan) -> void:
	active_plan = plan
	if active_plan == null or active_plan.waypoints.size() < 2:
		push_warning("ExpeditionMode: MissionPlan inválido o con menos de 2 puntos.")
		return

	effective_max_fuel = _resolve_fuel_capacity()
	current_waypoint_index = 1
	current_fuel = effective_max_fuel
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

	var fuel_source_label: String = "Delta-V Craft" if craft != null else "Max Fuel"
	_prepare_segment(1)
	_update_hud(
		"Ruta cargada (Costo: %.1f | Ahorro gravedad: %.1f | %s: %.1f)\n" % [
			active_plan.total_fuel_cost,
			active_plan.total_gravity_saved,
			fuel_source_label,
			effective_max_fuel
		]
		+ "ESPACIO: Iniciar/Pausar | R: Reiniciar | Arrastrar ratón / WASD: Mover mapa | Rueda: Zoom"
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

	# Descuenta gasolina/Delta-V proporcional al avance del tramo (incluye giro y descuento por gravedad)
	var traveled: float = segment_start_pos.distance_to(ship_mount.position)
	var progress: float = clampf(traveled / segment_total_dist, 0.0, 1.0)
	var delta_progress: float = maxf(0.0, progress - last_segment_progress)
	last_segment_progress = progress

	current_fuel = maxf(0.0, current_fuel - segment_fuel_cost * delta_progress)

	if current_fuel <= 0.0 and ship_mount.position.distance_to(target_point) > arrival_threshold:
		_finish_mission(false, "Falla: Sin combustible/Delta-V antes de completar la ruta.")
		return

	var fuel_tag: String = "Delta-V" if craft != null else "Gasolina"
	_update_hud("En tránsito (Tramo %d/%d) | %s: %.1f / %.1f" % [
		current_waypoint_index,
		active_plan.waypoints.size() - 1,
		fuel_tag,
		current_fuel,
		effective_max_fuel
	])

	if ship_mount.position.distance_to(target_point) <= arrival_threshold:
		current_waypoint_index += 1
		if current_waypoint_index >= active_plan.waypoints.size():
			_finish_mission(true, "¡Misión completada! %s restante: %.1f" % [fuel_tag, current_fuel])
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


func on_close():
	# TODO: dependiendo si ganamos o perdimos guardamos los datos para el modo de MissionClear
	if GameManager != null:
		GameManager.change_mode(GameManager.Mode.MissionClear)


func _update_hud(status_text: String) -> void:
	if hud_label:
		hud_label.text = status_text
