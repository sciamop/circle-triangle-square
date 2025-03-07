extends HSlider

var min_val:int = 10
var max_val:int = 100
var _step:float = 10
var labelText:String
@export var enemy_mass:float
@export var enemy_gravity_scale:float

@onready var arm_hurt_box: StaticBody2D = $"/root/Game/Player/Skeleton2D/HipBone/BodyBone/HeadBone/upperArmBone/lowerArmBone/ArmHurtBoxWrapper"
#@onready var arm_hurt_box: AnimatableBody2D = $"/root/Game/Player/ArmHurtBoxWrapper"

func _ready() -> void:

	
	labelText = name
	var label:Label = get_child(0)
	label.text = name
	


	if (labelText == "gravity_scale" || labelText == "mass"):
		min_value = -1.0
		max_value = 5.0
		value = 1.0
		step = 0.1
	else:
		min_value = min_val
		max_value = max_val
		step = _step
		value = 66
	
func _on_value_changed(value: float) -> void:
	#print(value)	
	if (labelText == "gravity_scale" || labelText == "mass"):
		 	
		var enemy: RigidBody2D =  get_tree().current_scene.find_child("enemy*")

			
		if enemy:
			enemy.set_deferred(labelText, value)
			
		#
		#if (labelText == "mass"):
			#enemy_mass = value
		#
		#if (labelText == "gravity_scale"):
			#enemy_mass = value
			
	else:
		arm_hurt_box.set_deferred(labelText,value)
		
func _on_drag_ended(value_changed: bool) -> void:
	release_focus()
