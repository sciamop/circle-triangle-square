extends CharacterBody2D

class_name Enemy

# Basic parameters
@export var max_health: int = 50
@export var move_speed: float = 150.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 800.0

# AI parameters
@export var detection_radius: float = 300.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.2
@export var patrol_wait_time: Vector2 = Vector2(1.0, 3.0)
@export var aggro_duration: float = 5.0
@export var chase_acceleration: float = 800.0
@export var patrol_acceleration: float = 400.0

# Combat parameters
@export var contact_damage: int = 10
@export var melee_damage: int = 15
@export var knockback_force: float = 300.0

# Pickup drops
@export var drops_enabled: bool = true
@export_group("Pickup Drops")
@export var circle_drop_chance: float = 0.7
@export var triangle_drop_chance: float = 0.5
@export var square_drop_chance: float = 0.3
@export var min_drops: int = 1
@export var max_drops: int = 3

# Juice parameters
@export_group("Visual Effects")
@export var enable_effects: bool = true
@export var hit_flash_duration: float = 0.1
@export var death_particles_count: int = 20
@export var squash_on_land: float = 0.2
@export var jump_stretch: float = 0.3

# Respawn parameters
@export_group("Respawn settings")
@export var respawn_time: float = 2.0  # Time in seconds before respawn
@export var should_respawn: bool = true  # Toggle if this enemy should respawn
@export_node_path("Node2D") var spawn_point_path  # Optional custom spawn point
@export var random_spawn_radius: float = 100.0  # Random spawn radius (0 for exact spawn)

var current_health: int = max_health
var is_alive: bool = true
var initial_position: Vector2
var spawn_point: Node2D = null
@onready var respawn_timer: Timer = $RespawnTimer

# References to nodes
#@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite: Polygon2D = $Polygon2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var ground_check: RayCast2D = $GroundCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var attack_timer: Timer = $AttackTimer
@onready var patrol_timer: Timer = $PatrolTimer
@onready var aggro_timer: Timer = $AggroTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer
@onready var attack_area: Area2D = $AttackArea

# Resources
@export var circle_pickup: PackedScene
@export var triangle_pickup: PackedScene
@export var square_pickup: PackedScene
@export var death_particles: PackedScene
@export var hit_sound: AudioStream
@export var attack_sound: AudioStream
@export var death_sound: AudioStream

# State machine variables
enum EnemyState {IDLE, PATROL, CHASE, ATTACK, HURT, DEAD, RESPAWN}
var current_state: int = EnemyState.IDLE

# State tracking variables
var health: int = max_health
var direction: int = 1  # 1 = right, -1 = left
var patrol_destination: Vector2 = Vector2.ZERO
var target: Node2D = null
var attack_ready: bool = true
var is_aggro: bool = false
var was_on_floor: bool = false
var is_hurting: bool = false
var original_modulate: Color = Color.BLACK

# Signals
signal enemy_died()
signal enemy_respawned()
signal on_enemy_died
signal on_enemy_hit(damage)
signal on_enemy_attack

func _ready() -> void:
	#death_particles = preload("res://Scenes/death_particles.tscn").instantiate()
	
	# Initialize health
	current_health = max_health
	
	# Store original color for flash effects
	if sprite:
		original_modulate = sprite.modulate
	
	# Initialize timers
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	if patrol_timer:
		patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	
	if aggro_timer:
		aggro_timer.timeout.connect(_on_aggro_timer_timeout)
	
	if hit_flash_timer:
		hit_flash_timer.timeout.connect(_on_hit_flash_timer_timeout)
	
	# Setup collision
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Start in patrol state
	change_state(EnemyState.PATROL)
	_start_patrol()
	
	# Set up the ground check
	was_on_floor = is_on_floor()

	# Store the initial position for respawning
	initial_position = global_position
	
	# Get reference to spawn point if provided
	if spawn_point_path:
		spawn_point = get_node(spawn_point_path)
	
	# Setup respawn timer


	

