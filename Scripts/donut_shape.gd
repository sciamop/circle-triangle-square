@tool
extends Area2D

@export var inner_radius: float = 50.0:
	set(value):
		if value != inner_radius:
			inner_radius = value
			generate_donut()

@export var outer_radius: float = 100.0:
	set(value):
		if value != outer_radius:
			outer_radius = value
			generate_donut()

@export var segments: int = 32:
	set(value):
		if value != segments:
			segments = value
			generate_donut()

@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D

@onready var polygon_2d: Polygon2D = $Polygon2D

func _ready() -> void:
	generate_donut()

func generate_donut() -> void:
	# if not Engine.is_editor_hint():
	# 	return  # Prevent unnecessary updates during gameplay

	var points = []
	
	# Generate outer circle points
	for i in range(segments):
		var angle = (i * 2 * PI) / segments
		var x = outer_radius * cos(angle)
		var y = outer_radius * sin(angle)
		points.append(Vector2(x, y))
	
	# Generate inner circle points (in reverse order)
	for i in range(segments - 1, -1, -1):
		var angle = (i * 2 * PI) / segments
		var x = inner_radius * cos(angle)
		var y = inner_radius * sin(angle)
		points.append(Vector2(x, y))
	
	# Set the polygon points for both Polygon2D and CollisionPolygon2D
	var packed_points = PackedVector2Array(points)
	polygon_2d.polygon = packed_points
	if collision_polygon:
		collision_polygon.polygon = packed_points
