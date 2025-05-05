extends Node

# Level management
var current_level: String = "game"
var levels = {
	"game": "res://Scenes/game.tscn",
	"level2": "res://Scenes/level2.tscn"
}

# Player progress
var player_progress = {
	"shapes": {
		"circle": 0,
		"triangle": 0,
		"square": 0
	},
	"health": 100,
	"completed_levels": []
}

# Signals
signal level_changed(new_level)
signal level_completed(level_name)
signal player_progress_saved

func _ready() -> void:
	# Load saved progress if it exists
	load_progress()

func change_level(level_name: String) -> void:
	if not levels.has(level_name):
		print("Error: Level ", level_name, " not found!")
		return
		
	# Save current progress before changing levels
	save_progress()
	
	# Change scene
	get_tree().call_deferred("change_scene_to_file",levels[level_name])
	current_level = level_name
	emit_signal("level_changed", level_name)

func complete_level(level_name: String) -> void:
	if not level_name in player_progress["completed_levels"]:
		player_progress["completed_levels"].append(level_name)
		save_progress()
		emit_signal("level_completed", level_name)

func save_progress() -> void:
	# Get current player state
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_progress["health"] = player.current_health
		player_progress["shapes"]["circle"] = player.circle_pieces
		player_progress["shapes"]["triangle"] = player.triangle_pieces
		player_progress["shapes"]["square"] = player.square_pieces
	
	# Save to file
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_var(player_progress)
	emit_signal("player_progress_saved")

func load_progress() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		return
		
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	player_progress = save_file.get_var()

func apply_saved_progress(player: Node) -> void:
	if player:
		player.current_health = player_progress["health"]
		player.circle_pieces = player_progress["shapes"]["circle"]
		player.triangle_pieces = player_progress["shapes"]["triangle"]
		player.square_pieces = player_progress["shapes"]["square"] 
