extends CharacterBody2D

class_name Player


# Movement parameters
@export var move_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1300.0
@export var air_friction: float = 400.0

# Jump parameters
@export var jump_force: float = 600.0
@export var jump_cut_height: float = 0.4
@export var jump_buffer_time: float = 0.15
@export var coyote_time: float = 0.15
@export var gravity: float = 1500.0
@export var fall_gravity_multiplier: float = 1.5
@export var max_fall_speed: float = 1000.0

# Wall sliding/jumping
@export var wall_slide_speed: float = 150.0
@export var wall_slide_gravity: float = 500.0
@export var wall_jump_force: Vector2 = Vector2(500, 600)
@export var wall_jump_time: float = 0.2

# Dash parameters
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8

# Combat parameters
@export var melee_damage: int = 10
@export var melee_cooldown: float = 0.5
@export var ranged_damage: int = 8
@export var ranged_cooldown: float = 0.7
@export var ranged_projectile_speed: float = 900.0
@export var ranged_unlocked: bool = false

# Pickup parameters
@export var pickup_detection_radius: float = 150.0
@export var pickup_magnet_speed: float = 600.0

# Health Parameters
signal health_changed(new_health)
signal player_died()

# Blueprint tracking
var collected_blueprints: Array = []
var current_blueprint: Blueprint = null
var is_building: bool = false

# Signals
signal blueprint_collected(blueprint: Blueprint)
signal blueprint_building_started(blueprint: Blueprint)
signal blueprint_building_completed(blueprint: Blueprint, result_item: String)
signal blueprint_building_failed(blueprint: Blueprint)

@export_group("Health")
@export var max_health: int = 100
@export var knockback_force: float = 400.0  # Force of knockback
@export var knockback_duration: float = 0.25  # Duration of knockback in seconds
var current_health: int = max_health
var is_alive: bool = true
var knockback_direction: Vector2 = Vector2.ZERO
var is_being_knocked_back: bool = false
var knockback_timer: float = 0.0
var pieces_scene: Node
var original_collision_mask: int  # Store original collision mask
var post_knockback_invincibility_timer: float = 0.0  # New timer for post-knockback invincibility
var is_post_knockback_invincible: bool = false  # New state for post-knockback invincibility

# Juice parameters
@export_group("Visual Juice")
@export var enable_juice: bool = true
@export var squash_factor: float = 0.3
@export var stretch_factor: float = 0.3
@export var squash_stretch_speed: float = 10.0
@export var lean_max_angle: float = 15.0
@export var lean_speed_factor: float = 0.08
@export var trail_length: int = 10
@export var trail_lifetime: float = 0.3


# State variables
var is_jumping: bool = false
var is_wall_sliding: bool = false
var is_dashing: bool = false
var direction: int = 0
@export var facing_direction: int = 1
var current_wall_direction: int = 0
var has_exploded:bool 			= false
var is_disabled: bool = false  # New state to track when player is disabled

# Combat state
var attacking: bool = false
var melee_cooldown_timer: float = 0.0
var ranged_cooldown_timer: float = 0.0
var active_projectile_shape: String = "triangle"

# Pickups tracking
var circle_pieces: int = 10
var triangle_pieces: int = 10
var square_pieces: int = 10
@onready var pickup_tracker: HBoxContainer = $"/root/Game/UI/CanvasLayer/Control/BoxContainer/HBoxContainer"

# Timers for mechanics
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var wall_jump_timer: float = 0.0
var squash_stretch_timer: float = 0.0
var current_squash_stretch: float = 0.0

# References
@onready var sprite: Skeleton2D = $Skeleton2D
@onready var animation_player: AnimationPlayer = $PlayerAnimPlayer
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight
@onready var pickup_area: Area2D = $PickupArea
@onready var camera: Camera2D = $Camera2D
@onready var melee_hitbox: Area2D = $Skeleton2D/HipBone/BodyBone/HeadBone/upperArmBone/lowerArmBone/ArmHurtBoxWrapper
@onready var particles_run: GPUParticles2D = $ParticlesRun
@onready var particles_jump: GPUParticles2D = $ParticlesJump
@onready var particles_land: GPUParticles2D = $ParticlesLand
@onready var trail: Line2D = $Trail
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var game_manager: Node2D = $"/root/Game"
@onready var ui: CanvasLayer = $"../UI"
@onready var blueprint_controller: Blueprint = $"/root/Game/BlueprintPickup"

# Resources
@export var projectile_scene: PackedScene
@export var pickup_particles_scene: PackedScene
@export var jump_sound: AudioStream
@export var land_sound: AudioStream
@export var attack_melee_sound: AudioStream
@export var attack_ranged_sound: AudioStream
@export var pickup_sound: AudioStream

# Debug
@export var debug_mode: bool = false

# Trail positions tracker
var trail_points = []

# Vacuum parameters
@export var vacuum_radius: float = 150.0
@export var score: int = 0

signal on_pickup(type, amount)
signal on_attack(attack_type)
signal on_activate(shape_type)
signal on_empty(shape_type)
signal shape_count_changed(shape_type, amount)
# Insight parameters
@export var insight_radius: float = 300.0
@export var insight_duration: float = 3.0
@export var insight_color: Color = Color(0.5, 0.5, 0.5, 0.2)  # Semi-transparent gray
@export var insight_grow_time: float = 0.3  # Time to grow to full size
@export var insight_contract_time: float = 0.5  # Time to contract before disappearing
@export var insight_max_radius: float = 400.0  # Maximum radius during growth
var insight_timer: float = 0.0
var insight_area: Area2D = null
var insight_circle: Polygon2D = null
var insight_animation_phase: String = "grow"  # "grow", "hold", "contract"
var insight_animation_timer: float = 0.0
var is_insight_active: bool = false  # Track if insight is currently active

# wall paremters
@export var wall_duration: float = 3.0
@export var wall_color: Color = Color(0.5, 0.5, 0.5, 0.2)  # Semi-transparent gray
@export var wall_grow_time: float = 0.125  # Time to grow to full size
@export var wall_contract_time: float = 0.25  # Time to contract before disappearing
@export var wall_max_height: float = 220.0  # Maximum radius during growth
@export var wall_max_width: float = 22.0  # Maximum radius during growth

var wall_timer: float = 0.0
var wall_area: StaticBody2D = null
var wall_rect: Polygon2D = null
var wall_animation_phase: String = "grow"  # "grow", "hold", "contract"
var wall_animation_timer: float = 0.0
var is_wall_active: bool = false  # Track if insight is currently active


#checkpoint stuff
@onready var mcguffin: Node2D = $"/root/Game/mcguffin"
@onready var door: Node2D = $"/root/Game/mid/Door"


@export var traveling_shape_scene: PackedScene

