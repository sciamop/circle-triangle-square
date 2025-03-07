extends StaticBody2D

var forceX: int = 1000
var forceY: int = 1000
var dirX: int = 1000
var dirY: int = 1000

@onready var player: CharacterBody2D = $"../../../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	set_deferred("disabled", true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var velocity = Vector2()
	var collision = move_and_collide(velocity * delta)
	
	if collision && collision.get_collider() is RigidBody2D:
		var colObj:RigidBody2D = collision.get_collider()
		#print(collision.get_collider().name)
		
		# added is slashing so kill is only possible on strike
		if (colObj.name.contains("enemy") && player.is_slashing):
			
			colObj.set_deferred("freeze",false)
			
			var enemyCollider:CollisionShape2D = colObj.get_child(1)
			print(forceY)
			var force = Vector2(forceX,forceY) * player.last_direction
			var direction = Vector2(dirX,dirY) * player.last_direction
			
			#colObj.apply_impulse(direction, random_force)
			#colObj.queue_free()  # Remove the character
			#colObj.linear_velocity = direction.normalized() * force
			#var random_force = Vector2(-30,-50)
			colObj.apply_impulse(direction, force)
	
	set_deferred("position", Vector2(-10,-20))


	#colObj.queue_free()  # Remove the character
	
	
