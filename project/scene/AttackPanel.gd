extends PanelContainer

var selected_attack : String = ""
var attacker : Node = null

@onready var health_label = $VBoxContainer/HBoxContainer/HealthLabel
@onready var health_bar = $VBoxContainer/HBoxContainer/HealthBar
@onready var light_button = $VBoxContainer/LightAttack
@onready var heavy_button = $VBoxContainer/HeavyAttack

func _ready():
	hide()
	light_button.pressed.connect(_on_light_attack)
	heavy_button.pressed.connect(_on_heavy_attack)

func show_for_unit(unit: Node):
	attacker = unit
	visible = true
	health_label.text = "Health: %d / %d" % [unit.loaded_data.health, health_bar.max_value]
	health_bar.value = unit.loaded_data.health
	set_meta("selected_unit", unit)
	_position_near_unit(unit)

func _on_light_attack():
	selected_attack = "light"
	print("Selected light attack")

func _on_heavy_attack():
	selected_attack = "heavy"
	print("Selected heavy attack")

func update_health(new_value: int):
	health_bar.value = new_value
	health_label.text = "Health: %d" % new_value
	
func _position_near_unit(unit: Node):
	# Offset relative to the unit’s position in world space.
	# Positive X is right, negative Y is up.
	var offset := Vector2(32, -32)
	global_position = unit.global_position + offset
