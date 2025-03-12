extends CharacterBody2D

class_name Player

# Movement parameters
@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1000.0
@export var air_friction: float = 200.0

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
@export var ranged_projectile_speed: float = 600.0
@export var ranged_unlocked: bool = false

# Pickup parameters
@export var pickup_detection_radius: float = 150.0
@export var pickup_magnet_speed: float = 200.0

# Health Parameters
signal health_changed(new_health)
signal player_died()

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
var facing_direction: int = 1
var current_wall_direction: int = 0
var has_exploded:bool 			= false

# Combat state
var attacking: bool = false
var melee_cooldown_timer: float = 0.0
var ranged_cooldown_timer: float = 0.0

# Pickups tracking
var circle_pieces: int = 0
var triangle_pieces: int = 0
var square_pieces: int = 0

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
#@onready var melee_hitbox: Area2D = $MeleeHitbox
#@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var melee_hitbox: Area2D = $Skeleton2D/HipBone/BodyBone/HeadBone/upperArmBone/lowerArmBone/MeleeHitbox2
#@onready var _melee_hitbox: RigidBody2D = $ArmHurtBoxWrapper
@onready var particles_run: GPUParticles2D = $ParticlesRun
@onready var particles_jump: GPUParticles2D = $ParticlesJump
@onready var particles_land: GPUParticles2D = $ParticlesLand
@onready var trail: Line2D = $Trail
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

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

#func _on_pickup():
	#print("pickedup")
	#

func _ready() -> void:
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

func _physics_process(delta: float) -> void:
	# Update timers
	update_timers(delta)
	
	# Process input
	handle_input()
	
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
	
	if is_being_knocked_back:
		# Apply knockback force
		velocity = knockback_direction * knockback_force
		
		# Update knockback timer
		knockback_timer -= delta
		if knockback_timer <= 0:
			is_being_knocked_back = false
			
		move_and_slide()
	
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

func handle_input() -> void:
	# Get horizontal input
	direction = Input.get_axis("move_left", "move_right")
	#sprite.scale.x = direction
	# Update facing direction when moving
	if direction != 0:
		facing_direction = direction
		# Flip sprite based on direction
		#sprite.flip_h = facing_direction < 0
		sprite.scale.x = -direction
	
	# Jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	
	# Jump release (for variable jump height)
	if Input.is_action_just_released("jump") and velocity.y < 0 and is_jumping:
		velocity.y *= jump_cut_height
	
	# Dash input
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()
	
	# Combat inputs
	if Input.is_action_just_pressed("slash") and melee_cooldown_timer <= 0:
		perform_melee_attack()
	
	if Input.is_action_just_pressed("attack_ranged") and ranged_cooldown_timer <= 0 and ranged_unlocked:
		perform_ranged_attack()

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
		
		# Wait for animation to finish then disable hitbox
		await animation_player.animation_finished
		melee_hitbox.monitoring = false
	
	# Play sound
	if audio_player and attack_melee_sound:
		audio_player.stream = attack_melee_sound
		audio_player.play()
	
	attacking = false
	emit_signal("on_attack", "melee")

func perform_ranged_attack() -> void:
	if attacking or not ranged_unlocked:
		return
	
	attacking = true
	ranged_cooldown_timer = ranged_cooldown
	
	# Play attack animation
	if animation_player:
		animation_player.play("ranged_attack")
	
	# Spawn projectile
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position + Vector2(20 * facing_direction, -10)
		projectile.direction = facing_direction
		projectile.speed = ranged_projectile_speed
		projectile.damage = ranged_damage
	
	# Play sound
	if audio_player and attack_ranged_sound:
		audio_player.stream = attack_ranged_sound
		audio_player.play()
	
	await animation_player.animation_finished
	attacking = false
	emit_signal("on_attack", "ranged")

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
		

func collect_pickup(pickup) -> void:
	# Identify pickup type
	var pickup_parent: RigidBody2D = pickup.get_parent()
	
	var pickup_type = pickup_parent.get_child(0).name.replace("Shape","")
	# print(pickup.name)
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
			#on_pickup.emit(pickup_type, square_pieces)# Emit signal
			emit_signal("on_pickup", pickup_type, square_pieces)
	
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
	# pickup.queue_free()
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
		# Don't interrupt attack animations
		if animation_player.current_animation == "melee_attack" or animation_player.current_animation == "ranged_attack":
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
			
		
		#if animation_player.current_animation != anim_name and not animation_player.is_playing():
		
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)

func _on_pickup_area_entered(body: Node2D) -> void:
	print("pickup area entered - player")
	if body.is_in_group("pickup_group"):
		collect_pickup(body)

func _on_vacuum_area_entered(area):
	if area is Pickup and !area._vacuum_active:
		area.start_vacuum(self)
		
func add_score(value):
	score += value
	print("Score: ", score)
	# Update your UI here

# Function to handle taking damage with knockback
func take_damage(amount: int, source_position: Vector2 = Vector2.ZERO) -> void:
	if not is_alive:
		return
		
	current_health = max(0, current_health - amount)
	emit_signal("health_changed", current_health)
	
	# Apply knockback if source position is provided
	if source_position != Vector2.ZERO:
		apply_knockback(source_position)
	
	if current_health <= 0:
		die()
# Apply knockback based on source position
func apply_knockback(source_position: Vector2) -> void:
	# Calculate direction away from source
	knockback_direction = (global_position - source_position).normalized()
	
	# Start knockback
	is_being_knocked_back = true
	knockback_timer = knockback_duration

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
	
	# Optional: add a timer to handle respawn or game over
	var timer = get_tree().create_timer(2.0)
	
	if has_exploded:
		return  # Stop if already exploded

	
	pieces_scene.global_position = global_position
	get_parent().call_deferred("add_child",pieces_scene)
	
	has_exploded = true  # Mark explosion as happened  # Add pieces to the scene

	queue_free()  # Remove the character
	
	timer.timeout.connect(_on_death_timer_timeout)

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
