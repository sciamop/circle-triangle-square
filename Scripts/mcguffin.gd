extends Node2D

@onready var label: Label = $Label
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func play_meow_sequence() -> void:
	# Show the label
	if label:
		label.visible = true
	
	# Play meow sound
	if audio_player:
		audio_player.stream = preload("res://Sounds/cat-meow.mp3")
		audio_player.play()
	
	# Wait for meow
	await get_tree().create_timer(1.5).timeout
	
	# Hide the label
	if label:
		label.visible = false

func move_to_door(door: Node2D) -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(door.global_position.x,global_position.y), 0.5)
	await tween.finished
	visible = false 
