extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Start button function
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://project/scene/tile_map.tscn") # when clicked Start, change scene to tile_map.tscn
	
# Settings button function
func _on_settings_pressed() -> void:
	pass # Replace with function body.

# Exit button function
func _on_exit_pressed() -> void: 
	get_tree().quit() # Quit the game
