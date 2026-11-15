class_name MissionCard
extends PanelContainer

@onready var planet_texture: TextureRect = %PlanetTexture
@onready var title_label: Label = %MissionTitle
@onready var description_label: Label = %MissionDescription
@onready var play_button: GenericButton = %PlayMission

func setup(title: String, description: String, icon: Texture2D, on_play: Callable, button_tooltip: String = "") -> void:
	title_label.text = title
	description_label.text = description
	planet_texture.texture = icon
	play_button.setup("PLAY", on_play, button_tooltip)
