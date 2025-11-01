extends Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_resume_pressed() -> void:
	get_tree().paused = false  # resumes global pause
	get_parent().hide() # hides the VBoxContainer panel
	# optional: if you want to explicitly call the main node’s resume logic:
	get_tree().root.get_node("main").resume_game() # replace "Main" with the actual path to your play.gd node
