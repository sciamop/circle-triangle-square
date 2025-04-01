extends Node2D

var start_pos: Vector2
var end_pos: Vector2
var travel_time: float = 0.5
var elapsed_time: float = 0.0
var curve: Curve = Curve.new()

func _ready():
	# Create a smooth curve for the animation

	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(0.5, -0.5))
	curve.add_point(Vector2(1, 0))
	
	

func init(start: Vector2, end: Vector2, shape_type: String):
	# Set fixed starting position at 50% screen width and 20px from bottom
	var viewport_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Convert viewport coordinates to global coordinates
		start_pos = camera.get_screen_center_position() + Vector2(0, viewport_size.y/2 - 20)
	else:
		# Fallback if no camera
		start_pos = Vector2(viewport_size.x * 0.5, viewport_size.y - 20)
	
	end_pos = end
	global_position = start_pos
	print("Start pos: ", start_pos)
	
	# Set the shape based on type
	var shape_node = $Shape
	match shape_type:
		"circle":
			# Create a circle using multiple points
			var points = PackedVector2Array()
			var segments = 32
			for i in range(segments):
				var angle = (i * 2.0 * PI) / segments
				points.append(Vector2(cos(angle) * 20, sin(angle) * 20))
			shape_node.polygon = points
		"triangle":
			# Create a triangle
			shape_node.polygon = PackedVector2Array([
				Vector2(0, -20),  # Top point
				Vector2(20, 20),  # Bottom right
				Vector2(-20, 20)  # Bottom left
			])
		"square":
			# Create a square
			shape_node.polygon = PackedVector2Array([
				Vector2(-20, -20),  # Top left
				Vector2(20, -20),   # Top right
				Vector2(20, 20),    # Bottom right
				Vector2(-20, 20)    # Bottom left
			])

func _process(delta):
	elapsed_time += delta
	var progress = min(elapsed_time / travel_time, 1.0)
	
	# Use the curve to create an arc motion
	var curve_progress = curve.sample(progress)
	var current_pos = start_pos.lerp(end_pos, progress)
	current_pos.y += curve_progress * 100  # Adjust the arc height as needed
	
	global_position = current_pos
	
	if progress >= 1.0:
		queue_free() 
