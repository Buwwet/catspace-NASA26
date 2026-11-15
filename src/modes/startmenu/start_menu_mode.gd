extends AbstractMode


@onready var planet = $"Sprite2D"
@onready var start_menu = $"StartMenu"


func _ready() -> void:
	start_menu.play_button.button_down.connect(on_close)


func _process(delta: float) -> void:
	planet.rotate(delta)


func on_close() -> void:
	GameManager.change_mode(GameManager.Mode.MissionSelection)
