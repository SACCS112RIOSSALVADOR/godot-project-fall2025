extends Node2D

var tilemap_1 = preload("res://project/scene/debugmap_1.tscn") # Preload for efficiency
var tilemap_2 = preload("res://project/scene/debugmap_2.tscn")
var tilemap_3 = preload("res://project/scene/debugmap_3.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tilemap_instance
	if GlobalData.current_level == 1:
		tilemap_instance = tilemap_1.instantiate()
	elif GlobalData.current_level == 2:
		tilemap_instance = tilemap_2.instantiate()
	elif GlobalData.current_level == 3:
		tilemap_instance = tilemap_3.instantiate()
	add_child(tilemap_instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
