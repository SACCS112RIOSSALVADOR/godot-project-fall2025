extends Button

func _ready() -> void:
	pass

# Called when the menu button is pressed. This function is connected to the 'pressed' signal of the button.
func _on_menu_pressed() -> void:
	# Unpause before changing scene
	get_tree().paused = false
	# Change to main menu scene (adjust path to your main menu scene)
	get_tree().change_scene_to_file("res://project/scene/main_menu.tscn")