# Shape tracking
var shape_counts: Dictionary = {
	"circle": 0,
	"triangle": 0,
	"square": 0
}

# Player states
enum PlayerState {
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
	ATTACKING,
	HURT,
	DEAD,
	DISABLED,
	BUILDING
}

var current_state: int = PlayerState.IDLE

# Add these variables near the top with other state variables
var is_grappling: bool = false
var grappling_point: Vector2 = Vector2.ZERO
var grappling_speed: float = 800.0
var grappling_line: Line2D = null

func _ready() -> void:
	# Initialize shape counts
	shape_counts["square"] = square_pieces
	shape_counts["triangle"] = triangle_pieces
	shape_counts["circle"] = circle_pieces
	
	# Emit signals for each shape type
	emit_signal("on_pickup", "circle", circle_pieces)
	emit_signal("on_pickup", "triangle", triangle_pieces)
	emit_signal("on_pickup", "square", square_pieces)

	var is_dialogue = Callable(self, "set_dialog_invinciblity") 
	ui.connect("dialog_visible", is_dialogue)
	
	var _decrement_shape_count = Callable(self, "decrement_shape_count") 
	blueprint_controller.connect("shape_spent_on_blueprint", _decrement_shape_count)


	# Add player to the player group
	add_to_group("player")
	
	# Initial setup
	if animation_player:
		animation_player.play("idle")
	
	# Setup pickup area
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_entered)
	
	# Initialize trail
	if trail:
		trail.clear_points()
		for i in range(trail_length):
			trail_points.append(position)
			trail.add_point(Vector2.ZERO)

	# Set collision layer and mask for player
	collision_layer = 2  # Player layer
	collision_mask = 1   # Collide with environment layer
	original_collision_mask = collision_mask  # Store original mask
	
	#initialize 
	pieces_scene = preload("res://Scenes/brokenPlayer.tscn").instantiate() 
	
	# Create a vacuum detection area
	var vacuum_area = Area2D.new()
	vacuum_area.name = "VacuumArea"
	
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = vacuum_radius
	collision.shape = circle
	
	vacuum_area.add_child(collision)
	add_child(vacuum_area)
	
	# Connect area signal
	vacuum_area.area_entered.connect(_on_vacuum_area_entered)

	# Initialize player health
	current_health = max_health
	
	# Hide all secret insight areas and disable their collision
	for item in get_tree().get_nodes_in_group("insight_item"):
		item.visible = false
		set_static_body_collision(item, false)

	# Initialize grappling line
	grappling_line = Line2D.new()
	grappling_line.width = 2.0
	grappling_line.default_color = Color(1, 1, 1, 0.8)
	add_child(grappling_line)
	grappling_line.visible = false

func _physics_process(delta: float) -> void:
	# Skip all physics if player is disabled
	if is_disabled and not is_grappling:
		return
	
	# Process input first
	handle_input()
	
	
	# Update timers
	update_timers(delta)
	
	# Handle grappling if active
	if is_grappling:
		_process_grappling(delta)
		move_and_slide()
		return
	
	# Apply movement logic based on state
	if is_dashing:
		apply_dash(delta)
	else:
		# Normal movement
		apply_gravity(delta)
		handle_movement(delta)
		handle_jumping()
		handle_wall_interactions(delta)
	
	# Combat handling
	handle_combat(delta)
	
	# Pickup magnet logic
	handle_pickups(delta)
	
	# Apply velocity and move
	move_and_slide()
	
	# Visual effects
	apply_juice(delta)
	
	# Update animation
	update_animation()
	
	# Handle knockback and post-knockback invincibility
	if is_being_knocked_back:
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_being_knocked_back = false
			knockback_direction = Vector2.ZERO
			# Start post-knockback invincibility
			is_post_knockback_invincible = true
			post_knockback_invincibility_timer = 0.75
			# Keep playing hurt animation during post-knockback invincibility
			if animation_player:
				animation_player.play("hurt")
				await animation_player.animation_finished
				animation_player.play("RESET")
		else:
			velocity = knockback_direction * knockback_force
			move_and_slide()
	elif is_post_knockback_invincible:
		post_knockback_invincibility_timer -= delta
		if post_knockback_invincibility_timer <= 0:
			is_post_knockback_invincible = false
			# Restore original collision mask
			collision_mask = original_collision_mask
			# Return to idle animation
			if animation_player:
				animation_player.play("idle")
	
	# Debug info
	if debug_mode:
		print_debug_info()

func update_timers(delta: float) -> void:
	# Update jump buffer timer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	# Update coyote timer
	if coyote_timer > 0:
		coyote_timer -= delta
	
	# Update dash timer
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	# Update dash cooldown timer
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Update wall jump timer
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
	
	# Update attack cooldown timers
	if melee_cooldown_timer > 0:
		melee_cooldown_timer -= delta
	
	if ranged_cooldown_timer > 0:
		ranged_cooldown_timer -= delta
	
	# Update squash/stretch timer
	if squash_stretch_timer > 0:
		squash_stretch_timer -= delta
		
	# Update insight timer and animation
	if insight_timer > 0:
		insight_timer -= delta
		update_insight_animation(delta)
		if insight_timer <= 0:
			end_insight()

	# Update insight timer and animation
	if wall_timer > 0:
		wall_timer -= delta
		update_wall_animation(delta)
		if wall_timer <= 0:
			end_insight()

func handle_input() -> void:
	# Skip input handling if player is disabled and not grappling
	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer <= 0 and ranged_unlocked and active_projectile_shape == "blueprint":
		print("is_grappling: " + str(is_grappling))
		if is_grappling:
			print("Detaching from grappling hook")
			end_grappling()
		else:
			perform_ranged_attack()
	
	if is_disabled:
		return
	
	# Get horizontal input
	direction = Input.get_axis("move_left", "move_right")
	
	# Update facing direction when moving
	if direction != 0:
		facing_direction = direction
		# Flip sprite based on direction
		sprite.scale.x = -direction
	
	# Jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Jump release (for variable jump height)
	if Input.is_action_just_released("jump") and velocity.y < 0 and is_jumping:
		velocity.y *= jump_cut_height
	
	# Combat inputs
	if Input.is_action_just_pressed("slash") and melee_cooldown_timer <= 0:
		perform_melee_attack()
	
	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer > 0 and ranged_unlocked:
		pickup_tracker.no_projectile(active_projectile_shape)

	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer <= 0 and ranged_unlocked and active_projectile_shape == "triangle":
		perform_ranged_attack()

	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer <= 0 and ranged_unlocked and active_projectile_shape == "circle":
		perform_insight()

	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer * 5 <= 0 and ranged_unlocked and active_projectile_shape == "square":
		perform_wall_build()

		
	if Input.is_action_just_pressed("activate_triangle"):
		update_activation("triangle")		
		
	if Input.is_action_just_pressed("activate_circle"):
		update_activation("circle")
				
	if Input.is_action_just_pressed("activate_square"):
		update_activation("square")

	if Input.is_action_just_pressed("activate_blueprint_item") and Global.has_blueprint_item:
		update_activation("blueprint")

