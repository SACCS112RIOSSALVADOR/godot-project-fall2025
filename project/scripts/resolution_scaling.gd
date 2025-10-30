extends OptionButton

# Enable resolution scaling 
func _on_item_selected(index: int) -> void:
	var options = [1, 0.75, 0.50, 0.25] # 100%, 75%, 50%, 25% scaling
	var value = options[index]
	print(value)
	get_tree().root.scaling_3d_scale = value 
