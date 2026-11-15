class_name ConstructionMode extends AbstractMode

@onready var all_tiles = $AllTiles;
@onready var tile_trans = $TileTransporter;
@onready var root: Tile;

var tiles: TileGraph;

func _ready():	
	root = all_tiles.find_child("cockpit").duplicate();
	add_child(root);
	root.position = Vector2(0, 0)
	
	$CanvasLayer/addButton.button_down.connect(func():
		call_deferred("on_close")
	);
	
	root.set_state(Tile.TileState.EditStationary);
	
	tiles = TileGraph.new([root], root);

func create_tile(tile_name: String):
	var new_tile = all_tiles.find_child(tile_name).duplicate();
	new_tile.position = Vector2.ZERO;
	tile_trans.grab_tile(new_tile);
	
	tiles.add_tile(new_tile);
	
	# TODO: recalculate stats.
	recalc_stats();

func recalc_stats():
	var stats = tiles.calculate_stats();
	$CanvasLayer/Label.text = "STATS\n- weight: " + str(stats.weight) + "kg\n- fuel: " + str(stats.fuel) + "kg\n- science: ";
	$CanvasLayer/Label.text += str(stats.science_capability) + "\n- electricity: " + str(stats.power_amount);
	$CanvasLayer/Label.text += "\n deltaV: " + str(stats.get_deltav());
	
	#TODO req.

func on_close():
	# TODO - save base craft on GameManager
	var craft_scene: PackedScene = load("res://src/craft/Craft.tscn");
	var craft: Craft = craft_scene.instantiate();
	
	craft.map = tiles;
	for tile in tiles.tiles:
		tile.position -= root.position;
		tile.set_state(Tile.TileState.Inactive);
		tile.reparent(craft);
		
	
	
	GameManager.craft = craft;
	
	GameManager.change_mode(GameManager.Mode.Expedition)
