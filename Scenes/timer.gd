extends Timer

func _ready():
	start()  # Start the timer
	print("Timer started with wait time:", wait_time)


func _on_timeout() -> void:
	print("bloop")
	queue_free()  # Remove the whole broken character node
	get_tree().reload_current_scene()
