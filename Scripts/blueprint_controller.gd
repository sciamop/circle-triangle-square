extends StaticBody2D

class_name Blueprint

# Blueprint properties
@export var blueprint_name: String = "default_blueprint"
@export var required_shapes: Dictionary = {
	"circle": 0,
	"triangle": 0,
	"square": 0
}
@export var result_item: String = "default_item"

# Visual properties
@export var glow_color: Color = Color(0.2, 0.2, 0.8, 1)
@export var glow_intensity: float = 0.5

# References
@onready var interaction_area: Area2D = $InteractionArea
@onready var polygon: Polygon2D = $Polygon2D
#@onready var collision_shape: CollisionShape2D = $CollisionShape2D
#@onready var sprite: Sprite2D = $Sprite2D
@onready var building_panel: ColorRect = $BuildingPanel
@onready var shape_counts: VBoxContainer = $BuildingPanel/ShapeCounts

# State
var player_in_range: bool = false
var current_player: Node = null
var is_building: bool = false
var placed_shapes: Dictionary = {
	"circle": 0,
	"triangle": 0,
	"square": 0
}
var panel_grow_tween: Tween

#camera
var camera_zoom_out_tween: Tween
var tween: Tween
var original_camera_pos
var original_camera_zoom
var camera
var blueprint_complete: bool = false

func _ready() -> void:
	# Set up interaction area
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	# Set visual properties
	polygon.color = glow_color
	
	# Initialize building panel
	building_panel.hide()
	_update_shape_count_labels()

func toggle_blueprint_item(visible: bool) -> void:
		for blueprint_item in get_tree().get_nodes_in_group("blueprint_item"):
			blueprint_item.visible = visible
			for shape in blueprint_item.get_children():
				for shape_states in shape.get_children():
					# Make sure the empty outline is visible and filled shape is hidden
					var line2d = shape_states.get_node_or_null("blueprint_" + shape.get_meta("shape_type") + "_empty")
					var polygon2d = shape_states.get_node_or_null("blueprint_" + shape.get_meta("shape_type") + "_filled")
					if line2d:
						line2d.visible = visible
					if polygon2d:
						polygon2d.visible = !visible

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player") && area.name != "InsightArea" && blueprint_complete == false:
		player_in_range = true
		current_player = area.get_parent()
		
		# Show all blueprint shapes
		toggle_blueprint_item(true)


func _on_interaction_area_exited(area: Area2D) -> void:
	player_in_range = false
	current_player = null
	if is_building:
		stop_building()
	# Hide all blueprint shapes
	toggle_blueprint_item(false)

func _process(_delta: float) -> void:
	if player_in_range and current_player:
		# Check if player has a square and is pressing the action key
		if current_player.shape_counts["square"] > 0 and blueprint_complete == false:
			start_building()

