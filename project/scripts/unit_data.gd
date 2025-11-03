# character_data.gd (Custom Resource Script)
class_name UnitData extends Resource

#attributes
#@export var character_name: String = "empty"
@export var health: int = 100
@export var strength: int = 10
@export var team: bool
@export var remaining_steps: int
@export var actionable: bool = true

signal lose_turn
signal health_depleted
signal health_changed(old_value, new_value)
signal team_A_signal
signal team_B_signal

func take_damage(amount):
	var old_health = health
	health -= amount
	health_changed.emit(old_health, health)
	if health <= 0:
		health_depleted.emit()

func team_assign():
	if team == true:
		team_A_signal.emit()
	else:
		team_B_signal.emit()

var steps: int = 0
# ... other character data
var ally_adjacent: bool
var foe_adjacent: bool

func actionsleft():
	if remaining_steps <= 0:
		actionable = false
		lose_turn.emit()
	elif remaining_steps >= 0:
		actionable = true
		remaining_steps = remaining_steps - 1
		


# In another script (e.g., a game manager or character spawner) for later
func _ready():
	var loaded_data: UnitData = load("res://path/to/your/character_data.tres")
	if loaded_data:
		#print("Loaded character: " + loaded_data.character_name)
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")
