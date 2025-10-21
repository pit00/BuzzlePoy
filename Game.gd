extends Node2D

@export_category("Gameplay")
@export var step_time : float = 0.12

@onready var floors : TileMapLayer = $Floors
@onready var walls : TileMapLayer = $Walls
@onready var goals : TileMapLayer = $Goals
@onready var player_node : Node2D = $Player
@onready var boxes_root : Node2D = $Boxes
#@onready var box : Node2D = $Box

var player_cell : Vector2 = Vector2.ZERO
var box_cell : Vector2 = Vector2.ZERO
var last_dir = Vector2.ZERO
var move_history : Array = [] # undo stack
var win_anim_playing := false
var boxes : Array = []
# var boxes : Array = [] # of Node (Box instances)
# Startup
func _ready():
	# print("BASE LEVEL")
	# Example: load from file (you can also store strings in the editor)
	# var lvl = FileAccess.open("res://levels/level1.txt", FileAccess.ModeFlags.READ).get_as_text()
	# load_level_from_text(lvl)
	
	# var used_cells = walls.get_used_cells()
	# for cell in used_cells:
	# 	print("Wall at: ", cell)
	
	# Force player to cell (2, 2) for example
	# print(player_node.position / 16)
	set_player_cell_ui()
	# Initialize all boxes
	# box.set_box_cell_ui(box.position, floors) # Box.gd
	boxes = []
	for child in boxes_root.get_children():
		if child is Node2D and child.has_method("move_to_cell"):
			child.set_box_cell_ui(child.position, floors) # Box.gd
			# child.cell = floors.local_to_map(child.position - floors.tile_set.tile_size * 0.5)
			boxes.append(child)
	# Star animation
	$Player/AnimatedSprite2D.play("idle")
	
	# Move
	# set_process_unhandled_input(true)
		# Collect all Box nodes
	# In _ready()
	# boxes = []
	# for child in boxes_root.get_children():
	# 	if child is Node2D and child.has_method("move_to_cell"):
	# 		# Calculate cell from position
	# 		child.cell = floors.local_to_map(child.position - floors.tile_set.tile_size * 0.5)
	# 		boxes.append(child)
	# print(boxes)

# Set Player Cell UI correction
func set_player_cell_ui() -> void:
	var cell = (player_node.position / 16) - Vector2(1, 1)
	player_cell = cell
	player_node.position = floors.map_to_local(cell) + floors.tile_set.tile_size * 0.5

# Set Player Cell
func set_player_cell(cell: Vector2) -> void:
	player_cell = cell
	player_node.position = floors.map_to_local(cell) + floors.tile_set.tile_size * 0.5

# Trigger loop
func _unhandled_input(ev):
	if win_anim_playing:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var dir = Vector2.ZERO
		# Only allow one direction per key press, no diagonals
		if Input.is_action_just_pressed("ui_up"):
			dir = Vector2(0, -1)
		elif Input.is_action_just_pressed("ui_down"):
			dir = Vector2(0, 1)
		elif Input.is_action_just_pressed("ui_left"):
			dir = Vector2(-1, 0)
		elif Input.is_action_just_pressed("ui_right"):
			dir = Vector2(1, 0)
		elif Input.is_action_just_pressed("undo"):
			undo_move()
			return
		elif Input.is_action_just_pressed("restart"):
			get_tree().reload_current_scene()
			return
		elif Input.is_action_just_pressed("menu"):
			get_tree().change_scene_to_file("res://LevelSelect.tscn")
			return
		
		if dir != Vector2.ZERO:
			attempt_move(dir)

# Movment
func attempt_move(dir : Vector2) -> void:
	last_dir = dir
	var to_cell = player_cell + dir

	# Check for wall
	if walls.get_cell_source_id(Vector2i(to_cell)) != -1:
		return

	# Check for box at target cell
	var box_to_push = null
	for b in boxes:
		if to_cell in b.get_occupied_cells():
			box_to_push = b
			break

	if box_to_push:
		# Calculate new cells for the box after push
		var new_cells = []
		for c in box_to_push.get_occupied_cells():
			new_cells.append(c + dir)
		# Check if all new cells are free (no wall, no other box)
		for nc in new_cells:
			if walls.get_cell_source_id(Vector2i(nc)) != -1:
				return
			for other in boxes:
				if other != box_to_push and nc in other.get_occupied_cells():
					return
		# Move box
		box_to_push.cell += dir
		box_to_push.move_to_cell(box_to_push.cell, floors, step_time)
		# Move player
		player_cell = to_cell
		_move_player_to_cell(to_cell, step_time)
		return

	# If no box, check if cell is blocked by any box
	for b in boxes:
		if to_cell in b.get_occupied_cells():
			return

	# Move player
	player_cell = to_cell
	_move_player_to_cell(to_cell, step_time)
	
# Move Player To Cell
func _move_player_to_cell(cell: Vector2, t: float) -> void:
	var target = floors.map_to_local(cell) + floors.tile_set.tile_size * 0.5
	var tween = player_node.create_tween()
	tween.tween_property(player_node, "position", target, t)
	
	var idle_anim = "idle"
	if last_dir == Vector2(0, -1):
		idle_anim = "idle_up"
	elif last_dir == Vector2(0, 1):
		idle_anim = "idle"
	elif last_dir == Vector2(-1, 0):
		idle_anim = "idle_left"
	elif last_dir == Vector2(1, 0):
		idle_anim = "idle_right"
	
	tween.tween_callback(Callable(player_node.get_node("AnimatedSprite2D"), "play").bind(idle_anim))
	
	# Check for goal after movement
	tween.tween_callback(Callable(self, "_check_goal_cell").bind(cell))

# Check Goal Cell
func _check_goal_cell(cell: Vector2) -> void:
	if goals.get_cell_source_id(Vector2i(cell)) != -1:
		# print("Goal reached, playing win animation")
		win_anim_playing = true
		player_node.get_node("AnimatedSprite2D").play("win")
		await get_tree().create_timer(2.0).timeout
		# set_player_cell(Vector2(0, 0))
		# player_node.get_node("AnimatedSprite2D").play("idle")
		win_anim_playing = false
		mark_level_completed(get_tree().current_scene.scene_file_path.get_file())
		get_tree().change_scene_to_file("res://LevelSelect.tscn")

# Box At Cell
func _box_at_cell(cell: Vector2):
	for b in boxes:
		if b.cell == cell:
			return b
	return null

# Undo Move
func undo_move() -> void:
	if move_history.is_empty():
		return
	var last = move_history.pop_back()
	# revert player
	player_cell = last["player_from"]
	_move_player_to_cell(player_cell, step_time)
	# revert box if any
	if last.has("box") and last["box"] != null:
		var id = last["box"]
		for b in boxes:
			if b.get_instance_id() == id:
				b.move_to_cell(last["box_from"], step_time)
				# ensure b.cell is updated immediately to avoid conflicts
				b.cell = last["box_from"]
				break

# Save completed level
func mark_level_completed(level_name):
	var save_path = "user://progress.save"
	var completed = []
	if FileAccess.file_exists(save_path):
		completed = FileAccess.open(save_path, FileAccess.READ).get_var()
	if level_name not in completed:
		completed.append(level_name)
		var file = FileAccess.open(save_path, FileAccess.WRITE)
		file.store_var(completed)
		file.close()
