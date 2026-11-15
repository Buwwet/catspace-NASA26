#CODIGO GENERADO POR GEMINI 4 HYDROGEN THINKING
class_name GenericButton
extends Button

@export var hover_tooltip: String = ""

var _on_click: Callable

func _ready() -> void:
	pressed.connect(_handle_pressed)
	mouse_entered.connect(_handle_mouse_entered)
	mouse_exited.connect(_handle_mouse_exited)

# Método principal para configurar texto, acción y tooltip en una sola línea
func setup(button_text: String, callback: Callable, tooltip: String = "") -> void:
	text = button_text
	_on_click = callback
	if not tooltip.is_empty():
		hover_tooltip = tooltip

# Permite cambiar solo la función más adelante sin alterar el texto
func set_callback(callback: Callable) -> void:
	_on_click = callback

func _handle_pressed() -> void:
	# is_valid() evita errores si el nodo dueño de la función fue eliminado (queue_free)
	if _on_click.is_valid():
		_on_click.call()

func _handle_mouse_entered() -> void:
	if not hover_tooltip.is_empty():
		UIManager.show_tooltip(hover_tooltip)

func _handle_mouse_exited() -> void:
	if not hover_tooltip.is_empty():
		UIManager.hide_tooltip()
