extends PanelContainer

# Declare variables
var selected_attack : String = ""
var attacker : Node = null

# OnReady variables to link to UI elements
@onready var health_label = $VBoxContainer/HBoxContainer/HealthLabel
@onready var health_bar = $VBoxContainer/HBoxContainer/HealthBar
@onready var light_button = $VBoxContainer/LightAttack
@onready var heavy_button = $VBoxContainer/HeavyAttack

# Called when the node is ready (initialized)
func _ready():
	hide()
	light_button.pressed.connect(_on_light_attack)
	heavy_button.pressed.connect(_on_heavy_attack)

# Show the panel for the selected unit
# Displays the unit’s health and sets the unit as the attacker
func show_for_unit(unit: Node):
	attacker = unit # Set the current attacker
	visible = true # Make the panel visible
	# Update the health label to display the unit’s current health out of max health
	health_label.text = "Health: %d / %d" % [unit.loaded_data.health, health_bar.max_value] 
	health_bar.value = unit.loaded_data.health # Update the health bar
	set_meta("selected_unit", unit) # Store the selected unit as meta-data
	_position_near_unit(unit) # Position the panel near the unit

# Function to handle light attack button press
func _on_light_attack():
	selected_attack = "light"
	print("Selected light attack")

# Function to handle heavy attack button press
func _on_heavy_attack():
	selected_attack = "heavy"
	print("Selected heavy attack")

# Update the health bar and label when health changes
func update_health(new_value: int):
	health_bar.value = new_value
	health_label.text = "Health: %d" % new_value

# Position the panel near the selected unit
# The panel will be offset slightly from the unit’s position in world space
func _position_near_unit(unit: Node):
	# Offset relative to the unit’s position in world space.
	# Positive X is right, negative Y is up.
	var offset := Vector2(32, -32) # Slight offset above and to the right of the unit
	global_position = unit.global_position + offset # Set the panel’s global position based on the unit
