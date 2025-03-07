extends CanvasLayer

#var slider_scene
#var slider:HSlider
#var label:Label
#
#var slider_data:Array = ["forceX","forceY","dirX","dirY"]
#var slider_scene_height = 40
#var sliders_size:int 
#
#@onready var arm_hurt_box: AnimatableBody2D = $"/root/Game/Player/ArmHurtBoxWrapper"
#@onready var polygon_2d: Polygon2D = $Polygon2D
#
#func _ready() -> void:
	#sliders_size = slider_data.size()
	#var counter:int = 0
#
	#for items in slider_data:
		#slider_scene = preload("res://Scenes/slider.tscn").instantiate() 
		#slider_scene.global_position.y = slider_scene_height * counter
		#counter = counter + 1
		#
		#add_child(slider_scene)
		#
		#
	#polygon_2d.scale.y = sliders_size
	#
#
#func set_slider_data() -> void:
	#var kids = get_children()
	#for kid in kids:
		#if kid is HSlider:
			#var hslider = kid
			#hslider.max_value = 1000
			#hslider.min_value = 10
			#hslider._on_value_changed.connect(_on_value_changed.bind(100))
#
#func _on_value_changed(val:int):
	#print(val)
	#
			
			
	
	