func apply_gravity(delta: float) -> void:
	if is_wall_sliding:
		# Apply reduced gravity when wall sliding
		velocity.y = min(velocity.y + wall_slide_gravity * delta, wall_slide_speed)
	else:
		# Apply normal or increased gravity when falling
		var gravity_multiplier = fall_gravity_multiplier if velocity.y > 0 else 1.0
		velocity.y = min(velocity.y + gravity * gravity_multiplier * delta, max_fall_speed)

func handle_movement(delta: float) -> void:
	# Skip horizontal input handling during wall jump
	if wall_jump_timer > 0:
		return
	
	# Skip during attack animation if needed
	if attacking and animation_player.current_animation == "melee_attack":
		return
	
	# Calculate target velocity
	var target_velocity = direction * move_speed
	
	# Apply acceleration or friction
	if direction != 0:
		velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
		
		# Trigger run particles
		if is_on_floor() and enable_juice and particles_run:
			if not particles_run.emitting:
				particles_run.emitting = true
			# Update particle direction based on movement direction
			particles_run.process_material.direction = Vector3(-direction, 0, 0)
	else:
		# Apply different friction when in air vs on ground
		var current_friction = friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0, current_friction * delta)
		
		# Stop run particles
		if particles_run and particles_run.emitting:
			particles_run.emitting = false

func handle_jumping() -> void:
	# Detect landing
	if is_on_floor() and is_jumping:
		is_jumping = false
		coyote_timer = coyote_time
		
		# Landing juice
		if enable_juice:
			# Play landing particles
			if particles_land:
				particles_land.restart()
			
			# Squash effect
			apply_squash()
			
			# Play sound
			if audio_player and land_sound:
				audio_player.stream = land_sound
				audio_player.play()
	elif not is_on_floor() and coyote_timer <= 0:
		is_jumping = true
		
	elif is_on_floor() and !is_jumping:
		coyote_timer = 0.01
		
	#print("CT" + str(coyote_timer))
	#print("JBT" + str(jump_buffer_timer))
	# Standard jump from ground
	if (jump_buffer_timer > 0 and coyote_timer > 0) and not is_jumping:
		velocity.y = -jump_force
		is_jumping = true
		jump_buffer_timer = 0
		coyote_timer = 0
		
		
		# Jump juice
		if enable_juice:
			# Play jump particles
			if particles_jump:
				particles_jump.restart()
			
			# Stretch effect
			apply_stretch()
			
			# Play sound
			if audio_player and jump_sound:
				audio_player.stream = jump_sound
				audio_player.play()
	
	# Wall jump
	if is_wall_sliding and jump_buffer_timer > 0:
		velocity.x = wall_jump_force.x * -current_wall_direction
		velocity.y = -wall_jump_force.y
		is_jumping = true
		is_wall_sliding = false
		wall_jump_timer = wall_jump_time
		jump_buffer_timer = 0
		
		# Jump juice for wall jump too
		if enable_juice:
			if particles_jump:
				particles_jump.restart()
			apply_stretch()
			if audio_player and jump_sound:
				audio_player.stream = jump_sound
				audio_player.play()

func handle_wall_interactions(delta: float) -> void:
	# Reset wall sliding state
	is_wall_sliding = false
	
	# Check for wall collision
	if not is_on_floor() and velocity.y > 0:
	
		if wall_check_left.is_colliding():
			current_wall_direction = -1
			is_wall_sliding = true
		elif wall_check_right.is_colliding():
			current_wall_direction = 1
			is_wall_sliding = true

func start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown + dash_duration
	
	# Set dash velocity
	velocity.x = facing_direction * dash_speed
	velocity.y = 0

func apply_dash(delta: float) -> void:
	# Maintain dash velocity
	velocity.x = facing_direction * dash_speed
	velocity.y = 0

func perform_melee_attack() -> void:
	if attacking:
		return
	
	attacking = true
	melee_cooldown_timer = melee_cooldown
	
	# Play attack animation
	if animation_player:
		animation_player.play("melee_attack")
	
	# Enable hitbox for the duration of the attack
	if melee_hitbox:
		melee_hitbox.monitoring = true
		melee_hitbox.monitorable = true
		
		# Update hitbox position and scale based on facing direction
		melee_hitbox.scale.x = facing_direction
		# Keep the original position values but flip them based on facing direction
		var hitbox_collision = melee_hitbox.get_node("ArmHurtBox")
		hitbox_collision.disabled = false
		# var base_position = Vector2(40.4641, -27.0979)  # Original position from scene
		#hitbox_collision.position = base_position * Vector2(facing_direction, 1)
		
		# Wait for animation to finish then disable hitbox
		await animation_player.animation_finished
		
		melee_hitbox.monitoring = false
		melee_hitbox.monitorable = false
		hitbox_collision.disabled = true
	
	# Play sound
	if audio_player and attack_melee_sound:
		audio_player.stream = attack_melee_sound
		audio_player.play()
	
	attacking = false
	emit_signal("on_attack", "melee")

func has_ammo() -> bool:
	match active_projectile_shape:
		"circle":
			if (circle_pieces == 0):
				emit_signal("on_empty", active_projectile_shape)
				return false
			circle_pieces -= 1
			shape_counts["circle"] = circle_pieces
			emit_signal("on_pickup", active_projectile_shape, circle_pieces)
		"square":
			if (square_pieces == 0):
				emit_signal("on_empty", active_projectile_shape)
				return false
			square_pieces -= 1
			shape_counts["square"] = square_pieces
			emit_signal("on_pickup", active_projectile_shape, square_pieces)
		"triangle":
			if (triangle_pieces == 0):
				emit_signal("on_empty", active_projectile_shape)
				return false
			triangle_pieces -= 1
			shape_counts["triangle"] = triangle_pieces
			emit_signal("on_pickup", active_projectile_shape, triangle_pieces)
	
	return true

