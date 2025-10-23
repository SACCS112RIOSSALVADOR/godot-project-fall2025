extends Node2D

const ZERO_D : int = 0
const NINTY_D : int = 90
const ONEEIGHTY : int = 180
const TWOSEVENTY : int = 270
enum {I,T,O,S,Z,L,J}

var health : int = 10
var boardpos : = Vector2(0,0)
var collision: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

func _createShape() -> void:
	pass

func _currentPosition() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#when class is called, check if the inputed position, type, roatation, and collission are valid
func _init(pos = Vector2(0,0),type = null , rotat = null, coll = null):
	pass
	boardpos = pos
	
