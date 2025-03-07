extends Area2D

@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	if (body.name == "Player"):
		print("You Died")
		Engine.time_scale = 0.5
		timer.start()
	
	if (body.name.contains("enemy")):

		body.respawn_object()
		body.queue_free()
		#get_parent().add_child(enemy)
		
	#body.get_node("CollisionShape2D").queue_free()

#when timer runds out it calls the standard function
func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
