extends Node2D

@export var orientation: int = 0 # 0=right, 1=down, 2=left, 3=up
var pivot: Vector2i = Vector2i(2, 2) # Set as needed

# Offsets: [pivot, arm]
const S_OFFSETS = [
	[Vector2i(0,0), Vector2i(1,0)],   # 0: OX (right)
	[Vector2i(0,0), Vector2i(0,1)],   # 1: O below X (down)
	[Vector2i(0,0), Vector2i(-1,0)],  # 2: XO (left)
	[Vector2i(0,0), Vector2i(0,-1)]   # 3: X above O (up)
]

func _ready():
	update_visual()

func set_hinge_cell_ui(cell_pos: Vector2, tilemap: TileMapLayer):
	pivot = (cell_pos / 16) - Vector2(1, 1)
	position = tilemap.map_to_local(pivot) + tilemap.tile_set.tile_size * 0.5

func get_occupied_cells() -> Array:
	var cells = []
	for offset in S_OFFSETS[orientation]:
		cells.append(pivot + offset)
	return cells

func update_visual():
	if has_node("Sprite2D"):
		$Sprite2D.rotation_degrees = 90 * orientation

func can_rotate(clockwise: bool, boxes: Array, hinges_s: Array, hinges_l: Array, hinges_t: Array, hinges_x: Array, hinges_i: Array, walls: Array) -> bool:
	var new_orientation = (orientation + (1 if clockwise else 3)) % 4
	var old_arm = pivot + S_OFFSETS[orientation][1]
	var new_arm = pivot + S_OFFSETS[new_orientation][1]
	
	var sweep_cells = [pivot, old_arm, new_arm]
	
	# Add diagonal cell for the rotation sweep
	if old_arm != new_arm:
		var diag = Vector2i(new_arm.x, old_arm.y)
		if diag == old_arm or diag == new_arm or diag == pivot:
			diag = Vector2i(old_arm.x, new_arm.y)
		# Only add if not already present
		if diag != old_arm and diag != new_arm and diag != pivot:
			sweep_cells.append(diag)
	
	# Remove duplicates
	var unique_cells = []
	for cell in sweep_cells:
		if cell not in unique_cells:
			unique_cells.append(cell)
	sweep_cells = unique_cells
	
	# Check for collision
	for cell in sweep_cells:
		for b in boxes:
			if Vector2(cell) in b.get_occupied_cells():
				return false
		for h in hinges_s:
			if h != self and cell in h.get_occupied_cells():
				return false
		for h in hinges_l:
			if h != self and cell in h.get_occupied_cells():
				return false
		for h in hinges_t:
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

func get_rotation_direction(to_cell: Vector2i, dir: Vector2):
	var offsets = S_OFFSETS[orientation]
	var arm_cell = pivot + offsets[1]

	if to_cell == arm_cell:
		match orientation:
			0: # OX (right)
				if dir.y < 0: return "anti"   # Up
				elif dir.y > 0: return "clock" # Down
			1: # O below X (down)
				if dir.x > 0: return "anti"  # Right
				elif dir.x < 0: return "clock" # Left
			2: # XO (left)
				if dir.y > 0: return "anti"   # Down
				elif dir.y < 0: return "clock" # Up
			3: # X above O (up)
				if dir.x < 0: return "anti"  # Left
				elif dir.x > 0: return "clock" # Right
		return "block"
	elif to_cell == pivot:
		return "block"
	return null
