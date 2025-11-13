extends "res://project/scripts/ShapeBase.gd"

"ShapeBase.gd = shared “brain” script.
Each shape scene still has its own CharacterBody2D root, 
Area2D for clicking, RayCast2Ds for edges, and any Sprite/Node2D visuals.
Every shape’s script file now contains only:
All RayCast2D nodes are grouped (or simply children), 
so the base script finds them automatically."

#Prority function for Enemy AI targeting
#Should be Unique ebtween each tretris shape scene and 1-7

var priority = 2

func return_priority():
	return priority
