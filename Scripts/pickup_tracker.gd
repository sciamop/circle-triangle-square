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
	
	var _updateScore = Callable(self, "updateScore") 
	player.connect("on_pickup", _updateScore)
	
	var _checkForActivate = Callable(self, "checkForActivated") 
	player.connect("on_activate", _checkForActivate)
	
	var _no_projectile = Callable(self, "no_projectile") 
	player.connect("on_empty", _no_projectile)
		
	checkStatus()	

func checkForActivated(shape:String) -> void:
	print(shape)
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

	set_blueprint_item_status()
	
	var activated_icon:Polygon2D = find_child(currently_activated + "Icon")
	if activated_icon:
		activated_icon.color = active_color
	
func set_blueprint_item_status():
		var blueprint_color:Color = enabled_color
		
		if (currently_activated == "blueprint"):
			blueprint_color = active_color
			
		var blueprint_item_polygon2ds = blueprint_item.get_children()
		for polygon2d:Polygon2D in blueprint_item_polygon2ds:
			polygon2d.color = blueprint_color

		if (currently_activated == "pickaxe"):
			blueprint_color = active_color
		else:
			blueprint_color = enabled_color

		var pickaxe_item_polygon2ds = pickaxe_item.get_children()
		for polygon2d:Polygon2D in pickaxe_item_polygon2ds:
			polygon2d.color = blueprint_color

func updateScore(pickup_type:String, pieces:int):

	# var iconStr:String = "../"+pickup_type+"VBoxContainer/"+pickup_type+"CenterContainer/" + pickup_type + "Icon"

	# var icon:Polygon2D = get_node(iconStr)
	
	var labelStr:String = pickup_type + "VBoxContainer/" + pickup_type + "Label"
	var label:Label =  get_node(labelStr)	
	
	
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
	
func no_projectile(shape: String) -> void:
	animation_player.play(shape + "_deny")
	print(shape + "_deny")
	await animation_player.animation_finished
	animation_player.play("RESET")
	

	
