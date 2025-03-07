extends RigidBody2D

var spawn_position:Vector2
var c_layer
var m_layer
var parent
@onready var _gravity_scale:float = 1.0
@onready var _mass:float = 1.0


func _ready() -> void:
	set_deferred("gravity_scale", _gravity_scale)
	set_deferred("mass", _mass)
	spawn_position = Vector2(position.x,position.y)
	c_layer = collision_layer
	m_layer = collision_mask
	parent = get_parent()
	print(c_layer)
	print(m_layer)

func _process(delta: float) -> void:
	#print(position.y)
	if (position.y < -1000 || position.y > 1000):
		queue_free()
		respawn_object()
		
		
func respawn_object():
	var new_object:RigidBody2D = preload("res://Scenes/enemy.tscn").instantiate() 
	var r:int = randi()
	
	get_parent().add_child(new_object, true)
	new_object.name = "enemy" + str(r)

	new_object.global_position = Vector2(spawn_position.x, spawn_position.y - 100)
	new_object.collision_layer = c_layer
	new_object.collision_mask = m_layer
	new_object.set_deferred("mass", _gravity_scale)
	new_object.set_deferred("gravity_scale", _gravity_scale)
	
	set_process(true)
	set_physics_process(true)
	reset_physics_interpolation()



	
