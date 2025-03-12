extends RigidBody2D
class_name Pickup

# Pickup properties
@export var value: int = 1
@export var vacuum_distance: float = 150.0
@export var max_speed: float = 400.0
@export var acceleration: float = 1000.0

# Visual properties
@export var sprite: Texture2D
@export var collection_effect: PackedScene

# Current state
var _player: Node2D = null
var _vacuum_active: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _collected: bool = false
# @onready var area_2d: Area2D = $Area2D
@onready var pickup_area_2d:Area2D = $pickupArea2D

# Setup sprite on ready
func _ready():

	#var sprite_node = Sprite2D.new()
	#sprite_node.texture = sprite
	#add_child(sprite_node)
	##
	### Set up collision shape (adjust based on your needs)
	#var collision = CollisionShape2D.new()
	#var shape = CircleShape2D.new()
	#shape.radius = 10
	#collision.shape = shape
	#add_child(collision)

	# Connect signals
	body_entered.connect(_on_body_entered)

func _process(delta):
	return
	if _collected:
		return
		
	# Check for player in vacuum range
	if _player != null and !_vacuum_active:
		var distance = global_position.distance_to(_player.global_position)
		if distance <= vacuum_distance:
			_vacuum_active = true
	
	# Apply vacuum effect
	if _vacuum_active and _player != null:
		var direction = (_player.global_position - global_position).normalized()
		_velocity += direction * acceleration * delta
		_velocity = _velocity.limit_length(max_speed)
		global_position += _velocity * delta


# func _physics_process(delta: float) -> void:
# 	var velocity:Vector2 = Vector2.ZERO
# 	var collision = move_and_collide(velocity * delta)
	
# 	if collision:
# 		#print(collision.get_collider().name)
# 		if collision.get_collider().is_in_group("player") and !_collected:
# 			# explode()
# 			collect(collision.get_collider())

# Called when a body enters the pickup's collision area
func _on_body_entered(body):

	if body.is_in_group("player") and !_collected:
		collect(body)

# Can be called when player enters vacuum range
func start_vacuum(player: Node2D):
	_player = player
	_vacuum_active = true

# Called when player actually collects the pickup
func collect(player: Node2D):
	return
	_collected = true
	
	# Spawn collection effect if provided
	if collection_effect:
		var effect = collection_effect.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)
	
	# Emit signal for the player to handle (add to score, etc.)
	emit_signal("collected", value)
	
	# Remove the pickup
	queue_free()

# Optional signal for when pickup is collected
signal collected(value)