func perform_insight() -> void:
	if attacking or not ranged_unlocked or not has_ammo():
		return
		
	attacking = true
	ranged_cooldown_timer = ranged_cooldown
	
	# Play attack animation
	if animation_player:
		animation_player.play("ranged_attack")
	
	# Create insight area if it doesn't exist
	if not insight_area:
		insight_area = Area2D.new()
		insight_area.name = "InsightArea"
		
		var collision = CollisionShape2D.new()
		collision.name = "insightCollisionShape"
		var circle = CircleShape2D.new()
		circle.radius = insight_radius
		collision.shape = circle
		
		# Create visual circle
		insight_circle = Polygon2D.new()
		insight_circle.color = insight_color
		insight_circle.show_behind_parent = true
		
		insight_area.add_child(insight_circle)
		insight_area.add_child(collision)
		add_child(insight_area)
		
		# Connect area signals
		insight_area.area_entered.connect(_on_insight_area_entered)
		insight_area.area_exited.connect(_on_insight_area_exited)
	
	# Start insight effect
	insight_timer = insight_duration
	insight_animation_timer = 0.0
	insight_animation_phase = "grow"
	insight_area.monitoring = true
	insight_circle.visible = true
	is_insight_active = true
	
	# Play sound
	if audio_player and attack_ranged_sound:
		audio_player.stream = attack_ranged_sound
		audio_player.play()
	
	await animation_player.animation_finished
	attacking = false
	emit_signal("on_attack", "insight")


func perform_wall_build() -> void:
	if not ranged_unlocked or attacking:
		return
	# Check ammo before proceeding
	if not has_ammo():
		return
	# Play attack animation


	if animation_player:
		animation_player.play("ranged_attack")
	
	# Spawn projectile
	var projectile = projectile_scene.instantiate()
	projectile.set_meta("shape_type", "square")
	projectile.find_child("projectile_square").visible = true
	projectile.set_meta("is_wall_projectile", true)  # Mark this as a wall projectile
	
	# Set collision layers and masks
	projectile.collision_layer = 4  # Projectile layer
	projectile.collision_mask = 1   # Collide with environment layer
	
	# Set up collision for the square shape
	var square_collision = projectile.find_child("RBCollShape2D")
	if square_collision:
		square_collision.disabled = false
	
	projectile.global_position = global_position + Vector2(facing_direction * 50, 40)
	
	# Initialize velocity with proper direction and speed
	projectile.velocity = Vector2(facing_direction * ranged_projectile_speed * 0.5, -ranged_projectile_speed * 0.5)  # Upward angle
	projectile.direction = Vector2(facing_direction, -0.5)  # Slight upward angle
	
	get_parent().add_child(projectile)

		# Start attack state
	attacking = true
	ranged_cooldown_timer = ranged_cooldown
	
	# Emit attack signal
	emit_signal("on_attack", "ranged")
	
	
	# Play sound
	if audio_player and attack_ranged_sound:
		audio_player.stream = attack_ranged_sound
		audio_player.play()
	
	await animation_player.animation_finished
	attacking = false
	emit_signal("on_attack", "wall")


func _on_wall_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Allow player to jump on top of the wall
		if body.global_position.y < wall_area.global_position.y:
			body.velocity.y = 0  # Stop player's downward velocity
	elif body.is_in_group("enemy"):
		# Stop enemies from passing through
		if body.has_method("take_damage"):
			body.take_damage(1)  # Optional: damage enemies that hit the wall
		# Push enemy away from wall
		var push_direction = sign(body.global_position.x - wall_area.global_position.x)
		body.velocity.x = push_direction * 200  # Adjust push force as needed

func _on_wall_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		print("Wall area entered by enemy")
		# Handle enemy area collision
		var enemy = area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(1)  # Optional: damage enemies that hit the wall

func transform_projectile_to_wall(projectile: Node2D) -> void:
	# Remove any existing wall before creating a new one
	if wall_area:
		wall_area.queue_free()
		wall_area = null
		wall_rect = null
		is_wall_active = false
	
	# Create wall body
	wall_area = StaticBody2D.new()
	wall_area.name = "WallArea"
	
	# Set collision layers and masks
	wall_area.collision_layer = 1  # Environment layer
	wall_area.collision_mask = 6   # Collide with player (2) and enemies (4)
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	collision.name = "WallCollisionShape"
	var rect = RectangleShape2D.new()
	
	# Set initial size
	rect.size = Vector2(wall_max_width * 2, wall_max_height * 2)
	collision.shape = rect
	
	# Create visual rectangle
	wall_rect = Polygon2D.new()
	wall_rect.color = wall_color
	wall_rect.show_behind_parent = true
	
	# Initialize with empty polygon
	wall_rect.polygon = PackedVector2Array()
	
	wall_area.add_child(wall_rect)
	wall_area.add_child(collision)
	get_parent().add_child(wall_area)
	
	# Position the wall at the projectile's position
	var wall_area_offset = projectile.global_position.y - wall_max_height / 3
	wall_area.global_position = Vector2(projectile.global_position.x, wall_area_offset)
	
	# Start wall effect
	wall_timer = wall_duration
	wall_animation_timer = 0.0
	wall_animation_phase = "grow"
	wall_rect.visible = true
	is_wall_active = true
	
	# Remove the projectile
	projectile.queue_free()

func end_insight() -> void:
	if insight_area:
		insight_area.monitoring = false
		if insight_circle:
			insight_circle.visible = false
		is_insight_active = false
		# Hide all insight items that aren't permanent
		for item in get_tree().get_nodes_in_group("insight_item"):
			if not item.has_meta("is_permanent") or not item.get_meta("is_permanent"):
				# For non-permanent items, hide the item and disable collision
				item.visible = false
				set_static_body_collision(item, false)
			else:
				# For permanent items, ensure the Polygon2D is visible and Line2D is hidden
				var line2d = item.get_node("Line2D")
				var polygon2d = item.get_node("Polygon2D")
				if line2d and polygon2d:
					line2d.visible = false
					polygon2d.visible = true
				# Keep the item visible and ensure collision is enabled
				item.visible = true
				set_static_body_collision(item, true)

func _on_insight_area_entered(area: Area2D) -> void:
	# Check if the area is part of an insight item
	if area.is_in_group("insight_item"):
		area.visible = true
		# Only enable collision if the item is permanent
		if area.has_meta("is_permanent") and area.get_meta("is_permanent"):
			set_static_body_collision(area, true)

func _on_insight_area_exited(area: Area2D) -> void:
	# Check if the area is part of an insight item
	if area.is_in_group("insight_item"):
		# Only hide and disable collision if the item is not permanent
		if not area.has_meta("is_permanent") or not area.get_meta("is_permanent"):
			area.visible = false
			set_static_body_collision(area, false)

func update_activation(shape: String) -> void:
	emit_signal("on_activate", shape)
	switch_projectile(shape)
	
	# Handle grappling hook point visibility
	if shape == "blueprint" and Global.has_blueprint_item:
		# Find the grappling hook point in the scene
		var grappling_hook_point = get_tree().get_first_node_in_group("grappling_hook_point")
		print("grappling hook point: ", grappling_hook_point.name)
		if grappling_hook_point:
			grappling_hook_point.visible = true
			# Play the attach point visible animation
			var animation_player = grappling_hook_point.get_node("AnimationPlayer")
			if animation_player and animation_player.has_animation("attach_point_visible"):
				animation_player.play("attach_point_visible")
	else:
		# Hide the grappling hook point when switching to other shapes
		var grappling_hook_point = get_tree().get_first_node_in_group("grappling_hook_point")
		if grappling_hook_point:
			grappling_hook_point.visible = false

