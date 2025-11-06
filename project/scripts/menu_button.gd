extends Button

func _ready() -> void:
	pass

func _on_menu_pressed() -> void:
	# Unpause before changing scene
	get_tree().paused = false
	
	# Change to main menu scene (adjust path to your main menu scene)
	get_tree().change_scene_to_file("res://project/scene/main_menu.tscn")
