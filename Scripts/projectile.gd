extends Area2D

@export var speed: float = 900.0
@export var max_bounces: int = 2
@export var bounce_distance: float = 100.0  # How far it bounces
@export var gravity_force: float = 1500.0  # Renamed from gravity

var direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var bounces: int = 0
var is_wall_projectile: bool = false
@onready var player: Player = $"/root/Game/Player"



func _ready() -> void:
	# Check if this is a wall projectile
	is_wall_projectile = get_meta("is_wall_projectile", false)
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# For non-wall projectiles, set initial velocity based on direction and speed
	if not is_wall_projectile:
		velocity = direction.normalized() * speed

func _physics_process(delta: float) -> void:
	# Only apply gravity and bouncing for wall projectiles
	if is_wall_projectile:
		# Apply gravity
		velocity.y += gravity_force * delta
		
		# Move the projectile
		position += velocity * delta
		
		# Check if it's time to transform into a wall
		if is_on_floor() and bounces >= max_bounces:
			transform_into_wall()
	else:
		# Regular projectile behavior - move in straight line
		position += velocity * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") or area.get_parent().is_in_group("enemy") and self.get_meta("shape_type") == "triangle":
		# Handle enemy hit
		area.get_parent().take_damage(10, self.direction)
		queue_free()
	elif area.is_in_group("environment"):
		if is_wall_projectile:
			# Bounce off environment
			if bounces < max_bounces:
				bounce()
			else:
				transform_into_wall()
		else:
			# Regular projectile - just destroy on impact
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("Body entered: ", body)
	if body.is_in_group("environment"):
		if is_wall_projectile:
			# Bounce off environment
			if bounces < max_bounces:
				bounce()
			else:
				transform_into_wall()
		else:
			# Regular projectile - just destroy on impact
			queue_free()

func bounce() -> void:
	bounces += 1
	velocity.y = -bounce_distance  # Bounce upward
	velocity.x *= 0.8  # Reduce horizontal velocity with each bounce

func transform_into_wall() -> void:
	# Get the player node
	if is_wall_projectile:
		if player and player.has_method("transform_projectile_to_wall"):
			player.transform_projectile_to_wall(self)
		else:
			queue_free()

func is_on_floor() -> bool:
	# Check if we're moving downward and have bounced enough times
	return velocity.y > 0 and bounces >= max_bounces