func switch_projectile(shape: String) -> void:
	active_projectile_shape = shape
	

func handle_combat(delta: float) -> void:
	# This function can be expanded to handle more complex combat logic
	pass

func handle_pickups(delta: float) -> void:
	# Get all pickups in the area
		
	var pickups = get_tree().get_nodes_in_group("pickup_group")
	
	for pickup in pickups:
		# Calculate distance to pickup
		var distance = global_position.distance_to(pickup.global_position)
		
		# Check if pickup is within attraction range
		if distance < pickup_detection_radius:
			# Calculate direction to player
			var direction_to_player = (global_position - pickup.global_position).normalized()
			# direction_to_player.y = direction_to_player.y + 2
			# Move pickup towards player with increasing speed as it gets closer
			var attraction_factor = 1.0 - (distance / pickup_detection_radius)
			var pickup_parent: RigidBody2D = pickup.get_parent()
			pickup_parent.set_deferred("freeze", true)
			pickup_parent.get_node("RBCollShape2D").set_deferred("disabled",true)
			
			# pickup.global_position += direction_to_player * pickup_magnet_speed * attraction_factor * delta
			
			pickup_parent.global_position += direction_to_player * pickup_magnet_speed * attraction_factor * delta
			
			# Check if pickup is close enough to collect
			if distance < 1.2:
				collect_pickup(pickup)
		else:
			var pickup_parent: RigidBody2D = pickup.get_parent()
			pickup_parent.set_deferred("freeze", false)
			pickup_parent.get_node("RBCollShape2D").set_deferred("disabled",false)
		

func collect_pickup(pickup) -> void:
	# Identify pickup type
	var pickup_parent: RigidBody2D = pickup.get_parent()
	
	var pickup_type = pickup_parent.get_child(0).name.replace("Shape","")
	
	# Add to player inventory
	match pickup_type:
		"circle":
			circle_pieces += 1
			emit_signal("on_pickup", pickup_type, circle_pieces)
		"triangle":
			triangle_pieces += 1
			emit_signal("on_pickup", pickup_type, triangle_pieces)
		"square":
			square_pieces += 1
			emit_signal("on_pickup", pickup_type, square_pieces)
		"blueprint":
			var blueprint_name = pickup_parent.get_meta("blueprint_name", "unknown")
			if not collected_blueprints.has(blueprint_name):
				collected_blueprints.append(blueprint_name)
				emit_signal("blueprint_collected", blueprint_name)
	
	# Play collection effect
	if pickup_particles_scene:
		var particles = pickup_particles_scene.instantiate()
		pickup_parent.add_child(particles)
		particles.global_position = pickup.global_position
		particles.emitting = true
	
	# Play sound
	if audio_player and pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.play()
	
	# Remove pickup
	pickup_parent.queue_free()
	
	# Check if ranged attack should be unlocked
	check_ranged_unlock()

func check_ranged_unlock() -> void:
	# Example condition: unlock ranged attack when player has at least 5 of each piece
	if circle_pieces >= 5 and triangle_pieces >= 5 and square_pieces >= 5 and not ranged_unlocked:
		ranged_unlocked = true
		# Play unlock effect/animation if desired

func apply_juice(delta: float) -> void:
	if not enable_juice:
		return
	
	# Apply squash and stretch
	if current_squash_stretch != 0:
		var factor = move_toward(abs(current_squash_stretch), 0, squash_stretch_speed * delta)
		if current_squash_stretch > 0:
			current_squash_stretch = factor
		else:
			current_squash_stretch = -factor
			
		if sprite:
			if current_squash_stretch > 0:
				# Squash
				sprite.scale.x = 1 + current_squash_stretch
				sprite.scale.y = 1 - current_squash_stretch
			else:
				# Stretch
				sprite.scale.x = 1 + current_squash_stretch
				sprite.scale.y = 1 - current_squash_stretch
	
	# Apply lean based on velocity
	if sprite and abs(velocity.x) > 10:
		var target_rotation = -lean_max_angle * velocity.x / move_speed * lean_speed_factor
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, target_rotation, 0.2)
	else:
		sprite.rotation_degrees = lerp(sprite.rotation_degrees, 0.0, 0.2)
	
	# Update trail
	if trail and trail_length > 0:
		# Shift all positions
		for i in range(trail_length - 1, 0, -1):
			trail_points[i] = trail_points[i-1]
		
		# Add current position
		trail_points[0] = global_position
		
		# Update trail points
		for i in range(trail_length):
			var alpha = 1.0 - float(i) / trail_length
			trail.set_point_position(i, to_local(trail_points[i]))
			
			# Set point color with fading alpha
			var color = Color(1, 1, 1, alpha * 0.5)
			#trail.set_point_color(i, color)
			trail.default_color = color

func apply_squash() -> void:
	current_squash_stretch = squash_factor
	squash_stretch_timer = 0.3

func apply_stretch() -> void:
	current_squash_stretch = -stretch_factor
	squash_stretch_timer = 0.3

func update_animation() -> void:
	if animation_player:
		# Don't interrupt attack animations or hurt animation during knockback/invincibility
		if animation_player.current_animation == "melee_attack" or animation_player.current_animation == "ranged_attack" or is_being_knocked_back or is_post_knockback_invincible:
			if not animation_player.is_playing():
				animation_player.play("idle")
			return
			
		var anim_name: String = "idle"
		
		if is_dashing:
			anim_name = "dash"
		elif is_wall_sliding:
			anim_name = "wall_slide"
		elif not is_on_floor():
			anim_name = "jump" if velocity.y < 0 else "fall"
		elif abs(velocity.x) > 10:
			if direction > 0:
				anim_name = "run_right"
			elif direction < 0:
				anim_name = "run_left"
			
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func _on_pickup_area_entered(body: Node2D) -> void:
	# print("pickup area entered - player")

	if body.is_in_group("pickup_group"):
		collect_pickup(body)

func _on_vacuum_area_entered(area):
	if area is Pickup and !area._vacuum_active:
		area.start_vacuum(self)
		
func add_score(value):
	score += value
	# print("Score: ", score)
	# Update your UI here

