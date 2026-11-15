## Nuestra estructura de datos que guarda los Tiles de un Craft
## Es una estructura no lineal en forma de RED. Usamos lista de adj.
class_name TileGraph extends Object

## TODO @ricky

var root: Tile;
var tiles: Array[Tile];

func _init(ts: Array[Tile], r: Tile) -> void:
	tiles = ts;
	r = root;

func add_tile(t: Tile):
	tiles.push_back(t);


func calculate_stats():
	var weight: float = 0.0;
	var thrust: int = 0;
	var fuel: float = 0.0;
	var science_capability = 0.0;
	var power_amount = 0.0;
	
	for tile in tiles:
		weight += tile.weight;
		thrust += tile.thrust;
		fuel += tile.fuel;
		science_capability += tile.science_capability;
		power_amount += tile.power_ammount;
	
	return Craft.Stats.new(weight, thrust, fuel, science_capability, power_amount);
