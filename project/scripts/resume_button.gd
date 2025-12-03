extends Button

func _ready() -> void:
	pass

# Called when the button is pressed. In this case, it is connected to the 'pressed' signal of the button.
func _on_resume_pressed() -> void:
	# Get reference to the main game scene
	var play_scene = get_tree().current_scene
	# Check if the current scene has a method named "resume_game" to ensure it's safe to call it.
	if play_scene.has_method("resume_game"):
		# Call the "resume_game" method in the current scene to resume gameplay.
		play_scene.resume_game()