# Function to handle taking damage with knockback
func take_damage(damage: int, knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if not is_alive or is_being_knocked_back or is_post_knockback_invincible:
		return
		
	current_health -= damage
	emit_signal("health_changed", current_health)
	
	if current_health <= 0:
		die()
	else:
		# Apply knockback if direction is provided
		if knockback_direction != Vector2.ZERO:
			apply_knockback(knockback_direction)

# Apply knockback based on source position
func apply_knockback(direction: Vector2) -> void:
	if is_being_knocked_back or is_post_knockback_invincible:  # Don't apply new knockback during knockback or post-knockback invincibility
		return
	

	is_being_knocked_back = true
	knockback_direction = direction
	knockback_timer = knockback_duration
	
	# Store original collision mask if not already stored
	if original_collision_mask == 0:
		original_collision_mask = collision_mask
	
	# Only disable collision with enemies and projectiles during knockback
	# Keep collision with environment (layer 1)
	collision_mask = 1  # Only collide with environment
	
	# Play hurt animation if available
	if animation_player:
		animation_player.play("hurt")
		await animation_player.animation_finished
		animation_player.play("RESET")

# Function to heal the player
func heal(amount: int) -> void:
	if not is_alive:
		return
		
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health)

# Death function
func die() -> void:
	is_alive = false
	emit_signal("player_died")
		
	# Stop knockback
	is_being_knocked_back = false
	
	# Disable collision
	collision_shape_2d.set_deferred("disabled", true)
	
	# Stop player movement
	velocity = Vector2.ZERO
	
	# Play death animation if you have one
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		# Or just implement basic death behavior
		modulate.a = 0.5  # Make the player semi-transparent
	
	if has_exploded:
		return  # Stop if already exploded

	# Spawn pieces immediately
	pieces_scene.global_position = global_position
	get_parent().call_deferred("add_child", pieces_scene)
	has_exploded = true  # Mark explosion as happened

	# Create a shorter timer for scene reload
	var timer = get_tree().create_timer(0.5)  # Reduced from 2.0 to 0.5 seconds
	timer.timeout.connect(_on_death_timer_timeout)

	queue_free()  # Remove the character

# Called when death timer expires
func _on_death_timer_timeout() -> void:
	# Handle what happens after death (game over, respawn, etc.)
	# For example:
	get_tree().reload_current_scene()  # Restart the current level
	# or
	# queue_free()  # Remove the player
	# or
	# respawn()  # Call a custom respawn function
	pass

# Optional: Add a respawn function
func respawn() -> void:
	current_health = max_health
	is_alive = true
	
	# Re-enable collision
	collision_shape_2d.set_deferred("disabled", false)
	
	# Reset appearance
	modulate.a = 1.0
	
	
	# Play respawn animation if you have one
	if animation_player and animation_player.has_animation("respawn"):
		animation_player.play("respawn")
	
	emit_signal("health_changed", current_health)
	
	# You might want to set the player's position to a spawn point here
	# position = spawn_point_position


func print_debug_info() -> void:
	print("Velocity: ", velocity)
	print("On Floor: ", is_on_floor())
	print("Is Jumping: ", is_jumping)
	print("Is Wall Sliding: ", is_wall_sliding)
	print("Is Dashing: ", is_dashing)
	print("Is Attacking: ", attacking)
	print("Melee Cooldown: ", melee_cooldown_timer)
	print("Ranged Cooldown: ", ranged_cooldown_timer)
	print("Pieces - Circle: ", circle_pieces, " Triangle: ", triangle_pieces, " Square: ", square_pieces)

func update_wall_animation(delta: float) -> void:
	if not wall_rect or not wall_rect.visible:
		return
		
	wall_animation_timer += delta
	
	match wall_animation_phase:
		"grow":
			# Rapidly grow to max size
			var progress = wall_animation_timer / wall_grow_time
			if progress >= 1.0:
				progress = 1.0
				wall_animation_phase = "hold"
				wall_animation_timer = 0.0
			
			var current_height = lerp(0.0, wall_max_height, progress)
			var current_width = lerp(0.0, wall_max_width, progress)
			var current_size = Vector2(current_width, current_height)
			
			update_rect_size(current_size)
			
		"hold":
			# Hold at full size until near the end
			if wall_timer <= wall_contract_time:
				wall_animation_phase = "contract"
				wall_animation_timer = 0.0
			
		"contract":
			# Contract before disappearing
			var progress = wall_animation_timer / wall_contract_time
			if progress >= 1.0:
				progress = 1.0
			
			var current_height = lerp(wall_max_height, 0.0, progress)
			var current_width = lerp(wall_max_width, 0.0, progress)
			var current_size = Vector2(current_width, current_height)
			update_rect_size(current_size)
			if (current_width <= wall_max_width / 10):
				wall_animation_phase = "remove"
		"remove":
			print("Removing wall")
			wall_area.queue_free()

func update_insight_animation(delta: float) -> void:
	if not insight_circle or not insight_circle.visible:
		return
		
	insight_animation_timer += delta
	
	match insight_animation_phase:
		"grow":
			# Rapidly grow to max radius
			var progress = insight_animation_timer / insight_grow_time
			if progress >= 1.0:
				progress = 1.0
				insight_animation_phase = "hold"
				insight_animation_timer = 0.0
			
			var current_radius = lerp(0.0, insight_max_radius, progress)
			update_circle_radius(current_radius)
			
		"hold":
			# Hold at full radius until near the end
			if insight_timer <= insight_contract_time:
				insight_animation_phase = "contract"
				insight_animation_timer = 0.0
			
		"contract":
			# Contract before disappearing
			var progress = insight_animation_timer / insight_contract_time
			if progress >= 1.0:
				progress = 1.0
			
			var current_radius = lerp(insight_max_radius, 0.0, progress)
			update_circle_radius(current_radius)

func update_circle_radius(radius: float) -> void:
	if not insight_circle:
		return
		
	var points = []
	var segments = 32
	for i in range(segments):
		var angle = (i * 2.0 * PI) / segments
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	insight_circle.polygon = PackedVector2Array(points)
	
	# Update collision shape radius
	if insight_area:
		var collision = insight_area.get_node("insightCollisionShape")
		if collision and collision.shape is CircleShape2D:
			collision.shape.radius = radius


func update_rect_size(size: Vector2) -> void:
	if not wall_rect:
		return
		
	# Create a rectangle with the given size
	var points = [
		Vector2(-size.x/2, -size.y/2),  # Top-left
		Vector2(size.x/2, -size.y/2),   # Top-right
		Vector2(size.x/2, size.y/2),    # Bottom-right
		Vector2(-size.x/2, size.y/2)    # Bottom-left
	]
	
	wall_rect.polygon = PackedVector2Array(points)
	
	# Update collision shape size
	if wall_area:
		var collision = wall_area.get_node("WallCollisionShape")
		if collision and collision.shape is RectangleShape2D:
			collision.shape.size.x = size.x + 10
			collision.shape.size.y = size.y + 10

