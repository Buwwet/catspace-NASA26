## Nuestra estructura de datos que guarda los Tiles de un Craft
## Es una estructura no lineal en forma de RED. Usamos lista de adj.
class_name TileGraph extends Object

## TODO @ricky

var root: Tile;
var tiles: Array[Tile];

func _init(ts: Array[Tile], r: Tile) -> void:
	tiles = ts;
	root = r;

func add_tile(t: Tile):
	tiles.push_back(t);

## Complejidad O(n²)
func recorrido_width():
	var output: String = "Recorrido width: ";
	
	# to review
	var fila: Array[Tile] = [root];
	
	for tile in tiles:
		tile.known = false;
	root.known = true;
		
	while fila.size() > 0:
		# 1 Visitamos
		var tile = fila[0];
		output += tile.id + " -> ";
		fila.remove_at(0);
		# Añadimos adjecentes a la fila
		for adj_pos in tile.connected_tiles:
			var adj: Tile = tile.connected_tiles.get(adj_pos);
			if not adj.known:
				adj.known = true;
				fila.push_back(adj);
	
	print(output);

## Complejidad O(n²)
func recorrido_depth():
	var output: String = "Recorrido depth: ";
	
	# to review
	var pila: Array[Tile] = [root];
	
	for tile in tiles:
		tile.known = false;
	root.known = true;
	var found = 1;
	
	output += root.id + " -> ";
	while found < tiles.size():
		# Visitar
		var tile = pila[0];
		if not tile.known:
			found += 1;
			output += tile.id + " -> ";
			tile.known = true;
		
		# Encontrar el primer hijo no visitado.
		
		var adj: Tile;
		for adj_pos in tile.connected_tiles:
			var adj_test = tile.connected_tiles.get(adj_pos);
			if not adj_test.known:
				# Encontramos uno no visitado
				adj = adj_test;
				break;
		if adj != null:
			# Tenemos uno a seguir.
			pila.push_front(adj);
		else:
			# No encontramos ninguno, regresar.
			pila.remove_at(0);
			

	
	
	print(output);

## O(n²)
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
