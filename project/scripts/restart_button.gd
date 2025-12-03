extends Button

func _ready() -> void:
	pass

# Called when the restart button is pressed. This function is connected to the 'pressed' signal of the button.
func _on_restart_pressed() -> void:
	# Unpause before restarting
	get_tree().paused = false
	# Reload the current scene
	get_tree().reload_current_scene()
