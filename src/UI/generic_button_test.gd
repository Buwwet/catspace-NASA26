extends Control

@onready var code_button: GenericButton = $VBoxContainer/CodeButton
@onready var inspector_button: GenericButton = $VBoxContainer/InspectorButton

func _ready() -> void:
	# Prueba 1: Configurar texto, acción y tooltip 100% por código
	code_button.setup(
		"Probar Popup",
		_on_test_popup_clicked,
		"Haz clic para abrir el popup genérico"
	)
	
	# Prueba 2: Usar el texto y tooltip del Inspector, asignando solo la función
	inspector_button.set_callback(func(): print("¡Clic en el botón del Inspector!"))

func _on_test_popup_clicked() -> void:
	print("¡Clic en el botón por código!")
	UIManager.show_popup(
		"Prueba exitosa",
		"El GenericButton ejecutó el Callable y llamó al UIManager.",
		func(): print("Confirmado desde el popup")
	)
