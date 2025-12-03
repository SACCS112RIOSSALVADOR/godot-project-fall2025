class_name Tetromino
extends Node2D

enum {I,T,O,S,Z,L,J}

var health : int = 10
var shape

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func _createShape(shape_type) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#initalize shape
func _init(type):
	_createShape(type)
	pass
