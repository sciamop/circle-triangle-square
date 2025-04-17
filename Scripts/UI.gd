extends CanvasLayer
	
@onready var player: Player = $"/root/Game/Player"
@onready var oob_dialogue = $CanvasLayer/Control/OOB
@onready var designintent_dialogue: ColorRect = $CanvasLayer/Control/DESIGNINTENT

@onready var enemy_oob: ColorRect = $CanvasLayer/Control/ENEMY_OOB
@onready var enemy_oob_trigger: Area2D = $"/root/Game/OOB_enemy_trigger"

@onready var tri_oob: ColorRect = $CanvasLayer/Control/TRI_OOB
@onready var tri_oob_trigger: Area2D = $"/root/Game/OOB_tri_trigger"

@onready var cir_oob: ColorRect = $CanvasLayer/Control/CIR_OOB
@onready var cir_oob_trigger: Area2D = $"/root/Game/OOB_cir_trigger"

@onready var squ_oob: ColorRect = $CanvasLayer/Control/SQU_OOB
@onready var squ_oob_trigger: Area2D = $"/root/Game/OOB_squ_trigger"

@onready var cat_oob: ColorRect = $CanvasLayer/Control/CAT_OOB
@onready var cat_oob_trigger: Area2D = $"/root/Game/OOB_cat_trigger"

@onready var blueprint_oob: ColorRect = $CanvasLayer/Control/BLUEPRINT_OOB
@onready var blueprint_oob_trigger: Area2D = $"/root/Game/OOB_blueprint_trigger"

@onready var shapes_oob: ColorRect = $CanvasLayer/Control/SHAPES_OOB


@onready var enemy: Enemy = $"/root/Game/enemy"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var blueprint_pickup: Blueprint = $"/root/Game/BlueprintPickup"
@onready var blueprint_item_grappling_hook: Area2D = $CanvasLayer/Control/BoxContainer/HBoxContainer/grapplingHookVBoxContainer/squareCenterContainer/item_blueprint_grapplinghook
@onready var blueprint_item_pickaxe: Area2D = $CanvasLayer/Control/BoxContainer/HBoxContainer/pickaxeVBoxContainer/squareCenterContainer/item_blueprint_pickaxe

var key_presses: int = 0
var dialog_state: String = "none"
var any_dialogues_visible: bool = false
signal dialog_visible(visible: bool)

func _ready() -> void:
	
	if not Global.has_seen_onboarding:
		dialog_state = "intent"
	
	
		# Only show the dialogue if this is the first start
		var _show_onboarding = Callable(self, "show_onboarding") 

		if enemy_oob_trigger:
			enemy_oob_trigger.connect("oob_triggered", _show_onboarding)
			tri_oob_trigger.connect("oob_triggered", _show_onboarding)
			squ_oob_trigger.connect("oob_triggered", _show_onboarding)
			cir_oob_trigger.connect("oob_triggered", _show_onboarding)
			cat_oob_trigger.connect("oob_triggered", _show_onboarding)
			blueprint_oob_trigger.connect("oob_triggered", _show_onboarding)
			enemy.connect("on_death", _show_onboarding.bind("shapes"))
		
		var _show_shapes_onboarding = Callable(self, "show_shapes_onboarding")
		enemy.connect("on_death", _show_shapes_onboarding)
		
		var _show_circle_triangle_square_onboarding = Callable(self, "show_circle_triangle_square_onboarding") 
		player.connect("on_activate", _show_circle_triangle_square_onboarding)

		emit_signal("dialog_visible", true)
		# figure out what's going on with the dialogues
		
	else:
		dialog_state = "none"

	var _add_blueprint_item_to_inventory = Callable(self, "add_blueprint_item_to_inventory")
	blueprint_pickup.connect("blueprint_item_added_to_inventory", _add_blueprint_item_to_inventory)

# make sure blueprint item shows
	if Global.has_grappling_hook:
		add_blueprint_item_to_inventory("grappling hook")
	if Global.has_pick_axe:
		add_blueprint_item_to_inventory("pickaxe")
	get_state()

func add_blueprint_item_to_inventory(_name: String) -> void:
	print(_name)
	if (_name == "grappling hook"):
		blueprint_item_grappling_hook.show()
		animation_player.play("add_blueprint_item")
	elif (_name == "pickaxe"):
		blueprint_item_pickaxe.show()
		animation_player.play("add_blueprint_item")


func show_onboarding(oob_to_display: String) -> void:
	if any_dialogues_visible:
		return

	if oob_to_display == "circle":
		if !Global.has_seen_circles_onboarding:
			dialog_state = "circles"
			get_state()
	elif oob_to_display == "triangle":
		if !Global.has_seen_triangles_onboarding:
			dialog_state = "triangles"
			get_state()
	elif oob_to_display == "square":
		if !Global.has_seen_squares_onboarding:
			dialog_state = "squares"
			get_state()
	elif oob_to_display == "enemy":
		if !Global.has_seen_enemy_onboarding:
			dialog_state = "enemy"
			get_state()
	elif oob_to_display == "shapes":
		if !Global.has_seen_shapes_onboarding:
			dialog_state = "shapes"
			get_state()
	elif oob_to_display == "blueprint":
		if !Global.has_seen_blueprint_onboarding:
			dialog_state = "blueprint"
			get_state()
	elif oob_to_display == "cat":
		if !Global.has_seen_cat_onboarding:
			dialog_state = "cat"
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
		
func start_video_player(dialog:ColorRect) -> void:
	var vs_player:VideoStreamPlayer = dialog.find_child("VideoStreamPlayer")
	if vs_player:
		vs_player.play()

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
				show_dialogue(enemy_oob)
				Global.has_seen_enemy_onboarding = true
			"shapes":
				show_dialogue(shapes_oob)
				Global.has_seen_shapes_onboarding = true
			"circles":
				show_dialogue(cir_oob)
				Global.has_seen_circles_onboarding = true
			"triangles":
				show_dialogue(tri_oob)
				Global.has_seen_triangles_onboarding = true
			"squares":
				show_dialogue(squ_oob)
				Global.has_seen_squares_onboarding = true	
			"blueprint":
				show_dialogue(blueprint_oob)
				Global.has_seen_blueprint_onboarding = true
			"cat":
				print("cat_____")
				show_dialogue(cat_oob)
				Global.has_seen_cat_onboarding = true
			"none":
				var visible_oob = get_tree().get_nodes_in_group("OOB")
				for oob in visible_oob:
					if oob.visible:
						slide_dialog(oob, null)
				emit_signal("dialog_visible", false)
				any_dialogues_visible = false

func show_dialogue(dialog: ColorRect) -> void:
	# Don't show dialogue if player is building
	# if player.current_state == player.PlayerState.BUILDING:
	# 	return
		
	slide_dialog(null, dialog)
	get_viewport().set_input_as_handled()
	emit_signal("dialog_visible", true)
	any_dialogues_visible = true
	start_video_player(dialog)
	dialog_state = "none"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and any_dialogues_visible:
		get_state()

			

func _on_oob_trigger_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player")):
		print('poop')
	pass # Replace with function body.
