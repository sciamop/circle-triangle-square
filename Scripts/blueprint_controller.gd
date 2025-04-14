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
@onready var shape_counts: HBoxContainer = $BuildingPanel/ShapeCounts
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D = $"/root/Game/Player"
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
var building_panel_size_y: int
var building_panel_size_x: int
var building_panel_pos: Vector2
var blueprint_item:Area2D

#camera
var camera_zoom_out_tween: Tween
var tween: Tween
var original_camera_pos
var original_camera_zoom
var camera
var blueprint_complete: bool = false

signal blueprint_item_added_to_inventory(blueprint_item_name)
signal shape_spent_on_blueprint(shape_type)

func _ready() -> void:
	# Set up interaction area
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	# Set visual properties
	polygon.color = glow_color
	building_panel_size_y = building_panel.size.y
	building_panel_size_x = building_panel.size.x
	building_panel_pos = building_panel.global_position
	# Initialize building panel
	building_panel.hide()
	_update_shape_count_labels()

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player") && area.name != "InsightArea" && blueprint_complete == false:
		player_in_range = true
		current_player = area.get_parent()


func _on_interaction_area_exited(area: Area2D) -> void:
	player_in_range = false
	current_player = null
	if is_building:
		stop_building()


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
	

	var camera_offset_x:float = building_panel_size_x
	var camera_offset_y:float = building_panel_size_y
	var camera_target = building_panel_pos
	camera_target.x = camera_target.x + camera_offset_x
	camera_target.y = camera_target.y + camera_offset_y

	# Zoom to blueprint
	tween = create_tween()
	tween.tween_property(camera, "global_position", camera_target, 0.5)


	# Show the panel but move it off screen
	building_panel.visible = true
	building_panel.global_position.x = building_panel.global_position.x + 1000
	panel_grow_tween = create_tween()
	panel_grow_tween.tween_property(building_panel,"global_position",building_panel_pos ,0.5)

	is_building = true
	_update_shape_count_labels()
	if current_player.has_method("start_blueprint_building"):
		current_player.start_blueprint_building(self)


func hide_building_panel() -> void:
	building_panel.global_position = building_panel_pos
	building_panel.hide()

func stop_building() -> void:
	if not is_building:
		return
	print("stop building")
	# Zoom back out
	camera_zoom_out_tween = create_tween()
	camera_zoom_out_tween.tween_property(camera, "global_position", original_camera_pos, 0.5)
	
	# Show the panel but move it off screen
	var hidden_building_panel_pos = Vector2(building_panel_pos.x - 1000, building_panel_pos.y)
	panel_grow_tween = create_tween()
	panel_grow_tween.tween_property(building_panel,"global_position",hidden_building_panel_pos ,0.5)
	panel_grow_tween.tween_callback(hide_building_panel)

	is_building = false
	# placed_shapes = {
	# 	"circle": 0,
	# 	"triangle": 0,
	# 	"square": 0
	# }


	_update_shape_count_labels()

func place_shape(shape_type: String) -> void:
	if is_building and placed_shapes[shape_type] < required_shapes[shape_type]:
		placed_shapes[shape_type] += 1
		print(placed_shapes)
		_update_shape_count_labels()
		emit_signal("shape_spent_on_blueprint",shape_type)
		# player.
		# Find all shapes of this type in the blueprint item
		blueprint_item = building_panel.get_node_or_null("item_blueprint_grapplinghook")
		
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
								
								
								# var is_dialogue = Callable(self, "set_dialog_invinciblity") 
								# ui.connect("dialog_visible", is_dialogue)

								var _toggle_blocks = Callable(self, "toggle_blocks")
								traveling_shape.connect("animation_finished", _toggle_blocks.bind(line2d,polygon2d))

								get_tree().root.add_child(traveling_shape)
								
								# Get the UI position for the current shape
								var ui_shape = get_tree().get_first_node_in_group("shape_" + shape_type)
								if ui_shape:
									traveling_shape.init(ui_shape.global_position, shape.global_position, shape_type)
								
								# Check if blueprint is complete
								if is_complete():
									complete_blueprint()
							return
		
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
	animation_player.play("blueprint_complete")
	await animation_player.animation_finished

	make_blueprint_item_real()

	stop_building()

func make_blueprint_item_real() -> void:
	# we want to get the item out of the blueprint!
	building_panel.remove_child(blueprint_item)
	var blueprint_root: StaticBody2D = building_panel.get_parent()
	blueprint_root.add_child(blueprint_item)
	
	# now we want to position it where the placeholder was
	var blueprint_marker: Polygon2D = blueprint_root.get_node("Polygon2D")
	blueprint_item.global_position = blueprint_marker.global_position
	
	# hide the marker/placeholder
	blueprint_marker.hide()

	# move it into inventory
	move_blueprint_item_into_inventory()

func move_blueprint_item_into_inventory() -> void:
	# Set fixed starting position at 50% screen width and 20px from bottom
	var viewport_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	var end_pos: Vector2 = camera.get_screen_center_position() + Vector2(0, viewport_size.y/2 + 200)	
	var blueprint_item_inventory_tween: Tween = create_tween()
	blueprint_item_inventory_tween.tween_interval(1.5)
	blueprint_item_inventory_tween.tween_property(blueprint_item, "global_position", end_pos, 0.25)
	blueprint_item_inventory_tween.tween_callback(blueprint_move_complete)
	
func blueprint_move_complete() -> void:
	emit_signal("blueprint_item_added_to_inventory","grappling hook")
	Global.has_blueprint_item = true

func get_required_shapes() -> Dictionary:
	return required_shapes.duplicate()

func get_result_item() -> String:
	return result_item 

func toggle_blocks(empty_block: Line2D, full_block: Polygon2D) -> void:
	empty_block.visible = false
	full_block.visible = true
	pass

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
