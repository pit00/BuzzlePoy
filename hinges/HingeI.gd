extends Node2D

var pivot: Vector2i = Vector2i(2, 2) # Set as needed
@export var orientation: int = 0 # 0=vertical, 1=horizontal

# I shape: 3 cells, pivot at center
const I_OFFSETS = [
	[Vector2i(0,0), Vector2i(0,-1), Vector2i(0,1)],   # 0° vertical
	[Vector2i(0,0), Vector2i(1,0), Vector2i(-1,0)],   # 90° horizontal
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,-1)],   # 180° vertical (same as 0°, but for rotation logic)
	[Vector2i(0,0), Vector2i(-1,0), Vector2i(1,0)]    # 270° horizontal (same as 90°, but for rotation logic)
]

func _ready():
	update_visual()

func set_hinge_cell_ui(cell_pos: Vector2, tilemap: TileMapLayer):
	pivot = (cell_pos / 16) - Vector2(1, 1)
	position = tilemap.map_to_local(pivot) + tilemap.tile_set.tile_size * 0.5

func get_occupied_cells() -> Array:
	var cells = []
	for offset in I_OFFSETS[orientation]:
		cells.append(pivot + offset)
	return cells

func update_visual():
	if has_node("Sprite2D"):
		$Sprite2D.rotation_degrees = 90 * orientation

func can_rotate(clockwise: bool, boxes: Array, hinges_s: Array, hinges_t: Array, hinges_l: Array, hinges_x: Array, hinges_i: Array, walls: Array) -> bool:
	var old_orientation = orientation
	var new_orientation = (orientation + (1 if clockwise else 3)) % 4
	var old_cells = []
	for offset in I_OFFSETS[old_orientation]:
		old_cells.append(pivot + offset)
	var new_cells = []
	for offset in I_OFFSETS[new_orientation]:
		new_cells.append(pivot + offset)
	var sweep_cells = old_cells + new_cells
	
	# Find moving ends: only the tips that change position
	var moving_ends = []
	for cell in old_cells:
		if cell != pivot and cell not in new_cells:
			moving_ends.append(cell)
	for cell in new_cells:
		if cell != pivot and cell not in old_cells:
			moving_ends.append(cell)
	# Ensure only 2 moving ends
	if moving_ends.size() > 2:
		moving_ends = moving_ends.slice(0, 2)
	# Calculate diagonals for just those 2
	var diag_cells = []
	for end_cell in moving_ends:
		var offset = end_cell - pivot
		var diag_offset = Vector2i(-offset.y, offset.x) if clockwise else Vector2i(offset.y, -offset.x)
		var diag_cell = pivot + offset + diag_offset
		diag_cells.append(diag_cell)
	# Add only these diagonals to sweep_cells
	for cell in diag_cells:
		if cell not in sweep_cells:
			sweep_cells.append(cell)
	
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
	var offsets = I_OFFSETS[orientation]
	var a_cell = pivot + offsets[1]
	var b_cell = pivot + offsets[2]
	
	match orientation:
		0: # vertical (up/down)
			if to_cell == a_cell:
				if dir.x > 0: return "clock"
				elif dir.x < 0: return "anti"
				else: return "block"
			elif to_cell == b_cell:
				if dir.x < 0: return "clock"
				elif dir.x > 0: return "anti"
				else: return "block"
		2: # vertical (up/down)
			if to_cell == a_cell:
				if dir.x > 0: return "anti"
				elif dir.x < 0: return "clock"
				else: return "block"
			elif to_cell == b_cell:
				if dir.x < 0: return "anti"
				elif dir.x > 0: return "clock"
				else: return "block"
		1: # horizontal (left/right)
			if to_cell == a_cell:
				if dir.y > 0: return "clock"
				elif dir.y < 0: return "anti"
				else: return "block"
			elif to_cell == b_cell:
				if dir.y < 0: return "clock"
				elif dir.y > 0: return "anti"
				else: return "block"
		3: # horizontal (left/right)
			if to_cell == a_cell:
				if dir.y > 0: return "anti"
				elif dir.y < 0: return "clock"
				else: return "block"
			elif to_cell == b_cell:
				if dir.y < 0: return "anti"
				elif dir.y > 0: return "clock"
				else: return "block"
	if to_cell == pivot:
		return "block"
	return null
