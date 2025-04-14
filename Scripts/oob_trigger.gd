extends Area2D

@export var oob_to_display: String = ""

signal oob_triggered(oob_to_display: String)

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player")):
		print(oob_to_display)
		emit_signal("oob_triggered", oob_to_display)
