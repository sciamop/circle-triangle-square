extends Node2D

@export var pause_duration: float = 0.05  # How long to pause on collision
@export var freeze_physics: bool = true   # If true, freeze physics instead of full game pause
var pause_timer: float = 0.0
var is_paused: bool = false

@onready var timer: Timer = $"/root/Game/Timer"

func _process(delta: float) -> void:
	pass

func pause_game():
	pass
	#Engine.time_scale = 0.05  # Almost paused but not completely
	#
	#timer.start()
	
func _on_timer_timeout() -> void:
	#player.set_freeze_enabled(false)
	Engine.time_scale = 1.5
	#get_tree().reload_current_scene()