func _physics_process(delta: float) -> void:
	# Skip if dead
	if current_state == EnemyState.DEAD:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	
	# Handle landing effects
	if is_on_floor() and not was_on_floor and enable_effects:
		_apply_squash()
	was_on_floor = is_on_floor()
	
	# State machine
	match current_state:
		EnemyState.IDLE:
			_process_idle_state(delta)
		
		EnemyState.PATROL:
			_process_patrol_state(delta)
		
		EnemyState.CHASE:
			_process_chase_state(delta)
		
		EnemyState.ATTACK:
			_process_attack_state(delta)
		
		EnemyState.HURT:
			_process_hurt_state(delta)
	
	# Handle ledge detection
	if is_on_floor() and current_state != EnemyState.HURT:
		_check_ledges()
	
	# Handle wall detection
	_check_walls()
	
	# Look for player if not already chasing
	if current_state != EnemyState.CHASE and current_state != EnemyState.ATTACK and current_state != EnemyState.HURT:
		_check_for_player()
	
	# Update animation
	_update_animation()
	
	# Move the character
	move_and_slide()

func change_state(new_state: int) -> void:
	if current_state == new_state:
		return
	
	# Exit current state
	match current_state:
		EnemyState.ATTACK:
			if attack_area:
				attack_area.monitoring = false
	
	# Enter new state
	current_state = new_state
	
	match new_state:
		EnemyState.IDLE:
			velocity.x = 0
			if patrol_timer and not patrol_timer.is_stopped():
				patrol_timer.start(randf_range(patrol_wait_time.x, patrol_wait_time.y))
		
		EnemyState.PATROL:
			_choose_patrol_destination()
		
		EnemyState.CHASE:
			if aggro_timer:
				aggro_timer.start(aggro_duration)
		
		EnemyState.ATTACK:
			velocity.x = 0
			if attack_area:
				attack_area.monitoring = true
			if audio_player and attack_sound:
				audio_player.stream = attack_sound
				audio_player.play()
			emit_signal("on_enemy_attack")
		
		EnemyState.HURT:
			is_hurting = true
			if animation_player:
				animation_player.play("hurt")
				await animation_player.animation_finished
				is_hurting = false
				
				# Return to chase if was chasing before, otherwise patrol
				if is_aggro and target:
					change_state(EnemyState.CHASE)
				else:
					change_state(EnemyState.PATROL)
		
		EnemyState.DEAD:
			# Disable collisions
			if hitbox:
				hitbox.set_deferred("monitoring", false)
				hitbox.set_deferred("monitorable", false)
			if hurtbox:
				hurtbox.set_deferred("monitoring", false)
				hurtbox.set_deferred("monitorable", false)
			
			$CollisionShape2D.set_deferred("disabled", true)
			
			# Stop movement
			velocity = Vector2.ZERO
			
			# Play death animation if you have one
			if animation_player and animation_player.has_animation("death"):
				animation_player.play("death")
				await animation_player.animation_finished
			else:
				# Or just basic death visuals
				modulate.a = 0.5  # Make semi-transparent
				
			# Spawn death effects
			_spawn_death_effects()
			
			# Spawn pickups
			if drops_enabled:
				_spawn_pickups()
			
			# Emit death signal
			emit_signal("on_enemy_died")
			
			is_alive = false
			emit_signal("enemy_died")
			# Disable collision
			$CollisionShape2D.set_deferred("disabled", true)
			
		
			# Disable any AI or state machine
			#set_process(false)
			#set_physics_process(false)

			# Handle respawn
			if should_respawn:
				respawn_timer.start(respawn_time)
				
				
			else:
				# If enemy doesn't respawn, free it after animation
				await get_tree().create_timer(0.5).timeout
				queue_free()
		
		EnemyState.RESPAWN:
			

			# Reset health
			current_health = max_health
			is_alive = true
			#$Polygon2D.color = Color(1,1,1,1)
			
			# Respawn at appropriate position
			if spawn_point != null:
				global_position = spawn_point.global_position
			else:
				global_position = initial_position
				
			# Add random offset if specified
			if random_spawn_radius > 0:
				var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				global_position += random_direction * randf_range(0, random_spawn_radius)
			
			# Re-enable AI processing
			set_process(true)
			
			emit_signal("enemy_respawned")
			modulate.a = 1.0
			visible = true
			$CollisionShape2D.set_deferred("disabled", false)
			#If we have a respawn animation lets play it
			if animation_player and animation_player.has_animation("respawn"):
				animation_player.play("respawn")
				await animation_player.animation_finished
				
				# Reset visual state
				
				
				$Polygon2D.color = Color(0,0,0,1)
				
				# Enable collisions
				if hitbox:
					hitbox.set_deferred("monitoring", true)
					hitbox.set_deferred("monitorable", true)
				if hurtbox:
					hurtbox.set_deferred("monitoring", true)
					hurtbox.set_deferred("monitorable", true)
			
				set_physics_process(true)
				
				
				
				change_state(EnemyState.IDLE)

