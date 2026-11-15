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
