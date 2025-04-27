extends Area2D

@export var oob_to_display: String = ""
var is_in_body: bool = false
signal oob_triggered(oob_to_display: String)


func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player")):
		var scaleTween:Tween = create_tween()
		var scaleTo: Vector2 = Vector2(1.5,1.5)
		scaleTween.tween_property(self,"scale",scaleTo,0.125)

		is_in_body = true

func _on_area_exited(area: Area2D) -> void:
	if (area.is_in_group("player")):
		var scaleTween:Tween = create_tween()
		var scaleTo: Vector2 = Vector2(0.5,0.5)
		scaleTween.tween_property(self,"scale",scaleTo,0.25)
		is_in_body = false

func _process(delta:float) -> void:
	if is_in_body == true and Input.is_action_just_pressed("activate"):
		emit_signal("oob_triggered", oob_to_display)

func _on_body_exited(body: Node2D) -> void:
	if (body.is_in_group("player")):
		var scaleTween:Tween = create_tween()
		var scaleTo: Vector2 = Vector2(0.75,0.75)
		scaleTween.tween_property(self,"scale",scaleTo,0.125)
		is_in_body = false
