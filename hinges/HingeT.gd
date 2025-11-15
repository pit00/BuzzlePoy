extends Node2D

@export var orientation: int = 0 # 0=up, 1=right, 2=down, 3=left
var pivot: Vector2i = Vector2i(2, 2) # Set as needed

const T_OFFSETS = [
	[Vector2i(0,0), Vector2i(0,-1), Vector2i(-1,0), Vector2i(1,0)],   # Up
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)],    # Right
	[Vector2i(0,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(1,0)],    # Down
	[Vector2i(0,0), Vector2i(-1,0), Vector2i(0,-1), Vector2i(0,1)]    # Left
]

func _ready():
	update_visual()

func set_hinge_cell_ui(cell_pos: Vector2, tilemap: TileMapLayer):
	pivot = (cell_pos / 16) - Vector2(1, 1)
	position = tilemap.map_to_local(pivot) + tilemap.tile_set.tile_size * 0.5

func get_occupied_cells() -> Array:
	var cells = []
	for offset in T_OFFSETS[orientation]:
		cells.append(pivot + offset)
	return cells

func update_visual():
	if has_node("Sprite2D"):
		$Sprite2D.rotation_degrees = 90 * orientation

func can_rotate(clockwise: bool, boxes: Array, hinges_s: Array, hinges_t: Array, hinges_l: Array, hinges_x: Array, hinges_i: Array, walls: Array) -> bool:
	# var old_orientation = orientation
	# var new_orientation = (orientation + (1 if clockwise else 3)) % 4

	# Get all cells in the 3x3 grid around the pivot
	var sweep_cells = []
	for x in range(pivot.x - 1, pivot.x + 2):
		for y in range(pivot.y - 1, pivot.y + 2):
			sweep_cells.append(Vector2i(x, y))

	# Determine which cell to remove based on orientation and direction
	var rel_remove = null
	
	match orientation:
		0:
			rel_remove = Vector2i(-1, 1) if clockwise else Vector2i(1, 1)
		1:
			rel_remove = Vector2i(-1, -1) if clockwise else Vector2i(-1, 1)
		2:
			rel_remove = Vector2i(1, -1) if clockwise else Vector2i(-1, -1)
		3:
			rel_remove = Vector2i(1, 1) if clockwise else Vector2i(1, -1)
	
	var remove_cell = pivot + rel_remove
	sweep_cells.erase(remove_cell)
	
	# Print sweep_cells as ASCII grid
	# var min_x = pivot.x - 1
	# var max_x = pivot.x + 1
	# var min_y = pivot.y - 1
	# var max_y = pivot.y + 1
	# var cell_set = {}
	# for cell in sweep_cells:
	# 	cell_set[cell] = true
	# for y in range(min_y, max_y + 1):
	# 	var line = ""
	# 	for x in range(min_x, max_x + 1):
	# 		if cell_set.has(Vector2i(x, y)):
	# 			line += "X "
	# 		else:
	# 			line += ". "
	# 	print(line)
	
	# Check for collision with boxes or other hinges
	for cell in sweep_cells:
		for b in boxes:
			if Vector2(cell) in b.get_occupied_cells():
				return false
		for h in hinges_t:
			if h != self and cell in h.get_occupied_cells():
				return false
		for h in hinges_l:
			if h != self and cell in h.get_occupied_cells():
				return false
		for h in hinges_x:
			if h != self and cell in h.get_occupied_cells():
				return false
		for h in hinges_i:
			if h != self and cell in h.get_occupied_cells():
				return false
		for h in hinges_s:
			if h != self and cell in h.get_occupied_cells():
				return false
		for w in walls:
			if cell == w:
				return false
	return true


func rotate_hinge(clockwise: bool):
	orientation = (orientation + (1 if clockwise else 3)) % 4
	update_visual()

func get_rotation_direction(to_cell: Vector2i, dir: Vector2):
	var offsets = T_OFFSETS[orientation]
	# Arm indices: 1=up, 2=left, 3=right (for orientation 0)
	# Up arm
	if to_cell == pivot + offsets[1]:
		match orientation:
			0: # Up
				if dir.x > 0: return "clock2"
				elif dir.x < 0: return "anti2"
			1: # Right
				if dir.y > 0: return "clock2"
				elif dir.y < 0: return "anti2"
			2: # Down
				if dir.x < 0: return "clock2"
				elif dir.x > 0: return "anti2"
			3: # Left
				if dir.y < 0: return "clock2"
				elif dir.y > 0: return "anti2"
		return "block"
	# Left arm
	elif to_cell == pivot + offsets[2]:
		match orientation:
			0: # Up
				if dir.y < 0: return "clock"
				elif dir.y > 0: return "anti2"
			1: # Right
				if dir.x < 0: return "anti2"
				elif dir.x > 0: return "clock"
			2: # Down
				if dir.y > 0: return "anti"
				elif dir.y < 0: return "clock2"
			3: # Left
				if dir.x > 0: return "clock2"
				elif dir.x < 0: return "anti"
		return "block"
	# Right arm
	elif to_cell == pivot + offsets[3]:
		match orientation:
			0: # Up
				if dir.y > 0: return "clock2"
				elif dir.y < 0: return "anti"
			1: # Right
				if dir.x > 0: return "anti"
				elif dir.x < 0: return "clock2"
			2: # Down
				if dir.y < 0: return "anti2"
				elif dir.y > 0: return "clock"
			3: # Left
				if dir.x < 0: return "clock"
				elif dir.x > 0: return "anti2"
		return "block"
	elif to_cell == pivot:
		return "block"
	return null
