extends CanvasLayer
	

@onready var oob_dialogue = $CanvasLayer/Control/OOB
@onready var designintent_dialogue: ColorRect = $CanvasLayer/Control/DESIGNINTENT
var key_presses: int = 0

func _ready() -> void:
	# Only show the dialogue if this is the first start
	if not Global.has_seen_onboarding:
		oob_dialogue.hide()
		slide_dialog(null, designintent_dialogue)
	else:
		hide_all_oob()
	
func hide_all_oob() -> void:
	var all_oob = get_tree().get_nodes_in_group("OOB")
	for oob in all_oob:
		oob.hide()

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
		
	

func _input(event: InputEvent) -> void:
	
	if event is InputEventKey and event.pressed:
		if (key_presses > 0):
			slide_dialog(oob_dialogue, null)
			designintent_dialogue.hide()
			get_viewport().set_input_as_handled()
			 #and oob_dialogue.visible
		if (key_presses == 0):
			slide_dialog(designintent_dialogue, oob_dialogue)
			key_presses = 1
			get_viewport().set_input_as_handled()
			Global.has_seen_onboarding = true
			
			
			
	
	
