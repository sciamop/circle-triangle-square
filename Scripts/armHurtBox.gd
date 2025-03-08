extends RigidBody2D

var forceX: int = 1000
var forceY: int = 1000
var dirX: int = 1000
var dirY: int = 1000
@export var attack_cooldown: float = 0.5

var damage: int = 10
@onready var game_manager: Node2D = $"/root/Game"
@onready var player: CharacterBody2D = $"../../../../../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	#set_deferred("disabled", true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var velocity = Vector2(200,144)
	var collision = move_and_collide(velocity * delta)
	
	if collision && collision.get_collider() is RigidBody2D:
		var colObj:RigidBody2D = collision.get_collider()
	
		if (colObj.name.contains("enemy") && player.is_slashing):

			#colObj.move_local_x(1000 * delta) 
			colObj.apply_central_impulse(Vector2(66,22) * player.last_direction)
			game_manager.pause_game()
			colObj.take_damage(damage)
			
	position = Vector2(-10,-20)
