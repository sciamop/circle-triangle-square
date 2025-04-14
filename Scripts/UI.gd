extends CanvasLayer
	
@onready var player: Player = $"/root/Game/Player"
@onready var oob_dialogue = $CanvasLayer/Control/OOB
@onready var designintent_dialogue: ColorRect = $CanvasLayer/Control/DESIGNINTENT
@onready var enemy_oob: ColorRect = $CanvasLayer/Control/ENEMY_OOB
@onready var tri_oob: ColorRect = $CanvasLayer/Control/TRI_OOB
@onready var cir_oob: ColorRect = $CanvasLayer/Control/CIR_OOB
@onready var shapes_oob: ColorRect = $CanvasLayer/Control/SHAPES_OOB
@onready var enemy: Enemy = $"/root/Game/enemy"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var blueprint_pickup: Blueprint = $"/root/Game/BlueprintPickup"
@onready var blueprint_item: Area2D = $CanvasLayer/Control/BoxContainer/HBoxContainer/squareVBoxContainer2/squareCenterContainer/item_blueprint_grapplinghook

var key_presses: int = 0
var dialog_state: String = "none"
var any_dialogues_visible: bool = false

signal dialog_visible(visible: bool)

func _ready() -> void:
	# Only show the dialogue if this is the first start
	var _show_enemy_onboarding = Callable(self, "show_enemy_onboarding") 
	player.connect("health_changed", _show_enemy_onboarding)
	
	var _show_shapes_onboarding = Callable(self, "show_shapes_onboarding")
	enemy.connect("on_death", _show_shapes_onboarding)
	
	if not Global.has_seen_onboarding:
		dialog_state = "intent"
	else:
		dialog_state = "none"

	var _add_blueprint_item_to_inventory = Callable(self, "add_blueprint_item_to_inventory")
	blueprint_pickup.connect("blueprint_item_added_to_inventory", _add_blueprint_item_to_inventory)
	
	# make sure blueprint item shows
	if Global.has_blueprint_item:
		add_blueprint_item_to_inventory("null")
		
	emit_signal("dialog_visible", true)
	# figure out what's going on with the dialogues
	get_state()

func add_blueprint_item_to_inventory(name: String) -> void:

	print(blueprint_item.name)
	# if Global.has_blueprint_item:
	blueprint_item.show()
	animation_player.play("add_blueprint_item")

func hide_all_oob() -> void:
	var all_oob = get_tree().get_nodes_in_group("OOB")
	for oob in all_oob:
		oob.hide()

func show_enemy_onboarding(health: int) -> void:
	if any_dialogues_visible:
		return
	if !Global.has_seen_enemy_onboarding:
		dialog_state = "enemy"
		get_state()

func show_shapes_onboarding() -> void:
	if !Global.has_seen_shapes_onboarding:
		dialog_state = "shapes"
		get_state()
				

func slide_dialog( out_dialog: ColorRect, in_dialog: ColorRect) -> void:
	
	if (out_dialog):

		var out_dialog_target_position_x:int = out_dialog.global_position.x - 1100
		out_dialog.show()
		var out_tween = create_tween()
		out_tween.tween_property(out_dialog, "global_position", Vector2(out_dialog_target_position_x, out_dialog.global_position.y), 0.25)
		await out_tween.finished
		out_dialog.hide()
	
	if (in_dialog):
		
		var in_dialog_target_position: Vector2 = in_dialog.global_position
		in_dialog.global_position.x = in_dialog.global_position.x + 1100
		in_dialog.show()
		var in_tween = create_tween()
		in_tween.tween_property(in_dialog, "global_position", in_dialog_target_position, 0.25)
		await in_tween.finished
		

func get_state() -> void:
	match dialog_state:
			"intent":
				print("intent")
				slide_dialog(null, designintent_dialogue)
				dialog_state = "controls"
				get_viewport().set_input_as_handled()
				emit_signal("dialog_visible", true)
				any_dialogues_visible = true
			"controls":
				slide_dialog(designintent_dialogue, oob_dialogue)
				get_viewport().set_input_as_handled()
				Global.has_seen_onboarding = true
				dialog_state = "none"
				any_dialogues_visible = true
			"enemy":
				slide_dialog(null, enemy_oob)
				get_viewport().set_input_as_handled()
				emit_signal("dialog_visible", true)
				Global.has_seen_enemy_onboarding = true
				dialog_state = "none"
				any_dialogues_visible = true
			"shapes":
				slide_dialog(null, shapes_oob)
				get_viewport().set_input_as_handled()
				emit_signal("dialog_visible", true)
				dialog_state = "circles"
				any_dialogues_visible = true
			"circles":
				slide_dialog(shapes_oob, cir_oob)
				get_viewport().set_input_as_handled()
				emit_signal("dialog_visible", true)
				dialog_state = "triangles"
				any_dialogues_visible = true
			"triangles":
				slide_dialog(cir_oob, tri_oob)
				get_viewport().set_input_as_handled()
				emit_signal("dialog_visible", true)
				Global.has_seen_shapes_onboarding = true
				dialog_state = "none"
				any_dialogues_visible = true
			"squares":
				pass
			"none":
				var visible_oob = get_tree().get_nodes_in_group("OOB")
				for oob in visible_oob:
					if oob.visible:
						slide_dialog(oob, null)
				emit_signal("dialog_visible", false)
				any_dialogues_visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and any_dialogues_visible:
		get_state()

			
			
			
			


			
			
			
	
	
