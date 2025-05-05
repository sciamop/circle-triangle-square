@tool
extends Area2D

@export var active_shape: String = "rhombus"
@export var is_keyhole: bool = false

var shapes: Dictionary

func _ready() -> void:
	shapes = {
		"rhombus": $rhombus,
		"pentagon": $pentagon,
		"octagon": $octagon,
		"diamond": $diamond
	}

	update_visibility()
	body_entered.connect(_on_body_entered)

func update_visibility() -> void:
	if is_keyhole:
		for _shapes in get_children():
			if _shapes.has_meta("special_shape_type"):
				print(_shapes)
				var polygon2d: Polygon2D = _shapes.find_child("Polygon2D")
				polygon2d.hide()
				var line2d: Line2D = _shapes.find_child("Line2D")
				line2d.show()
			
	if not shapes:
		return
		
	for shape_name in shapes:
		var shape = shapes[shape_name]
		if shape:
			shape.visible = (shape_name == active_shape)

	#for _collected_shape in Global.collected_shapes:
#
		#if shapes[_collected_shape]:
			#shapes[_collected_shape].queue_free()
	
			# queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var shape = shapes[active_shape]
		
		# open shape gate!
		if is_keyhole:
			print("is keyhole")
			for _collected_shape in Global.collected_shapes:
				print(_collected_shape)
				print(active_shape)
				if (_collected_shape == active_shape):
					print(_collected_shape + " is the active shape")
					var shape_gates = get_tree().get_nodes_in_group("shape_gate")
					for shape_gate in shape_gates:
						if shape_gate.get_meta("shape_gate") == active_shape:
							shape_gate.queue_free()
					
					
			return
			
		if shape:
			var shape_type = shape.get_meta("special_shape_type")
			Global.collected_shapes.append(shape_type)
			Global.emit_signal("shape_collected", shape_type)
			queue_free()