func zoom_on_checkpoint(checkpoint:Node2D) -> void:
			# Store original camera position and zoom
		var original_camera_pos = camera.global_position
		var original_camera_zoom = camera.zoom
		
		# Zoom to mcguffin
		var tween = create_tween()
		tween.tween_property(camera, "global_position", mcguffin.global_position, 0.5)
		tween.parallel().tween_property(camera, "zoom", Vector2(4.2, 4.2), 0.5)
		
		print("Started camera tween")
		
		# Wait for zoom
		await get_tree().create_timer(0.5).timeout
		
		# Handle mcguffin meow sequence
		await mcguffin.play_meow_sequence()
		
		# Zoom back out
		tween = create_tween()
		tween.tween_property(camera, "global_position", original_camera_pos, 0.5)
		tween.parallel().tween_property(camera, "zoom", original_camera_zoom, 0.5)
		# Wait for zoom
		await get_tree().create_timer(1.25).timeout

func handle_checkpoint(checkpoint: Node2D) -> void:
	# Disable player movement and actions
	is_disabled = true
	print("Player disabled")

	# Cancel insight circle if active
	if is_insight_active:
		end_insight()

	if mcguffin and door and mcguffin.visible:
		# Store original camera position and zoom
		var original_camera_pos = camera.global_position
		var original_camera_zoom = camera.zoom
		
		# Zoom to mcguffin
		var tween = create_tween()
		tween.tween_property(camera, "global_position", mcguffin.global_position, 0.5)
		tween.parallel().tween_property(camera, "zoom", Vector2(4.2, 4.2), 0.5)
		
		print("Started camera tween")
		
		# Wait for zoom
		await get_tree().create_timer(0.5).timeout
		
		# Handle mcguffin meow sequence
		await mcguffin.play_meow_sequence()
		
		# Zoom back out
		tween = create_tween()
		tween.tween_property(camera, "global_position", original_camera_pos, 0.5)
		tween.parallel().tween_property(camera, "zoom", original_camera_zoom, 0.5)
		# Wait for zoom
		await get_tree().create_timer(1.25).timeout
		# Move mcguffin to door
		await mcguffin.move_to_door(door)
	else:
		# If no mcguffin or it's not visible, just re-enable player movement
		print("No mcguffin found or not visible")
	
	# Re-enable player movement and actions
	is_disabled = false

func collect_blueprint(blueprint: Blueprint) -> void:
	if not collected_blueprints.has(blueprint):
		collected_blueprints.append(blueprint)
		emit_signal("blueprint_collected", blueprint)

func start_blueprint_building(blueprint: Blueprint) -> void:
	if is_building or current_blueprint != null:
		return
		
	# Check if player has a square to spend
	if shape_counts["square"] <= 0:
		emit_signal("blueprint_building_failed", blueprint)
		return
		
	# Spend a square
	shape_counts["square"] -= 1
	emit_signal("shape_count_changed", "square", shape_counts["square"])
	
	# Start building
	current_blueprint = blueprint
	is_building = true
	emit_signal("blueprint_building_started", blueprint)
	
	# Enter building state
	change_state(PlayerState.BUILDING)
	
func decrement_shape_count(shape_type: String):
	# Spend the shape
	shape_counts[shape_type] -= 1
	
	emit_signal("on_pickup", shape_type, shape_counts[shape_type])
	emit_signal("shape_count_changed", shape_type, shape_counts[shape_type])

func place_shape_on_blueprint(shape_type: String) -> void:
	if not is_building or current_blueprint == null:
		return
		
	# Check if shape is required and available
	var required_shapes = current_blueprint.get_required_shapes()
	if required_shapes[shape_type] <= 0 or shape_counts[shape_type] <= 0:
		return
		
	# Spend the shape
	shape_counts[shape_type] -= 1
	emit_signal("shape_count_changed", shape_type, shape_counts[shape_type])
	
	# Update required shapes
	required_shapes[shape_type] -= 1
	
	# Check if blueprint is complete
	var is_complete = true
	for count in required_shapes.values():
		if count > 0:
			is_complete = false
			break
			
	if is_complete:
		# Complete the blueprint
		var result_item = current_blueprint.get_result_item()
		# Add result item to inventory
		# TODO: Implement inventory system
		
		emit_signal("blueprint_building_completed", current_blueprint, result_item)
		current_blueprint = null
		is_building = false
		change_state(PlayerState.IDLE)

func _process_state(delta: float) -> void:
	match current_state:
		PlayerState.IDLE:
			_process_idle_state(delta)
		PlayerState.WALKING:
			_process_walking_state(delta)
		PlayerState.JUMPING:
			_process_jumping_state(delta)
		PlayerState.FALLING:
			_process_falling_state(delta)
		PlayerState.ATTACKING:
			_process_attacking_state(delta)
		PlayerState.HURT:
			_process_hurt_state(delta)
		PlayerState.DEAD:
			_process_dead_state(delta)
		PlayerState.DISABLED:
			_process_disabled_state(delta)
		PlayerState.BUILDING:
			_process_building_state(delta)

func _process_building_state(delta: float) -> void:
	# Stop player movement during building
	velocity = Vector2.ZERO
	
	# Disable shape spawning
	if Input.is_action_just_pressed("projectile"):
		return  # Prevent square spawning
	
	# Handle other inputs
	_process_movement(delta)
	_process_jump(delta)
	_process_attack(delta)

func _process_idle_state(delta: float) -> void:
	# Handle idle state
	pass

func _process_walking_state(delta: float) -> void:
	# Handle walking state
	pass

func _process_jumping_state(delta: float) -> void:
	# Handle jumping state
	pass

func _process_falling_state(delta: float) -> void:
	# Handle falling state
	pass

func _process_attacking_state(delta: float) -> void:
	# Handle attacking state
	pass

func _process_hurt_state(delta: float) -> void:
	# Handle hurt state
	pass

func _process_dead_state(delta: float) -> void:
	# Handle dead state
	pass

func _process_disabled_state(delta: float) -> void:
	# Handle disabled state
	pass

func _process_movement(delta: float) -> void:
	# Handle movement state
	pass

func _process_jump(delta: float) -> void:
	# Handle jump state
	pass

func _process_attack(delta: float) -> void:
	# Handle attack state
	pass

func change_state(new_state: PlayerState) -> void:
	# Don't allow state changes while in HURT state
	if current_state == PlayerState.HURT:
		return
		
	# Exit current state
	match current_state:
		PlayerState.IDLE:
			pass
		PlayerState.WALKING:
			pass
		PlayerState.JUMPING:
			pass
		PlayerState.FALLING:
			pass
		PlayerState.ATTACKING:
			pass
		PlayerState.HURT:
			pass
		PlayerState.DEAD:
			pass
		PlayerState.DISABLED:
			pass
		PlayerState.BUILDING:
			# Clean up building state
			current_blueprint = null
			is_building = false
			
	# Enter new state
	current_state = new_state
	match new_state:
		PlayerState.IDLE:
			pass
		PlayerState.WALKING:
			pass
		PlayerState.JUMPING:
			pass
		PlayerState.FALLING:
			pass
		PlayerState.ATTACKING:
			pass
		PlayerState.HURT:
			pass
		PlayerState.DEAD:
			pass
		PlayerState.DISABLED:
			pass
		PlayerState.BUILDING:
			# Initialize building state
			velocity = Vector2.ZERO

