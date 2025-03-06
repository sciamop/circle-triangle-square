extends CharacterBody2D

var speed = 200.0
var accel = 433
const MAXSPEED = 300
const JUMP_VELOCITY = -420.0

@onready var player_anim_player: AnimationPlayer = $PlayerAnimPlayer
@onready var dash_particles: GPUParticles2D = $DashParticles

@export var dash_speed: float = 620.0
@export var dash_duration: float = 0.5
@export var dash_cooldown: float = 1.0

@onready var player: CharacterBody2D = $"."

var is_dashing = false
var can_dash = true
var dash_particle_process_mat;
var has_exploded = false

func _ready() -> void:
	dash_particle_process_mat = dash_particles.process_material;

func explode():
	if has_exploded:
		return  # Stop if already exploded

	var pieces_scene = preload("res://Scenes/brokenPlayer.tscn").instantiate() 
	pieces_scene.global_position = global_position
	get_parent().add_child(pieces_scene)
	
	has_exploded = true  # Mark explosion as happened  # Add pieces to the scene

	queue_free()  # Remove the character

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		print(collision.get_collider().name)
		if collision.get_collider().name == "enemy":
			explode()
	

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		#velocity.x = direction * SPEED
		velocity.x = move_toward(velocity.x, direction * MAXSPEED,accel * delta)
		can_dash = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		player_anim_player.play("idle")
		can_dash = false
		
	if is_on_floor():
		if direction < 0:
			player_anim_player.play("walkLeft")
		
		elif direction > 0:
			player_anim_player.play("walkRight")

	move_and_slide()
	
func _process(delta):
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
		
func start_dash():
	
	is_dashing = true
	can_dash = false
	
	# Start the dash particle effect
	dash_particles.emitting = true
	var direction := Input.get_axis("ui_left", "ui_right")
	var current_particle_direction = dash_particle_process_mat.get_direction()
	
	dash_particle_process_mat.set_direction(Vector3(direction * -1,current_particle_direction.y,current_particle_direction.z))
	
	#dash_particles.EMIT_FLAG_VELOCITY = direction
	velocity = velocity.normalized() * dash_speed
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	dash_particles.emitting = false
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
