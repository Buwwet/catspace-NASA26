class_name MissionPlan
extends Resource

@export var waypoints: Array[Vector2] = []
@export var target_waypoint_index: int = 0
@export var segment_costs: Array[float] = []      # Costo total (recto + giro) para llegar al nodo i
@export var straight_costs: Array[float] = []     # Costo solo por distancia recta al nodo i
@export var turn_penalties: Array[float] = []     # Costo extra por girar hacia el nodo i
@export var total_fuel_cost: float = 0.0

## Recalcula todos los costos de la ruta.
## weight_multiplier queda en 1.0 para el MVP y luego recibirá (craft.weight / base_weight).
func recalculate(
	base_fuel_per_px: float = 0.04,
	max_turn_penalty: float = 25.0,
	straight_angle_tolerance_deg: float = 5.0,
	weight_multiplier: float = 1.0
) -> void:
	segment_costs.clear()
	straight_costs.clear()
	turn_penalties.clear()
	total_fuel_cost = 0.0

	if waypoints.is_empty():
		target_waypoint_index = 0
		return

	# El nodo 0 es el origen (costo 0)
	segment_costs.append(0.0)
	straight_costs.append(0.0)
	turn_penalties.append(0.0)

	var tolerance_rad: float = deg_to_rad(straight_angle_tolerance_deg)

	for i in range(1, waypoints.size()):
		var dist: float = waypoints[i - 1].distance_to(waypoints[i])
		var straight_cost: float = dist * base_fuel_per_px * weight_multiplier
		var turn_cost: float = 0.0

		# Si hay un tramo anterior, calculamos el ángulo de giro en waypoints[i - 1]
		if i >= 2:
			var prev_dir: Vector2 = (waypoints[i - 1] - waypoints[i - 2]).normalized()
			var next_dir: Vector2 = (waypoints[i] - waypoints[i - 1]).normalized()
			if prev_dir.length() > 0.0 and next_dir.length() > 0.0:
				var turn_angle: float = abs(prev_dir.angle_to(next_dir))
				if turn_angle > tolerance_rad:
					# Escala lineal: 0° = 0 extra, 180° = max_turn_penalty
					turn_cost = (turn_angle / PI) * max_turn_penalty * weight_multiplier

		var seg_total: float = straight_cost + turn_cost
		straight_costs.append(straight_cost)
		turn_penalties.append(turn_cost)
		segment_costs.append(seg_total)
		total_fuel_cost += seg_total

	target_waypoint_index = clampi(target_waypoint_index, 0, waypoints.size() - 1)


## Calcula cuánto costaría agregar un punto candidato (para vista previa en tiempo real)
func preview_next_point(
	candidate: Vector2,
	base_fuel_per_px: float = 0.04,
	max_turn_penalty: float = 25.0,
	straight_angle_tolerance_deg: float = 5.0,
	weight_multiplier: float = 1.0
) -> Dictionary:
	if waypoints.is_empty():
		return { "straight": 0.0, "turn": 0.0, "total": 0.0, "angle_deg": 0.0 }

	var last: Vector2 = waypoints[-1]
	var dist: float = last.distance_to(candidate)
	var straight_cost: float = dist * base_fuel_per_px * weight_multiplier
	var turn_cost: float = 0.0
	var angle_deg: float = 0.0

	if waypoints.size() >= 2:
		var prev_dir: Vector2 = (last - waypoints[-2]).normalized()
		var next_dir: Vector2 = (candidate - last).normalized()
		if prev_dir.length() > 0.0 and next_dir.length() > 0.0:
			var turn_angle: float = abs(prev_dir.angle_to(next_dir))
			angle_deg = rad_to_deg(turn_angle)
			if turn_angle > deg_to_rad(straight_angle_tolerance_deg):
				turn_cost = (turn_angle / PI) * max_turn_penalty * weight_multiplier

	return {
		"straight": straight_cost,
		"turn": turn_cost,
		"total": straight_cost + turn_cost,
		"angle_deg": angle_deg
	}
