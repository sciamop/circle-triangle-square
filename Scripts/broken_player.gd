extends CharacterBody2D

@onready var player: CharacterBody2D = $"/root/Game/Player"
@onready var camera_2d: Camera2D = $"/root/Game/Player/Camera2D"

func _ready():
	player.remove_child(camera_2d)
	add_child(camera_2d)
  # Remove the whole broken character node
	for part in get_children():
		if part is RigidBody2D:
			var random_force = Vector2(randf_range(30, 255) * player.direction, randf_range(-130, -330))
			part.apply_central_impulse(random_force)
	
