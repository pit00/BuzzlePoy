extends Control

@onready var levels_dir := "res://levels"
var level_scenes := []
var current_index := 0
var name_map = {
	"Level1-1.tscn": "Level 1-1",
	"Level1-2.tscn": "Level 1-2",
	"Level1-3.tscn": "Level 1-3",
	"Level1-4.tscn": "Level 1-4",
	"Level1-5.tscn": "Level 1-5",
	# "Level1-6.tscn": "Level 1-6",
	"Level1-7.tscn": "Level 1-7",
	# "Level1-8.tscn": "Level 1-8",
	"Level1-9.tscn": "Level 1-9",
	"Level1-10.tscn": "Level 1-10",
	"Level1-11.tscn": "Level 1-11",
	"Level1-12.tscn": "Level 1-12",
	"Level1-13.tscn": "Level 1-13",
	"Level1-14.tscn": "Level 1-14",
	# "Level1-15.tscn": "Level 1-15",
	"Level1-16.tscn": "Level 1-16",
	# "Level1-17.tscn": "Level 1-17",
	# "Level1-18.tscn": "Level 1-18",
	"Level1-19.tscn": "Level 1-19",
	"Level1-20.tscn": "Level 1-20",
	# "Level2-1.tscn": "Level 2-1",
	# "Level2-2.tscn": "Level 2-2",
	# "Level2-3.tscn": "Level 2-3",
	# "Level2-4.tscn": "Level 2-4",
	# "Level2-5.tscn": "Level 2-5",
	"Level2-6.tscn": "Level 2-6",
	# "Level2-7.tscn": "Level 2-7",
	# "Level2-8.tscn": "Level 2-8",
	# "Level2-9.tscn": "Level 2-9",
	# "Level2-10.tscn": "Level 2-10",
	# "Level2-11.tscn": "Level 2-11",
	# "Level2-12.tscn": "Level 2-12",
	# "Level2-13.tscn": "Level 2-13",
	"Level2-14.tscn": "Level 2-14",
	# "Level2-15.tscn": "Level 2-15",
	# "Level2-16.tscn": "Level 2-16",
	# "Level2-17.tscn": "Level 2-17",
	# "Level2-18.tscn": "Level 2-18",
	# "Level2-19.tscn": "Level 2-19",
	# "Level2-20.tscn": "Level 2-20",
	# "Level3-1.tscn": "Level 3-1",
	# "Level3-2.tscn": "Level 3-2",
	# "Level3-3.tscn": "Level 3-3",
	# "Level3-4.tscn": "Level 3-4",
	# "Level3-5.tscn": "Level 3-5",
	# "Level3-6.tscn": "Level 3-6",
	# "Level3-7.tscn": "Level 3-7",
	# "Level3-8.tscn": "Level 3-8",
	# "Level3-9.tscn": "Level 3-9",
	# "Level3-10.tscn": "Level 3-10",
	# "Level3-11.tscn": "Level 3-11",
	# "Level3-12.tscn": "Level 3-12",
	# "Level3-13.tscn": "Level 3-13",
	# "Level3-14.tscn": "Level 3-14",
	# "Level3-15.tscn": "Level 3-15",
	# "Level3-16.tscn": "Level 3-16",
	# "Level3-17.tscn": "Level 3-17",
	# "Level3-18.tscn": "Level 3-18",
	# "Level3-19.tscn": "Level 3-19",
	# "Level3-20.tscn": "Level 3-20",
	# "Level4-1.tscn": "Level 4-1",
	# "Level4-2.tscn": "Level 4-2",
	# "Level4-3.tscn": "Level 4-3",
	# "Level4-4.tscn": "Level 4-4",
	# "Level4-5.tscn": "Level 4-5",
	# "Level4-6.tscn": "Level 4-6",
	# "Level4-7.tscn": "Level 4-7",
	# "Level4-8.tscn": "Level 4-8",
	# "Level4-9.tscn": "Level 4-9",
	# "Level4-10.tscn": "Level 4-10",
	# "Level4-11.tscn": "Level 4-11",
	# "Level4-12.tscn": "Level 4-12",
	# "Level4-13.tscn": "Level 4-13",
	# "Level4-14.tscn": "Level 4-14",
	# "Level4-15.tscn": "Level 4-15",
	# "Level4-16.tscn": "Level 4-16",
	# "Level4-17.tscn": "Level 4-17",
	# "Level4-18.tscn": "Level 4-18",
	# "Level4-19.tscn": "Level 4-19",
	# "Level4-20.tscn": "Level 4-20"
}

@onready var label := $LevelNameLabel

func _ready():
	# Find all .tscn level scenes
	var dir = DirAccess.open(levels_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				level_scenes.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		# Sort level_scenes by numeric value
		level_scenes.sort_custom(func(a, b):
			# Extract all numbers from filenames like "Level1-13.tscn"
			var regex = RegEx.new()
			regex.compile("\\d+")
			var matches_a = regex.search_all(a)
			var matches_b = regex.search_all(b)
			var world_a = int(matches_a[0].get_string()) if matches_a.size() > 0 else 0
			var level_a = int(matches_a[1].get_string()) if matches_a.size() > 1 else 0
			var world_b = int(matches_b[0].get_string()) if matches_b.size() > 0 else 0
			var level_b = int(matches_b[1].get_string()) if matches_b.size() > 1 else 0
			if world_a == world_b:
				return level_a < level_b
			else:
				return world_a < world_b
		)
	
	if level_scenes.size() > 0:
		current_index = 0
		_update_label()

func _unhandled_input(event):
	if Input.is_action_just_pressed("debug"):
		get_tree().change_scene_to_file("res://Base.tscn")
	if event is InputEventKey and event.pressed and not event.echo:
		if Input.is_action_just_pressed("ui_left"):
			current_index = (current_index - 1 + level_scenes.size()) % level_scenes.size()
			_update_label()
		elif Input.is_action_just_pressed("ui_right"):
			current_index = (current_index + 1) % level_scenes.size()
			_update_label()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_load_selected_level()
			Input.is_action_just_pressed("debug")

func _update_label():
	var file = level_scenes[current_index]
	label.text = name_map.get(file, file)
	if is_level_completed(file):
		label.text += " 😃"
	# label.text = level_scenes[current_index]

func _load_selected_level():
	var scene_path = levels_dir + "/" + level_scenes[current_index]
	get_tree().change_scene_to_file(scene_path)

# Check if level is completed
func is_level_completed(level_name):
	var save_path = "user://progress.save"
	if FileAccess.file_exists(save_path):
		var completed = FileAccess.open(save_path, FileAccess.READ).get_var()
		return level_name in completed
	return false
