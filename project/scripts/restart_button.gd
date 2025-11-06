extends Button

func _ready() -> void:
	pass

func _on_restart_pressed() -> void:
	# Unpause before restarting
	get_tree().paused = false
	# Reload the current scene
	get_tree().reload_current_scene()
