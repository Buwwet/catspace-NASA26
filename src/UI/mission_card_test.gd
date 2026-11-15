extends AbstractMode

const MISSION_CARD_SCENE := preload("res://src/UI/components/mission_card.tscn")

# Drag your .tres files here from the Inspector
@export var missions: Array[MissionData] = []

@onready var cards_container: HBoxContainer = %CardsContainer


func _ready() -> void:
	_populate_missions()


func _populate_missions() -> void:
	# Limpia tarjetas de prueba si las hubiera
	for child in cards_container.get_children():
		child.queue_free()

	# Genera una tarjeta por cada MissionData configurado
	for mission in missions:
		var card: MissionCard = MISSION_CARD_SCENE.instantiate()
		cards_container.add_child(card)
		card.setup(
			mission.title,
			mission.description,
			mission.icon,
			func(): _launch_mission(mission),
			"Iniciar misión en " + mission.title
		)


func _launch_mission(_mission: MissionData) -> void:
	# Temporal para demo: omitimos la validación de datos/escena y pasamos directo al siguiente modo
	on_close()


func on_close() -> void:
	if GameManager != null:
		GameManager.change_mode(GameManager.Mode.MissionPlanning)
