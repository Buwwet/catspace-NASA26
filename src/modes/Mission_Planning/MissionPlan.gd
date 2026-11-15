class_name MissionPlan
extends Resource

@export var waypoints: Array[Vector2] = []
@export var target_waypoint_index: int = 0
@export var segment_costs: Array[float] = []
@export var straight_costs: Array[float] = []
@export var turn_penalties: Array[float] = []
@export var gravity_discounts: Array[float] = []
@export var total_fuel_cost: float = 0.0
@export var total_gravity_saved: float = 0.0


## Recalcula todos los costos de la ruta (distancia recta + giro - ahorro por gravedad).
## weight_multiplier queda en 1.0 para el MVP y luego recibirá el factor de peso de Craft.
func recalculate(
	base_fuel_per_px: float = 0.04,
	max_turn_penalty: float = 25.0,
	straight_angle_tolerance_deg: float = 5.0,
	weight_multiplier: float = 1.0,
	solar_system: Node = null
) -> void:
	segment_costs.clear()
	straight_costs.clear()
	turn_penalties.clear()
	gravity_discounts.clear()
	total_fuel_cost = 0.0
	total_gravity_saved = 0.0

	if waypoints.is_empty():
		target_waypoint_index = 0
		return

	# El nodo 0 es el origen (costo 0)
	segment_costs.append(0.0)
	straight_costs.append(0.0)
	turn_penalties.append(0.0)
	gravity_discounts.append(0.0)

	var tolerance_rad: float = deg_to_rad(straight_angle_tolerance_deg)
	var has_gravity_map: bool = solar_system != null and solar_system.has_method("get_segment_gravity_discount")

	for i in range(1, waypoints.size()):
		var dist: float = waypoints[i - 1].distance_to(waypoints[i])
		var straight_cost: float = dist * base_fuel_per_px * weight_multiplier
		var turn_cost: float = 0.0

		# Penalización por ángulo de giro respecto al tramo anterior
		if i >= 2:
			var prev_dir: Vector2 = (waypoints[i - 1] - waypoints[i - 2]).normalized()
			var next_dir: Vector2 = (waypoints[i] - waypoints[i - 1]).normalized()
			if prev_dir.length() > 0.0 and next_dir.length() > 0.0:
				var turn_angle: float = abs(prev_dir.angle_to(next_dir))
				if turn_angle > tolerance_rad:
					turn_cost = (turn_angle / PI) * max_turn_penalty * weight_multiplier

		var raw_cost: float = straight_cost + turn_cost
		var discount_ratio: float = 0.0
		if has_gravity_map:
			discount_ratio = solar_system.get_segment_gravity_discount(waypoints[i - 1], waypoints[i])

		var saved_fuel: float = raw_cost * discount_ratio
		var seg_total: float = maxf(0.5, raw_cost - saved_fuel)

		straight_costs.append(straight_cost)
		turn_penalties.append(turn_cost)
		gravity_discounts.append(saved_fuel)
		segment_costs.append(seg_total)

		total_fuel_cost += seg_total
		total_gravity_saved += saved_fuel

	target_waypoint_index = clampi(target_waypoint_index, 0, waypoints.size() - 1)
