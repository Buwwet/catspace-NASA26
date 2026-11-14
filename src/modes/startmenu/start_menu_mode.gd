extends AbstractMode


@onready var planet = $"Sprite2D"

func _ready():
	pass


func _process(delta: float) -> void:
	planet.rotate(delta)


func on_close():
	# We don't need to save anything.
	pass;
