extends Control

@onready var main_menu: VBoxContainer = $MainMenu
@onready var options_menu: Panel = $OptionsMenu

func _ready():
	get_tree().paused = false
	main_menu.visible = true
	options_menu.visible = false

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scene/tile_map.tscn")

func _on_options_pressed():
	print("Settings Pressed")
	main_menu.visible = false
	options_menu.visible = true

func _on_exit_pressed():
	get_tree().quit()

func _on_back_options_pressed() -> void:
	_ready()
