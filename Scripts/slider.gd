extends HSlider

var min_val:int = 10
var max_val:int = 666
var _step:float = 10
var labelText:String
@export var enemy_mass:float
@export var enemy_gravity_scale:float

@onready var arm_hurt_box: RigidBody2D = $"/root/Game/Player/Skeleton2D/HipBone/BodyBone/HeadBone/upperArmBone/lowerArmBone/ArmHurtBoxWrapper"
#@onready var arm_hurt_box: AnimatableBody2D = $"/root/Game/Player/ArmHurtBoxWrapper"

func _ready() -> void:

	
	labelText = name
	var label:Label = get_child(0)
	label.text = name
	
	min_value = min_val
	max_value = max_val
	step = _step
	value = 222
	
func _on_value_changed(value: float) -> void:
	#print(value)	
	arm_hurt_box.set_deferred(labelText,value)
		
func _on_drag_ended(value_changed: bool) -> void:
	release_focus()
