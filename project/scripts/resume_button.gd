extends Button

func _ready() -> void:
	pass

func _on_resume_pressed() -> void:
	# Get reference to the main game scene
	var play_scene = get_tree().current_scene
	if play_scene.has_method("resume_game"):
		play_scene.resume_game()
