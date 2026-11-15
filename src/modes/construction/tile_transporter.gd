class_name TileTransporter extends Node2D

var is_active: bool = false;

var tile: Tile = null;

func grab_tile(t: Tile):
	if is_active:
		return;
	tile = t;
	add_child(tile);
	is_active = true;
	tile.set_state(Tile.TileState.Dragged);

func _process(delta: float) -> void:
	position = get_global_mouse_position();
		

## Runs when a tile was placed and is no longer our child.
func place_tile():
	is_active = false;
	tile = null;
