extends RigidBody2D

var spawn_position:Vector2
var c_layer
var m_layer
var parent

func _ready() -> void:
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
	var new_object = preload("res://Scenes/enemy.tscn").instantiate() 
	var r:int = randi()
	new_object.name = "enemy" + str(r)
	parent.add_child(new_object)
	new_object.global_position = Vector2(spawn_position.x - 10, spawn_position.y - 100)
	new_object.collision_layer = 1
	new_object.collision_mask = 1
	new_object.mass = 1.2
	new_object.gravity_scale = 1.6
	set_process(true)
	set_physics_process(true)
	reset_physics_interpolation()

	
