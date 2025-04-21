extends Control

@onready var shape_container = $HBoxContainer
@onready var divider = $Line2D
@onready var animation_player = $AnimationPlayer
var special_shape_scene = preload("res://Scenes/special_shape.tscn")

func _ready() -> void:
	Global.shape_collected.connect(_on_shape_collected)
	update_display()

func _on_shape_collected(shape_type: String) -> void:
	print("collected shape: " + shape_type)
	if Global.collected_shapes.size() > 3:
		animation_player.play("all_shapes_collected")
	update_display()

func update_display() -> void:
	# Clear existing shapes (except blueprint)
	if Global.collected_shapes.size() > 0:
		divider.visible = true
	else:
		divider.visible = false
	for child in shape_container.get_children():
		child.queue_free()
	
	call_deferred("add_children_to_container")
	
func add_children_to_container() -> void:
		# Add collected shapes
	var c:int = 1
	for shape_type in Global.collected_shapes:
		var shape_instance = special_shape_scene.instantiate()
		
		shape_instance.active_shape = shape_type
		shape_instance.scale = Vector2(0.5, 0.5)  # Make it smaller for UI
		var special_shape: Area2D = shape_instance.find_child(shape_type)
		if (special_shape):
			if Global.collected_shapes.size() < 4:
				special_shape.find_child("Polygon2D").color = Color(0.0, 0.0, 0.0, 0.75)  # Make it gray
			else:
				special_shape.find_child("Polygon2D").color = Color(1.0, 0.0, 1.0, 1.0)  # Make it gray
			
		shape_instance.global_position.x = -48 * c
		shape_container.add_child(shape_instance)
		c += 1 