func _process_idle_state(delta: float) -> void:
	# Slow down to a stop
	velocity.x = move_toward(velocity.x, 0, patrol_acceleration * delta)

func _process_patrol_state(delta: float) -> void:
	if patrol_destination == Vector2.ZERO:
		_choose_patrol_destination()
		return
	
	# Move toward patrol destination
	var target_velocity = direction * move_speed * 0.6
	velocity.x = move_toward(velocity.x, target_velocity, patrol_acceleration * delta)
	
	# Check if we've reached the destination
	var distance_to_destination = abs(global_position.x - patrol_destination.x)
	if distance_to_destination < 10:
		change_state(EnemyState.IDLE)

func _process_chase_state(delta: float) -> void:
	if not is_instance_valid(target):
		is_aggro = false
		change_state(EnemyState.PATROL)
		return
	
	# Update direction based on target position
	var target_direction = sign(target.global_position.x - global_position.x)
	if target_direction != 0:
		direction = target_direction
	
	# Check if within attack range
	var distance_to_target = abs(global_position.x - target.global_position.x)
	if distance_to_target <= attack_range and attack_ready:
		change_state(EnemyState.ATTACK)
		return
	
	# Move toward target
	var target_velocity = direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity, chase_acceleration * delta)

func _process_attack_state(delta: float) -> void:
	# Attack logic is handled by animation events
	# This state transitions back to CHASE once the animation is done
	if animation_player and not animation_player.is_playing():
		# Reset attack cooldown
		attack_ready = false
		if attack_timer:
			attack_timer.start(attack_cooldown)
		
		# Return to chase if target still exists
		if is_instance_valid(target) and is_aggro:
			change_state(EnemyState.CHASE)
		else:
			change_state(EnemyState.PATROL)

func _process_hurt_state(delta: float) -> void:
	# Hurt state transitions are handled by animation events
	# Knockback is applied when damage is taken
	velocity.x = move_toward(velocity.x, 0, 500 * delta)

func _check_ledges() -> void:
	if not ledge_check:
		return
	
	if not ledge_check.is_colliding() and is_on_floor():
		# About to walk off ledge, turn around
		direction *= -1
		_update_raycasts()
		
		if current_state == EnemyState.PATROL:
			_choose_patrol_destination()

func _check_walls() -> void:
	if not wall_check:
		return
	
	if wall_check.is_colliding():
		# Hit a wall, turn around
		direction *= -1
		_update_raycasts()
		
		if current_state == EnemyState.PATROL:
			_choose_patrol_destination()

func _update_raycasts() -> void:
	# Update raycast directions based on movement direction
	if wall_check:
		wall_check.target_position.x = abs(wall_check.target_position.x) * direction
	
	if ledge_check:
		ledge_check.position.x = abs(ledge_check.position.x) * direction

func _check_for_player() -> void:
	# Find the player in the scene if exists
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var distance = global_position.distance_to(player.global_position)
		
		# Check if player is within detection radius
		if distance <= detection_radius:
			target = player
			is_aggro = true
			change_state(EnemyState.CHASE)

func _apply_squash() -> void:
	if not sprite or not enable_effects:
		return
		
	# Apply squash effect
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1 + squash_on_land, 1 - squash_on_land), 0.1)
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.2)

func _apply_hit_flash() -> void:
	if not sprite or not enable_effects:
		return
	
	sprite.modulate = Color(1, 0.3, 0.3, 1)
	if hit_flash_timer:
		hit_flash_timer.start(hit_flash_duration)

