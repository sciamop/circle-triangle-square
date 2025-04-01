extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("Checkpoint triggered")
	if body.is_in_group("player"):
		# Call the player's handle_checkpoint function
		if body.has_method("handle_checkpoint"):
			body.handle_checkpoint(self)
