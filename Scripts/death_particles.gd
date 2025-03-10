extends Area2D

class_name DeathParticles

@onready var player: CharacterBody2D = $"/root/Game/Player"
@onready var camera_2d: Camera2D = $"/root/Game/Player/Camera2D"

func _ready():
  # Remove the whole broken character node
	for part in get_children():
		if part is RigidBody2D:
			var random_force = Vector2(randf_range(-30, 30), randf_range(-30, -30))
			part.apply_impulse(Vector2.ZERO, random_force)
