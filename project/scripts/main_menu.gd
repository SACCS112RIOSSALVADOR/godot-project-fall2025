extends Control

@onready var main_menu_buttons: VBoxContainer = $main_menu_buttons
@onready var settings_panel: Panel = $settings_panel

# Called when the node enters the scene tree for the first time.
func _ready():
	main_menu_buttons.visible = true
	settings_panel.visible = false

# Start button function
func _on_start_pressed():
	get_tree().change_scene_to_file("res://project/scene/tile_map.tscn") 
	# when clicked Start, change scene to tile_map.tscn
	
# Settings button function
func _on_settings_pressed():
	main_menu_buttons.visible = false # hide menu panel when clicked
	settings_panel.visible = true # show settings panel when clicked

# Exit button function
func _on_exit_pressed(): 
	get_tree().quit() # quit the game when clicked

# Back button 
func _on_back_pressed():
	_ready() # back to menu when clicked
