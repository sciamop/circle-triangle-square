extends HSlider

var min_val:int = 10
var max_val:int = 100
var _step:float = 10
var labelText:String

@onready var arm_hurt_box: AnimatableBody2D = $"/root/Game/Player/ArmHurtBoxWrapper"

func _ready() -> void:
	min_value = min_val
	max_value = max_val
	step = _step
	
	labelText = name
	var label:Label = get_child(0)
	label.text = name
	
	if (labelText == "forceX"):
		value = 30
	if (labelText == "forceY"):
		value = 30
	if (labelText == "dirX"):
		value = 40
	if (labelText == "dirY"):
		value = 50
	
	
func _on_value_changed(value: float) -> void:
	print(value)	
	if (labelText == "forceX"):
		arm_hurt_box.forceX = value
	if (labelText == "forceY"):
		arm_hurt_box.forceY = value
	if (labelText == "dirX"):
		arm_hurt_box.dirX = value * -1
	if (labelText == "dirY"):
		arm_hurt_box.dirY = value * -1
		
func _on_drag_ended(value_changed: bool) -> void:
	release_focus()
