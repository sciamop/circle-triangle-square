extends Area2D

var speed: float = 600.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 1

func _ready():
	# Connect signal for when projectile hits something
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Get the shape type from metadata
	var shape_type = get_meta("shape_type", "triangle")
	var active_projectile_shape = find_child("projectile_" + shape_type)
	if active_projectile_shape:
		active_projectile_shape.visible = true

func _physics_process(delta):
	# Move the projectile
	position += direction.normalized() * speed * delta
	
	# Optional: Rotate the projectile to face its movement direction
	rotation = direction.angle()

func _on_body_entered(body):
	# Check what was hit
	if body.has_method("take_damage"):
		body.take_damage(damage,direction)
	
	# Destroy the projectile
	queue_free()

# Optional method to free the projectile when it goes off-screen
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
