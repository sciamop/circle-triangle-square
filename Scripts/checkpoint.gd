extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("checkpoint triggered")
		# Call the player's handle_checkpoint function
		if body.has_method("handle_checkpoint"):
			body.handle_checkpoint(self)
