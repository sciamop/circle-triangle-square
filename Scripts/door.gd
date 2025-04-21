extends Node2D

func _ready() -> void:
	# Connect the body_entered signal
	$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Get the player node to check checkpoint status
		var player = body
		if Global.has_completed_checkpoint:
			# Only change level if checkpoint is completed
			LevelManager.change_level("level2") 
