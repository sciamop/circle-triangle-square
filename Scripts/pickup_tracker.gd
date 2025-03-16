extends VBoxContainer

# @onready var square_icon: Polygon2D = $squareCenterContainer/squareIcon
# @onready var square_label: Label = $squareLabel
@onready var player: Player = $"/root/Game/Player"
@onready var animation_player: AnimationPlayer = $"../../../../../AnimationPlayer"


var square_score:int = 0
var triangle_score:int = 0
var circle_score:int = 0
var score:int = 0


func _ready() -> void:
	var callable = Callable(self, "updateScore") 
	player.connect("on_pickup", callable)

func updateScore(pickup_type:String, pieces:int):
	
	
	# var iconStr:String = "../"+pickup_type+"VBoxContainer/"+pickup_type+"CenterContainer/" + pickup_type + "Icon"

	# var icon:Polygon2D = get_node(iconStr)
	
	var labelStr:String = "../" + pickup_type + "VBoxContainer/" + pickup_type + "Label"
	var label:Label =  get_node(labelStr)	
	label.set_text(str(pieces))
	animation_player.play(pickup_type + "_update")
	await animation_player.animation_finished
	