func start_building() -> void:
	if is_building:
		return
	camera = current_player.camera
	# Store original camera position and zoom
	original_camera_pos = camera.global_position
	original_camera_zoom = camera.zoom
	

	var camera_offset_x:float = building_panel.size.x / 2
	var camera_offset_y:float = building_panel.size.y / 2
	var camera_target = building_panel.global_position
	camera_target.x = camera_target.x + camera_offset_x
	camera_target.y = camera_target.y + camera_offset_y

	# Zoom to mcguffin
	tween = create_tween()
	tween.tween_property(camera, "global_position", camera_target, 0.5)
	tween.parallel().tween_property(camera, "zoom", Vector2(4.2, 4.2), 0.5)


	# Show the panel but keep it at 1px width
	building_panel.visible = true
	building_panel.size.x = 1
	# Center the panel
	building_panel.position.x = -0.5  # Half of 1px width
	
	# Create and start the grow animation
	if panel_grow_tween:
		panel_grow_tween.kill()
	panel_grow_tween = create_tween()
	# Animate both size and position
	panel_grow_tween.parallel().tween_property(building_panel, "size:x", 400, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	panel_grow_tween.parallel().tween_property(building_panel, "position:x", -200, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	is_building = true
	_update_shape_count_labels()
	if current_player.has_method("start_blueprint_building"):
		current_player.start_blueprint_building(self)

func stop_building() -> void:
	if not is_building:
		return
	print("stop building")
	toggle_blueprint_item(false)
	# Zoom back out
	camera_zoom_out_tween = create_tween()
	camera_zoom_out_tween.tween_property(camera, "global_position", original_camera_pos, 0.5)
	camera_zoom_out_tween.parallel().tween_property(camera, "zoom", original_camera_zoom, 0.5)
	
	# Create and start the shrink animation
	if panel_grow_tween:
		panel_grow_tween.kill()
	panel_grow_tween = create_tween()
	# Animate both size and position
	panel_grow_tween.parallel().tween_property(building_panel, "size:x", 1, 0.2).set_ease(Tween.EASE_IN)
	panel_grow_tween.parallel().tween_property(building_panel, "position:x", -0.5, 0.2).set_ease(Tween.EASE_IN)
	panel_grow_tween.tween_callback(func(): building_panel.visible = false)
	
	is_building = false
	placed_shapes = {
		"circle": 0,
		"triangle": 0,
		"square": 0
	}
	_update_shape_count_labels()

func place_shape(shape_type: String) -> void:
	if is_building and placed_shapes[shape_type] < required_shapes[shape_type]:
		placed_shapes[shape_type] += 1
		print(placed_shapes)
		_update_shape_count_labels()
		# Find all shapes of this type in the blueprint item
		var blueprint_item = get_node_or_null("item_blueprint_grapplinghook")
		if blueprint_item:
			
			# Find the next unfilled shape of this type
			for shape in blueprint_item.get_children():
				
				if shape.get_meta("shape_type") == shape_type:

					for shape_state in shape.get_children():
						# Check if this shape is already filled
						var line2d = shape.get_node_or_null("blueprint_" + shape_type + "_empty")
						var polygon2d = shape.get_node_or_null("blueprint_" + shape_type + "_filled")
						
						if line2d and polygon2d and line2d.visible:
							# Create a traveling shape from UI to the blueprint shape
							if current_player and current_player.traveling_shape_scene:
								var traveling_shape = current_player.traveling_shape_scene.instantiate()
								get_tree().root.add_child(traveling_shape)
								
								# Get the UI position for the current shape
								var ui_shape = get_tree().get_first_node_in_group("shape_" + shape_type)
								if ui_shape:
									traveling_shape.init(ui_shape.global_position, shape.global_position, shape_type)

								# Hide the empty outline and show the filled shape
								line2d.visible = false
								polygon2d.visible = true
								
								# Check if blueprint is complete
								if is_complete():
									complete_blueprint()
						break
		
		# Check if blueprint is complete
		if is_complete():
			complete_blueprint()

func is_complete() -> bool:
	for shape_type in required_shapes:
		if placed_shapes[shape_type] < required_shapes[shape_type]:
			return false
	return true

func complete_blueprint() -> void:
	# Handle blueprint completion
	print("Blueprint completed!")
	blueprint_complete = true
	stop_building()

func get_required_shapes() -> Dictionary:
	return required_shapes.duplicate()

func get_result_item() -> String:
	return result_item 

func _update_shape_count_labels() -> void:
	for shape_type in required_shapes:
		var count_label = shape_counts.get_node(shape_type.capitalize() + "/Count")
		if count_label:
			count_label.text = str(placed_shapes[shape_type]) + "/" + str(required_shapes[shape_type])

func _input(event: InputEvent) -> void:
	if is_building:
		if event.is_action_pressed("ui_cancel"):
			stop_building()
			if current_player and current_player.has_method("change_state"):
				current_player.change_state(current_player.PlayerState.IDLE)
		elif event.is_action_pressed("activate_circle"):
			place_shape("circle")
		elif event.is_action_pressed("activate_triangle"):
			place_shape("triangle")
		elif event.is_action_pressed("activate_square"):
			place_shape("square") 
