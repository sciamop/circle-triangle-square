extends Area2D

@export var oob_to_display: String = ""
@onready var ui: CanvasLayer = $"/root/Game/UI"
@onready var dialogue_visible: bool = true
var is_in_body: bool = false
signal oob_triggered(oob_to_display: String)

func _ready() -> void:
	var _is_dialogue_visible = Callable(self, "is_dialogue_visible") 
	ui.connect("dialog_visible", _is_dialogue_visible)

func is_dialogue_visible(visible: bool) -> void:
	dialogue_visible = visible

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


func _on_body_exited(body: Node2D) -> void:
	if (body.is_in_group("player")):
		var scaleTween:Tween = create_tween()
		var scaleTo: Vector2 = Vector2(0.75,0.75)
		scaleTween.tween_property(self,"scale",scaleTo,0.125)
		is_in_body = false

func _process(delta:float) -> void:
	if is_in_body == true and Input.is_action_just_pressed("activate") and dialogue_visible == false:
		emit_signal("oob_triggered", oob_to_display)
	
			
