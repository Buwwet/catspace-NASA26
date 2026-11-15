class_name ConstructionMode extends AbstractMode

@onready var all_tiles = $AllTiles;
@onready var tile_trans = $TileTransporter;
@onready var root = $root;

var tiles: Array[Tile] = [];

func _ready():	
	tiles.push_back($root);
	$addButton.button_down.connect(func():
		call_deferred("on_close")
	);
	
	$root.set_state(Tile.TileState.EditStationary);
	pass;


func create_tile(tile_name: String):
	var new_tile = all_tiles.find_child(tile_name).duplicate()
	tile_trans.grab_tile(new_tile);
	
	tiles.push_back(new_tile);
	
	# TODO: recalculate stats.


func on_close():
	# TODO - save base craft on GameManager
	var craft_scene: PackedScene = load("res://src/craft/Craft.tscn");
	var craft: Craft = craft_scene.instantiate();
	
	craft.map = TileGraph.new(tiles, root);
	for tile in tiles:
		tile.position -= root.position;
		tile.reparent(craft);
	
	
	GameManager.craft = craft;
	
	GameManager.change_mode(GameManager.Mode.Expedition)
