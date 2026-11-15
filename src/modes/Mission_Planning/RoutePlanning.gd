class_name RoutePlanning
extends Node2D

signal plan_confirmed(plan: MissionPlan)

@export var expedition_scene_path: String = "res://src/modes/Expedition/Expedition.tscn"
@export var base_fuel_per_px: float = 0.04
@export var max_turn_penalty: float = 25.0
@export var straight_angle_tolerance_deg: float = 5.0

## Multiplicador listo para conectar después con Craft (peso de la nave)
@export var craft_weight_multiplier: float = 1.0

@onready var confirmed_line: Line2D = $ConfirmedLine
@onready var preview_line: Line2D = $PreviewLine
@onready var start_icon: Sprite2D = $StartIcon
@onready var target_icon: Sprite2D = $TargetIcon
@onready var markers_container: Node2D = $MarkersContainer
@onready var hud_label: Label = $CanvasLayer/HudLabel

var outbound_waypoints: Array[Vector2] = []
var plan: MissionPlan = MissionPlan.new()


func _ready() -> void:
	start_icon.visible = false
	target_icon.visible = false
	_rebuild_round_trip_plan()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_add_waypoint(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_last_waypoint()

	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Z:
				_remove_last_waypoint()
			KEY_R:
				_clear_route()
			KEY_ENTER, KEY_KP_ENTER:
				_confirm_and_launch()


func _process(_delta: float) -> void:
	_update_preview_line()


func _add_waypoint(pos: Vector2) -> void:
	outbound_waypoints.append(pos)
	_rebuild_round_trip_plan()


func _remove_last_waypoint() -> void:
	if outbound_waypoints.is_empty():
		return
	outbound_waypoints.pop_back()
	_rebuild_round_trip_plan()


func _clear_route() -> void:
	outbound_waypoints.clear()
	_rebuild_round_trip_plan()


## Construye la ruta completa (Ida + Retorno espejo al inicio) y recalcula costos
func _rebuild_round_trip_plan() -> void:
	plan = _build_plan_from_outbound(outbound_waypoints)
	_refresh_visuals()


func _build_plan_from_outbound(source_points: Array[Vector2]) -> MissionPlan:
	var new_plan := MissionPlan.new()

	# 1. Tramo de ida (Inicio -> ... -> Objetivo)
	for pt in source_points:
		new_plan.waypoints.append(pt)

	# 2. Tramo de regreso automático (Objetivo -> ... -> Inicio)
	for i in range(source_points.size() - 2, -1, -1):
		new_plan.waypoints.append(source_points[i])

	# El ícono de FIN/OBJETIVO siempre queda en el último punto elegido antes de regresar
	new_plan.target_waypoint_index = maxi(0, source_points.size() - 1)
	new_plan.recalculate(
		base_fuel_per_px,
		max_turn_penalty,
		straight_angle_tolerance_deg,
		craft_weight_multiplier
	)
	return new_plan


func _refresh_visuals() -> void:
	confirmed_line.clear_points()
	for child in markers_container.get_children():
		child.queue_free()

	var n: int = outbound_waypoints.size()

	for i in range(n):
		var pt: Vector2 = outbound_waypoints[i]
		confirmed_line.add_point(pt)

		var tag_label := Label.new()
		tag_label.position = pt + Vector2(12, -24)

		if i == 0:
			tag_label.text = "#0 INICIO / BASE RETORNO"
		else:
			var out_cost: float = plan.segment_costs[i]
			var return_index: int = (2 * n - 1) - i
			var back_cost: float = plan.segment_costs[return_index]

			if i == n - 1:
				tag_label.text = "#%d [OBJETIVO - RETORNO]\nIda: %.1f | Giro+Vuelta: %.1f" % [i, out_cost, back_cost]
			else:
				tag_label.text = "#%d\nIda: %.1f | Vuelta: %.1f" % [i, out_cost, back_cost]

		markers_container.add_child(tag_label)

	start_icon.visible = n >= 1
	if start_icon.visible:
		start_icon.position = outbound_waypoints[0]

	target_icon.visible = n >= 2
	if target_icon.visible:
		target_icon.position = outbound_waypoints[n - 1]

	_update_preview_line()


func _update_preview_line() -> void:
	preview_line.clear_points()

	if outbound_waypoints.is_empty():
		hud_label.text = "Clic Izq: Poner punto de INICIO | Clic Der/Z: Deshacer | R: Limpiar"
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	preview_line.add_point(outbound_waypoints[-1])
	preview_line.add_point(mouse_pos)

	# Simula cuánto costaría la ruta completa de ida y vuelta si agregas este punto
	var candidate_outbound: Array[Vector2] = outbound_waypoints.duplicate()
	candidate_outbound.append(mouse_pos)
	var candidate_plan: MissionPlan = _build_plan_from_outbound(candidate_outbound)
	var added_round_trip_cost: float = candidate_plan.total_fuel_cost - plan.total_fuel_cost

	hud_label.text = (
		"Gasolina total (Ida y Vuelta): %.1f | Costo extra ida+vuelta si agregas nodo: +%.1f\n" % [plan.total_fuel_cost, added_round_trip_cost]
		+ "Clic Izq: Agregar nodo | Clic Der/Z: Quitar último | R: Limpiar | ENTER: Iniciar Expedition"
	)


func _confirm_and_launch() -> void:
	if outbound_waypoints.size() < 2:
		hud_label.text = "Necesitas al menos 2 puntos (Inicio y Objetivo) antes de iniciar Expedition."
		return

	plan_confirmed.emit(plan)

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and "current_mission_plan" in gm:
		gm.current_mission_plan = plan

	var expedition_packed: PackedScene = load(expedition_scene_path)
	if expedition_packed:
		var expedition_instance: Expedition = expedition_packed.instantiate() as Expedition
		get_tree().root.add_child(expedition_instance)
		expedition_instance.load_mission_plan(plan)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = expedition_instance
