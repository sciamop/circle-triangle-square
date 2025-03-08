extends RigidBody2D

var spawn_position:Vector2
var c_layer
var m_layer
var parent

@onready var _gravity_scale:float = 1.0
@onready var _mass:float = 1.0

@export var health: int = 100
@export var move_speed: int = 80
@export var max_speed: int = 150


# Hit management
@export var invulnerability_time: float = 0.5  # Seconds of invulnerability after being hit
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
var last_hit_time: int = 0  # To track time between hits using OS.get_ticks_msec()

# Movement State
enum State {IDLE, CHASING, KNOCKED}
var current_state: State = State.IDLE
var knockback_timer: float = 0.0
var knockback_recovery_time: float = 0.23
@onready var game_manager: Node2D = $"/root/Game"



func _ready() -> void:
	#set_deferred("gravity_scale", _gravity_scale)
	#set_deferred("mass", _mass)
	spawn_position = Vector2(position.x,position.y)
	c_layer = collision_layer
	m_layer = collision_mask
	parent = get_parent()

func _process(delta: float) -> void:
	#print(position.y)
	# Handle invulnerability timer
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false
			# Reset visual effects that indicate invulnerability
			modulate.a = 1.0
	
	
	
	if (position.y < -1000 || position.y > 1000):
		queue_free()
		respawn_object()
		
		
func take_damage(damage:int):
	
	if is_invulnerable:
		return
	
	# Detect and handle potential rapid-fire hits
	var current_time = Time.get_ticks_msec()
	if current_time - last_hit_time < 50:  # Less than 50ms between hits is suspicious
		print("Hit rejected: too close to previous hit")
		return
	last_hit_time = current_time
	game_manager.pause_game()
	
	# Make invulnerable for a short period
	is_invulnerable = true
	invulnerability_timer = invulnerability_time
	
	health = health - damage
	print("Enemy health = " + str(health))
	
	if health <=0:
		die()
	
		
func respawn_object():
	var enemies = ["enemy","enemy02","enemy03"]
	var enemyStr:String = enemies[randi() % 3]

	
	var new_object:RigidBody2D
	
	if (enemyStr == "enemy"):	if (enemyStr == "enemy"):
		new_object = load("res://Scenes/enemy.tscn").instantiate() 
	if (enemyStr == "enemy02"):
		new_object = load("res://Scenes/enemy02.tscn").instantiate() 
	if (enemyStr == "enemy03"):
		new_object = load("res://Scenes/enemy03.tscn").instantiate() 
	
	
	var r:int = randi()
	
	get_parent().add_child(new_object, true)
	new_object.name = "enemy" + str(r)
	var xRand:int = randi() % 200 - 200
	new_object.global_position = Vector2(spawn_position.x + xRand, spawn_position.y - 200)
	new_object.collision_layer = c_layer
	new_object.collision_mask = m_layer
	#new_object.set_deferred("mass", _gravity_scale)
	#new_object.set_deferred("gravity_scale", _gravity_scale)
	
	set_process(true)
	set_physics_process(true)
	reset_physics_interpolation()

func die():
	queue_free()
	respawn_object()	

	
