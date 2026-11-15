@tool
class_name Planet
extends Node2D

@export_category("Info")
@export var planet_name: String = "Planeta":
	set(value):
		planet_name = value
		_sync_visuals()

@export_category("Gravity")
@export var gravity_radius: float = 240.0:
	set(value):
		gravity_radius = maxf(10.0, value)
		_sync_collision_shape()
		queue_redraw()

## Porcentaje de ahorro de gasolina al cruzar el campo gravitacional (0.35 = 35% menos costo)
@export_range(0.0, 0.85, 0.05) var fuel_discount_ratio: float = 0.35
@export var gravity_fill_color: Color = Color(0.2, 0.75, 1.0, 0.16)
@export var gravity_border_color: Color = Color(0.25, 0.85, 1.0, 0.65)

@export_category("Visual")
@export var planet_img: Texture2D = preload("res://icon.svg"):
	set(value):
		planet_img = value
		_sync_visuals()

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	_ensure_nodes()
	_sync_visuals()
	_sync_collision_shape()
	queue_redraw()


func _ensure_nodes() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	if get_node_or_null("NameLabel") == null:
		var lbl := Label.new()
		lbl.name = "NameLabel"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size = Vector2(160, 24)
		add_child(lbl)

	if get_node_or_null("GravityArea") == null:
		var area := Area2D.new()
		area.name = "GravityArea"
		add_child(area)

		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = gravity_radius
		col.shape = circle
		area.add_child(col)


func _sync_visuals() -> void:
	if not is_node_ready():
		return

	if sprite != null:
		sprite.texture = planet_img

	var lbl := get_node_or_null("NameLabel") as Label
	if lbl != null:
		lbl.text = planet_name
		var half_height: float = (planet_img.get_height() * 0.5) if planet_img != null else 64.0
		lbl.position = Vector2(-lbl.size.x * 0.5, half_height + 4.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, gravity_radius, gravity_fill_color)
	draw_arc(Vector2.ZERO, gravity_radius, 0.0, TAU, 64, gravity_border_color, 2.0, true)


func _sync_collision_shape() -> void:
	if not is_node_ready():
		return
	var col := get_node_or_null("GravityArea/CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		col.shape.radius = gravity_radius


## Devuelve qué fracción (0.0 a 1.0) del segmento p1 -> p2 pasa dentro del círculo de gravedad
func get_segment_overlap_ratio(p1: Vector2, p2: Vector2) -> float:
	var center: Vector2 = global_position
	var d: Vector2 = p2 - p1
	var f: Vector2 = p1 - center

	var a: float = d.dot(d)
	if a < 0.0001:
		return 1.0 if f.length() <= gravity_radius else 0.0

	var b: float = 2.0 * f.dot(d)
	var c: float = f.dot(f) - gravity_radius * gravity_radius
	var discriminant: float = b * b - 4.0 * a * c

	if discriminant <= 0.0:
		return 0.0

	var sqrt_disc: float = sqrt(discriminant)
	var t1: float = (-b - sqrt_disc) / (2.0 * a)
	var t2: float = (-b + sqrt_disc) / (2.0 * a)

	var t_start: float = clampf(t1, 0.0, 1.0)
	var t_end: float = clampf(t2, 0.0, 1.0)
	return maxf(0.0, t_end - t_start)