func take_damage(damage: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if current_state == EnemyState.DEAD:
		return
	
	# Apply damage
	current_health -= damage
	emit_signal("on_enemy_hit", damage)
	
	# Apply hit effects
	if enable_effects:
		_apply_hit_flash()
	
	# Play hit sound
	if audio_player and hit_sound:
		audio_player.stream = hit_sound
		audio_player.play()
	
	# Check for death
	if current_health <= 0:
		change_state(EnemyState.DEAD)

		return
	
	# Apply knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * knockback_force
	else:
		# Default knockback direction
		velocity.x = -direction * knockback_force * 0.7
		velocity.y = -knockback_force * 0.5
	
	# Enter hurt state
	change_state(EnemyState.HURT)
	
func _spawn_pickups() -> void:
	# Determine number of drops
	var drop_count = randi_range(min_drops, max_drops)
	
	for i in range(drop_count):
		var pickup_scene = null
		var rand = randf()
		
		# Choose pickup type based on probabilities
		if rand < circle_drop_chance:
			pickup_scene = circle_pickup
		elif rand < circle_drop_chance + triangle_drop_chance:
			pickup_scene = triangle_pickup
		else:
			pickup_scene = square_pickup
		
		if pickup_scene:
			var pickup = pickup_scene.instantiate()
			get_parent().add_child(pickup)
			
			# Position with random offset
			pickup.global_position = global_position + Vector2(
				randf_range(-20, 20),
				randf_range(-10, 0)
			)
			
			# Add initial velocity for "explosion" effect
			if pickup.has_method("apply_impulse"):
				var impulse = Vector2(
					randf_range(-100, 100),
					randf_range(-150, -50)
				)
				pickup.apply_impulse(impulse)

func _spawn_death_effects() -> void:
	if not enable_effects or not death_particles:
		return
	
	# Spawn death particles
	var particles = death_particles.instantiate()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	
	# Play death sound
	if audio_player and death_sound:
		audio_player.stream = death_sound
		audio_player.play()

func _choose_patrol_destination() -> void:
	# Choose a random patrol point within range
	var patrol_range = 100
	patrol_destination = global_position + Vector2(patrol_range * direction, 0)

func _start_patrol() -> void:
	# Choose initial direction
	direction = 1 if randf() > 0.5 else -1
	_update_raycasts()
	_choose_patrol_destination()
	
	# Start patrol timer
	if patrol_timer:
		patrol_timer.start(randf_range(patrol_wait_time.x, patrol_wait_time.y))

func _update_animation() -> void:
	if not animation_player or not sprite:
		return
	
	# Update sprite direction
	sprite.scale.x = direction
	
	# Don't interrupt hurt, attack or death animations
	if animation_player.current_animation == "respawn" or animation_player.current_animation == "hurt" or animation_player.current_animation == "attack" or animation_player.current_animation == "death":
		return
	
	# Choose animation based on state
	var anim_name = "idle"
	
	match current_state:
		EnemyState.IDLE:
			anim_name = "idle"
		
		EnemyState.PATROL:
			anim_name = "walk"
		
		EnemyState.CHASE:
			anim_name = "run"
		
		EnemyState.ATTACK:
			anim_name = "attack"
			
		EnemyState.RESPAWN:
			anim_name = "respawn"
	
	# Play falling animation if in air
	if not is_on_floor() and velocity.y > 0:
		anim_name = "fall"
	
	# Update animation if changed
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	
	# Check if hit by player attack
	if area.is_in_group("player_attack"):
		var damage = melee_damage
		var knockback_dir = Vector2.ZERO
		
		# Get damage value from attack if available
		if area.get_parent().has_method("get_damage"):
			damage = area.get_parent().get_damage()
		
		# Calculate knockback direction
		if area.get_parent().has_method("get_facing_direction"):
			var player_dir = area.get_parent().get_facing_direction()
			knockback_dir = Vector2(player_dir, -0.5).normalized()
		
		# Apply damage
		take_damage(damage, knockback_dir)

func _on_hitbox_body_entered(body: Node2D) -> void:
	# Check if hit player
	print(body.name)
	if body.is_in_group("player"):
		print("contact with player")
		# Deal contact damage to player
		if body.has_method("take_damage"):
			var knockback_dir = (body.global_position - global_position).normalized()
			body.take_damage(contact_damage, knockback_dir)

func _on_attack_timer_timeout() -> void:
	attack_ready = true

func _on_patrol_timer_timeout() -> void:
	if current_state == EnemyState.IDLE:
		change_state(EnemyState.PATROL)

func _on_aggro_timer_timeout() -> void:
	is_aggro = false
	change_state(EnemyState.PATROL)

func _on_hit_flash_timer_timeout() -> void:
	if sprite:
		sprite.modulate = original_modulate


# Respawn the enemy
func respawn() -> void:
	change_state(EnemyState.RESPAWN)
	

# Called when respawn timer expires
func _on_respawn_timer_timeout() -> void:
	print("now is the time to respawn")
	respawn()
