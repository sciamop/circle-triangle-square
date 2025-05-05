extends HBoxContainer

# @onready var square_icon: Polygon2D = $squareCenterContainer/squareIcon
# @onready var square_label: Label = $squareLabel
@onready var player: Player = $"/root/Game/Player"
@onready var circle_icon: Polygon2D = $circleVBoxContainer/circleCenterContainer/circleIcon
@onready var triangle_icon: Polygon2D = $triangleVBoxContainer/CenterContainer/triangleIcon
@onready var square_icon: Polygon2D = $squareVBoxContainer/squareCenterContainer/squareIcon
@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"
@onready var blueprint_item: Area2D = $grapplingHookVBoxContainer/squareCenterContainer/item_blueprint_grapplinghook
@onready var pickaxe_item: Area2D = $pickaxeVBoxContainer/squareCenterContainer/item_blueprint_pickaxe

var square_score:int = 0
var triangle_score:int = 0
var circle_score:int = 0
var score:int = 0
var disabled_color:Color = Color(0,0,0,0.5);
var enabled_color:Color = Color(0,0,0,1.0);
@export var active_color:Color = Color(1,0,0,1.0);
var currently_activated:String = "triangle"

signal on_score(circle_score,triangle_score,square_score)

func _ready() -> void:
	print("Pickup tracker ready")
	# Add shape groups to icons
	circle_icon.add_to_group("shape_circle")
	triangle_icon.add_to_group("shape_triangle")
	square_icon.add_to_group("shape_square")
	
	# Add pickup tracker to group
	add_to_group("pickup_tracker")
	
	# Connect to player signals
	if player:
		print("Connecting to player signals")
		player.connect("on_pickup", Callable(self, "updateScore"))
		player.connect("on_activate", Callable(self, "checkForActivated"))
		player.connect("on_empty", Callable(self, "no_projectile"))
	else:
		print("Player not found!")
		
	checkStatus()

func checkForActivated(shape:String) -> void:
	print("ACTIVATED: " + shape)
	currently_activated = shape
	checkStatus()

func checkStatus() -> void:
	
	if (square_score == 0):
		square_icon.color = disabled_color
	else:
		square_icon.color = enabled_color
	
	if (triangle_score == 0):
		triangle_icon.color = disabled_color
	else:
		triangle_icon.color = enabled_color 
		
	if (circle_score == 0):
		circle_icon.color = disabled_color
	else:
		circle_icon.color = enabled_color

	# Handle grappling hook
	var grappling_hook_color:Color = enabled_color
	if (currently_activated == "grappling_hook"):
		grappling_hook_color = active_color
		
	if blueprint_item:
		var grappling_hook_polygon2ds = blueprint_item.get_children()
		for polygon2d:Polygon2D in grappling_hook_polygon2ds:
			polygon2d.color = grappling_hook_color

	# Handle pickaxe
	var pickaxe_color:Color = enabled_color
	if (currently_activated == "pickaxe"):
		pickaxe_color = active_color

	if pickaxe_item:
		var pickaxe_item_polygon2ds = pickaxe_item.get_children()
		for polygon2d:Polygon2D in pickaxe_item_polygon2ds:
			polygon2d.color = pickaxe_color
	
	# Handle basic shapes
	if currently_activated in ["triangle", "square", "circle"]:
		var activated_icon:Polygon2D = find_child(currently_activated + "Icon")
		if activated_icon:
			activated_icon.color = active_color


func updateScore(pickup_type:String, pieces:int):
	print("score updated")
	var labelStr:String = pickup_type + "VBoxContainer/" + pickup_type + "Label"
	var label:Label = get_node(labelStr)

	if label:
		label.set_text(str(pieces))
		animation_player.play(pickup_type + "_update")
		await animation_player.animation_finished
		animation_player.play("RESET")
		
		if (pickup_type == "triangle"):
			triangle_score = pieces
		if (pickup_type == "square"):
			square_score = pieces
		if (pickup_type == "circle"):
			circle_score = pieces
			
		checkStatus()
		emit_signal("on_score", circle_score, triangle_score, square_score)
	else:
		print("Label not found: ", labelStr)

func no_projectile(shape: String) -> void:
	animation_player.play(shape + "_deny")
	print(shape + "_deny")
	await animation_player.animation_finished
	animation_player.play("RESET")
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory_left"):
		cycle_inventory(-1)
	elif event.is_action_pressed("inventory_right"):
		cycle_inventory(1)

func cycle_inventory(direction: int) -> void:
	# Get available shapes based on player's inventory
	var available_shapes = []
	
	# Add shapes in visual order: circle, triangle, square, grappling hook, pickaxe
	if circle_score > 0:
		available_shapes.append("circle")
	if triangle_score > 0:
		available_shapes.append("triangle")
	if square_score > 0:
		available_shapes.append("square")
	
	# Add special items if player has them
	if player.current_state != player.PlayerState.BUILDING:
		if Global.has_grappling_hook:
			print("Adding grappling hook to available shapes")
			available_shapes.append("grappling_hook")
		if Global.has_pick_axe:
			available_shapes.append("pickaxe")
	
	print("Available shapes: ", available_shapes)
	print("Current shape: ", currently_activated)
	print("Has grappling hook: ", Global.has_grappling_hook)
	
	# If no shapes are available, return
	if available_shapes.size() == 0:
		return
	
	# Find current index
	var current_index = available_shapes.find(currently_activated)
	print("Current index: ", current_index)
	if current_index == -1:
		current_index = 0  # Default to first item if current not found


	# Calculate new index with wrap-around
	var new_index = (current_index + direction) % available_shapes.size()
	if new_index < 0:
		new_index = available_shapes.size() - 1
	
	print("New index: ", new_index)
	
	# Update selection and active projectile
	var new_shape = available_shapes[new_index]
	print("New shape: ", new_shape)
	
	# Update activation and projectile
	checkForActivated(new_shape)
	if player:
		player.update_activation(new_shape)
		player.switch_projectile(new_shape)

	
