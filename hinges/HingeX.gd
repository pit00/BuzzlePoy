extends Node2D

var pivot: Vector2i = Vector2i(2, 2) # Set as needed
var orientation: int = 0 # 0=up, 1=right, 2=down, 3=left

const CROSS_OFFSETS = [
	[Vector2i(0,0), Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)],   # 0°
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1)],   # 90°
	[Vector2i(0,0), Vector2i(0,1), Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,0)],   # 180°
	[Vector2i(0,0), Vector2i(-1,0), Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1)]    # 270°
]

func set_hinge_cell_ui(cell_pos: Vector2, tilemap: TileMapLayer):
	pivot = (cell_pos / 16) - Vector2(1, 1)
	position = tilemap.map_to_local(pivot) + tilemap.tile_set.tile_size * 0.5

func get_occupied_cells() -> Array:
	var cells = []
	for offset in CROSS_OFFSETS[orientation]:
		cells.append(pivot + offset)
	return cells

func update_visual():
	if has_node("Sprite2D"):
		$Sprite2D.rotation_degrees = 90 * orientation

func can_rotate(clockwise: bool, boxes: Array, hinges_t: Array, hinges_l: Array, hinges_x: Array, hinges_i: Array, walls: Array) -> bool:
	var old_orientation = orientation
	var new_orientation = (orientation + (1 if clockwise else 3)) % 4
	var old_offsets = CROSS_OFFSETS[old_orientation]
	var new_offsets = CROSS_OFFSETS[new_orientation]
	var sweep_cells = []
	
	# Add all cells from old and new positions
	for offset in old_offsets:
		sweep_cells.append(pivot + offset)
	for offset in new_offsets:
		sweep_cells.append(pivot + offset)
	
	# Get all arms (excluding pivot)
	var arms = []
	for i in range(1, 5):
		arms.append(pivot + old_offsets[i])
		arms.append(pivot + new_offsets[i])
	
	# Find bounding box
	var xs = [pivot.x]
	var ys = [pivot.y]
	for cell in arms:
		xs.append(cell.x)
		ys.append(cell.y)
	var min_x = xs.min()
	var max_x = xs.max()
	var min_y = ys.min()
	var max_y = ys.max()
	
	# Add all cells in bounding box
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			sweep_cells.append(Vector2i(x, y))
	
	# Remove duplicates
	var unique_cells = []
	for cell in sweep_cells:
		if cell not in unique_cells:
			unique_cells.append(cell)
	sweep_cells = unique_cells
	
	# Check for collision with boxes, hinges, or walls
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
		for w in walls:
			if cell == w:
				return false
	return true

func rotate_hinge(clockwise: bool):
	orientation = (orientation + (1 if clockwise else 3)) % 4
	update_visual()
	# print(clockwise)
	# if clockwise:
	# 	$Sprite2D.rotation_degrees += 90
	# else:
	# 	$Sprite2D.rotation_degrees -= 90

func get_rotation_direction(to_cell: Vector2i, dir: Vector2):
	var offsets = CROSS_OFFSETS[orientation]
	# Arm indices: 1=up, 2=right, 3=down, 4=left (for orientation 0)
	# Adjust direction logic for each orientation
	# Up arm
	if to_cell == pivot + offsets[1]:
		match orientation:
			0: # Up
				if dir.x < 0: return "anti2"
				elif dir.x > 0: return "clock2"
			1: # Right
				if dir.y > 0: return "clock2"
				elif dir.y < 0: return "anti2"
			2: # Down
				if dir.x > 0: return "anti2"
				elif dir.x < 0: return "clock2"
			3: # Left
				if dir.y < 0: return "clock2"
				elif dir.y > 0: return "anti2"
		return "block"
	# Right arm
	elif to_cell == pivot + offsets[2]:
		match orientation:
			0: # Up
				if dir.y > 0: return "clock2"
				elif dir.y < 0: return "anti2"
			1: # Right
				if dir.x > 0: return "anti2"
				elif dir.x < 0: return "clock2"
			2: # Down
				if dir.y < 0: return "clock2"
				elif dir.y > 0: return "anti2"
			3: # Left
				if dir.x < 0: return "anti2"
				elif dir.x > 0: return "clock2"
		return "block"
	# Down arm
	elif to_cell == pivot + offsets[3]:
		match orientation:
			0: # Up
				if dir.x > 0: return "anti2"
				elif dir.x < 0: return "clock2"
			1: # Right
				if dir.y < 0: return "clock2"
				elif dir.y > 0: return "anti2"
			2: # Down
				if dir.x < 0: return "anti2"
				elif dir.x > 0: return "clock2"
			3: # Left
				if dir.y > 0: return "clock2"
				elif dir.y < 0: return "anti2"
		return "block"
	# Left arm
	elif to_cell == pivot + offsets[4]:
		match orientation:
			0: # Up
				if dir.y < 0: return "clock2"
				elif dir.y > 0: return "anti2"
			1: # Right
				if dir.x < 0: return "anti2"
				elif dir.x > 0: return "clock2"
			2: # Down
				if dir.y > 0: return "clock2"
				elif dir.y < 0: return "anti2"
			3: # Left
				if dir.x > 0: return "anti2"
				elif dir.x < 0: return "clock2"
		return "block"
	elif to_cell == pivot:
		return "block"
	return null
