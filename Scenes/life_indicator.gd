extends HBoxContainer

@onready var player: Player = $"/root/Game/Player"
@onready var life_v_box_container_0: VBoxContainer = $lifeVBoxContainer0
@onready var life_v_box_container_1: VBoxContainer = $lifeVBoxContainer1
@onready var life_v_box_container_2: VBoxContainer = $lifeVBoxContainer2
@onready var life_v_box_container_3: VBoxContainer = $lifeVBoxContainer3
@onready var animation_player: AnimationPlayer = $"../../../../AnimationPlayer"


var circleIcon3:Array[Node]
var circleIcon2:Array[Node]
var circleIcon1:Array[Node]

func _ready() -> void:
	var callable = Callable(self, "updateHealth") 
	player.connect("health_changed", callable)
	

	
	circleIcon3 = life_v_box_container_3.find_children("*","Polygon2D")
	circleIcon2 = life_v_box_container_2.find_children("*","Polygon2D")
	circleIcon1 = life_v_box_container_1.find_children("*","Polygon2D")

func pause_action(pause:bool) -> void:
	if pause:
		SceneTree.paused = true
	else:
		
		SceneTree.paused = false
	pass

func updateHealth(current_health:int) -> void:
	if (current_health == 30):
		for poop in circleIcon3:
			poop.color = Color(0.5,0.5,0.5,0.5)
			animation_player.play("take_damage_3")
	if (current_health <= 20):
		for poop in circleIcon2:
			poop.color = Color(0.5,0.5,0.5,0.5)
	if (current_health <= 10):
		for poop in circleIcon1:
			poop.color = Color(0.5,0.5,0.5,0.5)
	print(str(current_health))
