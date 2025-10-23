extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_pressed_pause() -> void:
	var game = get_tree().get_root().get_node("TileMap")  # adjust if needed
	game.pause_game()
