@tool
extends Polygon2D

@export var radius: float = 50.0: 
	set(value):
		radius = value
		update_circle()

@export var segments: int = 32: 
	set(value):
		segments = max(3, value)  # Minimum 3 to avoid errors
		update_circle()

func _ready():
	update_circle()

func update_circle():
	if not Engine.is_editor_hint():
		return  # Prevent unnecessary updates during gameplay
	
	var points = []
	for i in range(segments):
		var angle = (i * 2.0 * PI) / segments
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	polygon = PackedVector2Array(points)
