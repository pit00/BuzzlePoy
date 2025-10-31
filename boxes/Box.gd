extends Node2D

@export var size: Vector2 = Vector2(1, 1) # width, height in tiles
var cell : Vector2# = Vector2.ZERO

func set_box_cell_ui(cell_pos: Vector2, tilemap: TileMapLayer):
	cell = (cell_pos / 16) - Vector2(1, 1)
	position = tilemap.map_to_local(cell) + tilemap.tile_set.tile_size * 0.5

# func set_cell(cell_pos: Vector2, tilemap: TileMapLayer):
# 	cell = cell_pos
# 	position = tilemap.map_to_local(cell) + tilemap.tile_set.tile_size * 0.5

func move_to_cell(cell_pos: Vector2, tilemap: TileMapLayer, time: float):
	cell = cell_pos
	var target = tilemap.map_to_local(cell) + tilemap.tile_set.tile_size * 0.5
	var tween = create_tween()
	tween.tween_property(self, "position", target, time)
	return tween

func get_occupied_cells() -> Array:
	var cells = []
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			cells.append(cell + Vector2(x, y))
	return cells