func perform_ranged_attack() -> void:
	print("perform_ranged_attack called")
	if not ranged_unlocked:
		print("Ranged attack not unlocked")
		return
	if attacking:
		print("Already attacking")
		return
	# Check ammo before proceeding
	if not has_ammo():
		print("No ammo available")
		return

	# Handle blueprint grappling hook
	print("Checking blueprint conditions - active shape: ", active_projectile_shape, " has blueprint: ", Global.has_blueprint_item)
	if active_projectile_shape == "blueprint" and Global.has_blueprint_item:
		print("Blueprint shape active and has blueprint item")
		var grappling_hook_point = get_tree().get_first_node_in_group("grappling_hook_point")
		print("Found grappling hook point: ", grappling_hook_point)
		if grappling_hook_point and grappling_hook_point.visible:
			print("Starting grappling sequence")
			# Start grappling
			is_grappling = true
			grappling_point = grappling_hook_point.global_position
			grappling_line.visible = true
			
			# Disable gravity and normal movement while grappling
			velocity = Vector2.ZERO
			is_disabled = true
			
			# Play grappling sound if available
			if audio_player and attack_ranged_sound:
				audio_player.stream = attack_ranged_sound
				audio_player.play()
			
			return
		else:
			print("Grappling hook point not found or not visible")
	else:
		print("Blueprint conditions not met - active shape: ", active_projectile_shape, " has blueprint: ", Global.has_blueprint_item)

	# Start attack state
	attacking = true
	ranged_cooldown_timer = ranged_cooldown
	
	# Emit attack signal
	emit_signal("on_attack", "ranged")
	
	# Play attack sound
	if audio_player and attack_ranged_sound:
		audio_player.stream = attack_ranged_sound
		audio_player.play()
	
	# Check for insight items in range
	var found_match = false
	print("Checking for insight items with shape: ", active_projectile_shape)
	
	# Only check for insight items if the insight circle is active
	if is_insight_active:
		for item in get_tree().get_nodes_in_group("insight_item"):
			print("Found insight item: ", item.name)
			# Check both the item and its parent for visibility
			var parent = item.get_parent()
			if item.visible or (parent and parent.visible):
				var item_shape = item.get_meta("shape_type", "")
				print("Item shape type: ", item_shape)
				print("Looking for: ", active_projectile_shape)
				if item_shape == active_projectile_shape and not item.get_meta("is_permanent"):
					print("Found matching shape!")
					# Make the item permanent
					item.set_meta("is_permanent", true)
					
					# Get the Line2D and Polygon2D nodes
					var line_node = item.get_node_or_null("Line2D")
					var poly_node = item.get_node_or_null("Polygon2D")
					
					if line_node:
						line_node.visible = false
					if poly_node:
						poly_node.visible = true
					
					# Enable collision on the StaticBody2D
					set_static_body_collision(item, true)
					
					# Ensure both the item and its parent are visible
					item.visible = true
					if parent:
						parent.visible = true
					
					# Spawn traveling shape from UI to insight item
					if traveling_shape_scene:
						var traveling_shape = traveling_shape_scene.instantiate()
						get_tree().root.add_child(traveling_shape)
						
						# Get the UI position for the current shape
						var ui_shape = get_tree().get_first_node_in_group("shape_" + active_projectile_shape)
						if ui_shape:
							traveling_shape.init(ui_shape.global_position, item.global_position, active_projectile_shape)
					
					found_match = true
					break
				else:
					print("Shape mismatch - expected: " + active_projectile_shape + ", got: " + item_shape)
			else:
				print("Item and parent not visible")
	
	if found_match:
		# Reset attack state and emit signal
		attacking = false
		emit_signal("on_attack", "ranged")
	else:
		# Spawn projectile if no match found
		var projectile = projectile_scene.instantiate()
		projectile.set_meta("shape_type", active_projectile_shape)
		
		# Make the correct shape visible
		var shape_node = projectile.find_child("projectile_" + active_projectile_shape)
		if shape_node:
			shape_node.visible = true
		
		# Spawn in front of the player based on facing direction, with enough distance to avoid collision
		projectile.global_position = global_position + Vector2(facing_direction * 50, 40)
		projectile.direction = Vector2(facing_direction, 0)
		projectile.speed = ranged_projectile_speed
		get_parent().add_child(projectile)
		# Reset attack state after projectile is fired
		attacking = false

# Add this new function to handle grappling physics
func _process_grappling(delta: float) -> void:
	if not is_grappling:
		return
		
		
	# Calculate direction to grappling point
	var direction = (grappling_point - global_position).normalized()
	
	# Move player towards grappling point
	velocity = direction * grappling_speed
	
	# Update line position
	grappling_line.clear_points()
	grappling_line.add_point(Vector2.ZERO)
	grappling_line.add_point(to_local(grappling_point))
	
	# Check if we've reached the point
	var distance = global_position.distance_to(grappling_point)
	if distance < 10.0:
		print("Reached grappling point, ending grapple")
		end_grappling()

# Add this function to end grappling
func end_grappling() -> void:
	print("end_grappling called")
	is_grappling = false
	grappling_line.visible = false
	
	# Find the summit point
	var summit_point = get_tree().get_first_node_in_group("summit_point")
	if summit_point:
		print("Found summit point, transporting player")
		# Teleport player to summit point
		global_position = summit_point.global_position
		# Reset velocity and enable movement
		velocity = Vector2.ZERO
		is_disabled = false
	else:
		print("No summit point found")
		# Just reset state if no summit point
		velocity = Vector2.ZERO
		is_disabled = false
	
	print("Grapple state reset")

# Add this new helper function
func set_static_body_collision(item: Node2D, enabled: bool) -> void:
	var static_body = item.find_child("StaticBody2D")
	if static_body and static_body is StaticBody2D:
		static_body.collision_layer = 1 if enabled else 0
		static_body.collision_mask = 1 if enabled else 0

func set_dialog_invinciblity(is_dialogue_visible:bool) -> void:
	print("dialogue visible: " + str(is_dialogue_visible))
	if is_dialogue_visible:
		is_post_knockback_invincible = true
	else:
		# post_knockback_invincibility_timer = 0.75
		post_knockback_invincibility_timer = 2.0
	print("is_post_knockback_invincible: " + str(is_post_knockback_invincible))
