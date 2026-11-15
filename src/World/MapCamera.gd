class_name MapCamera
extends Camera2D

@export var min_zoom: float = 0.25
@export var max_zoom: float = 2.5
@export var zoom_step: float = 0.12
@export var keyboard_pan_speed: float = 700.0
@export var map_bounds: Rect2 = Rect2(-3000, -3000, 6000, 6000)

## En RoutePlanning va en false (clic izq pone nodos); en ExpeditionMode va en true
@export var allow_left_drag: bool = false

var is_dragging: bool = false
var drag_button: int = -1
var drag_start_screen: Vector2 = Vector2.ZERO
var did_pan_during_drag: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Zoom con rueda del ratón centrado en la posición del cursor
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_cursor(1.0 + zoom_step)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_cursor(1.0 / (1.0 + zoom_step))
			get_viewport().set_input_as_handled()

		# Inicio de arrastre (Botón central, derecho, o izquierdo si está habilitado)
		elif event.pressed and _is_pan_button(event.button_index):
			is_dragging = true
			drag_button = event.button_index
			drag_start_screen = event.position
			did_pan_during_drag = false

		# Fin de arrastre: si sí se arrastró, consume el evento para no borrar nodos por error
		elif not event.pressed and event.button_index == drag_button:
			is_dragging = false
			drag_button = -1
			if did_pan_during_drag:
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		if not did_pan_during_drag and event.position.distance_to(drag_start_screen) > 6.0:
			did_pan_during_drag = true

		if did_pan_during_drag:
			position -= event.relative / zoom
			_clamp_position()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0

	if input_dir != Vector2.ZERO:
		position += input_dir.normalized() * (keyboard_pan_speed / zoom.x) * delta
		_clamp_position()


func _is_pan_button(button_index: int) -> bool:
	if button_index == MOUSE_BUTTON_MIDDLE or button_index == MOUSE_BUTTON_RIGHT:
		return true
	return allow_left_drag and button_index == MOUSE_BUTTON_LEFT


func _zoom_at_cursor(factor: float) -> void:
	var mouse_before: Vector2 = get_global_mouse_position()
	var target_zoom: float = clampf(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(target_zoom, target_zoom)
	var mouse_after: Vector2 = get_global_mouse_position()
	position += (mouse_before - mouse_after)
	_clamp_position()


func _clamp_position() -> void:
	position.x = clampf(position.x, map_bounds.position.x, map_bounds.end.x)
	position.y = clampf(position.y, map_bounds.position.y, map_bounds.end.y)
