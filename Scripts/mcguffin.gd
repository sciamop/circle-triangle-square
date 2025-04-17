extends Node2D

@onready var label: Label = $Label
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var player: Node2D = $"/root/Game/Player"


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
	# Tween to door's x position
	var tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(door.global_position.x, global_position.y), 0.5)
	await tween.finished
	visible = false
	# Play door's cat_escape animation
	var door_anim = door.get_node("AnimationPlayer")
	if door_anim:
		door_anim.play("cat_escape")
		await door_anim.animation_finished
		door.hide()
		door_anim.play("RESET")
	# Move instantly to checkpoint2
	var checkpoint1 = get_tree().get_nodes_in_group("checkpoint")[0]
	checkpoint1.queue_free()
	
	var checkpoint2 = get_tree().get_nodes_in_group("checkpoint")[1]
	if checkpoint2:
		visible = true
		global_position = checkpoint2.global_position
		door.global_position = Vector2(checkpoint2.global_position.x - 100, checkpoint2.global_position.y - 53)
		door.show()
		door_anim.play("portal_open")
		await door_anim.animation_finished
		door_anim.play("RESET")

		if player and player.has_method("zoom_on_checkpoint"):
			await player.zoom_on_checkpoint(checkpoint2)
			
			door_anim.play("cat_escape")
			await door_anim.animation_finished
			door.hide()
			door.global_position = Vector2(player.global_position.x - 100, player.global_position.y - 53)
			door.show()
			door_anim.play("portal_open")
			await door_anim.animation_finished
			door_anim.play("RESET")
		
	 
