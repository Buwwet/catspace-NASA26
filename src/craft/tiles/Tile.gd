@tool
## Tile class to be extended. Usado en nuestro grafo de estructura de datos.
class_name Tile extends Node2D

enum TileState {
	Inactive,
	EditStationary, # Cuando esta siendo editando pero esta quieto.
	Dragged, # Cuando se esta moviendo
}
var current_state: TileState = TileState.Inactive;

@export_category("info")
@export var id: String = "null";

@export var weight: float = 0.0;
@export var thrust: int = 0;
@export var fuel: float = 0.0;
@export var science_capability = 0.0;
@export var power_ammount = 0.0;


@export var size: Vector2 = Vector2(1, 1);

## Posible tiles that can be connected
@export var connection_points: Array[Vector2]  = [
	Vector2(1, 0),
	Vector2(-1, 0),
	Vector2(0, 1),
	Vector2(0, -1),	
];

var connected_tiles: Dictionary[Vector2, Tile] = {};

@export_category("Visual")
@export var tile_img: Texture2D;


@onready var sprite = $Sprite2D;
@onready var body = $StaticBody2D;

# Parar recorridos.
var known = false;


func _ready() -> void:
	sprite.texture = tile_img;
	
# Para connectar tiles, ocupamos detectar si los lugares que tenemos disponibles no esten tocando nada más
var tile_grabbers: Dictionary[Area2D, Vector2];
# We are going to grab to a tile that entered to our active grabbers.
func grabTo(area: Area2D, body_RID: RID, body: Node2D):	
	var t: Tile = body.get_parent();
	var trans = t.get_parent(); # this should be true?
	var con_point = tile_grabbers.get(area);
	
	if trans is not TileTransporter:
		return;
	trans.place_tile();
	
	
	# Set connection between us
	connected_tiles.set(con_point, t);
	if (t.connection_points.has(con_point * -1)):
		t.connected_tiles.set(con_point * -1, self);
		
	# We are all in construction still.
	t.set_state(TileState.EditStationary);
	
	# Reparent to ship
	t.call_deferred("reparent", get_parent());
	t.set_deferred("position", position + con_point * 100)
	
	# Remove grabber
	tile_grabbers.erase(area);
	area.queue_free();
	pass;


func set_state(new: TileState):
	# Exit the last one.
	match current_state:
		TileState.Inactive:
			pass;
		TileState.EditStationary:
			# Delete all of our tile grabbers
			for grabber in tile_grabbers.keys():
				if is_instance_valid(grabber):
					grabber.queue_free()
			tile_grabbers.clear()
		TileState.Dragged:
			pass; #idk
	
	match new:
		TileState.Inactive:
			body.set_collision_layer_value(1, false);
		TileState.Dragged:
			body.set_collision_layer_value(1, true);
		TileState.EditStationary:
			body.set_collision_layer_value(1, false);
			var sensor_scene: PackedScene = load("res://src/craft/tiles/TileConnectionPoint.tscn");
			# We want to react to a new node coming our way.
			for connection_point: Vector2 in connection_points:
				if not connected_tiles.has(connection_point):
					# We are ready to recieve here.
					var sensor: Area2D = sensor_scene.instantiate();
					call_deferred("add_child", sensor);
					tile_grabbers.set(sensor, connection_point)
					sensor.position = connection_point * 100;
					# Si entra un tile, corremos esta funcion
					sensor.body_shape_entered.connect(
						func(body_rid, body, _a, _b): grabTo(sensor, body_rid, body)
					);
	current_state = new;
					

func reconnect():
	# TODO: do some raycasts to connect with everything.
	pass;
