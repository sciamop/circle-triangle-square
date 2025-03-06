extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var velocity = Vector2()
	var collision = move_and_collide(velocity * delta)
	
	if collision && collision.get_collider() is RigidBody2D:
		var colObj:RigidBody2D = collision.get_collider()
		print(collision.get_collider().name)
		if (colObj.name == "enemy"):
			
			
			colObj.set_deferred("freeze",false)
			var enemyCollider:CollisionShape2D = colObj.get_child(1)
			
			
			
			var force = Vector2(330,10)
			
			var direction = Vector2(-30,0)
			#colObj.apply_impulse(direction, random_force)
			#colObj.queue_free()  # Remove the character
			colObj.linear_velocity = direction.normalized() * force
		
func explode(colObj):
	print("move it move it")
	var random_force = Vector2(randf_range(-130, 130), randf_range(-130, -130))
	colObj.apply_impulse(Vector2.ZERO, random_force)

	#colObj.queue_free()  # Remove the character
	
	
