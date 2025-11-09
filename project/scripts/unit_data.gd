# character_data.gd (Custom Resource Script)
class_name UnitData extends Resource

#attributes
#@export var character_name: String = "empty"
@export var health: int = 100
@export var strength: int = 10
@export var team: bool
@export var remaining_steps: int = 3
@export var actionable: bool = true
@export var in_combat: bool
@export_enum("I","T","O","S","Z","L","J") var shape_type: String

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

func actionsleft():
	if remaining_steps <= 0:
		actionable = false
		lose_turn.emit()
	elif remaining_steps >= 0:
		actionable = true
		remaining_steps = remaining_steps - 1
		
# In another script (e.g., a game manager or character spawner) for later
func _ready():
	var loaded_data: UnitData = load("res://project/resources/unitdata_resource.tres")
	if loaded_data:
		#print("Loaded character: " + loaded_data.character_name)
		print("Health: " + str(loaded_data.health))
	else:
		print("Failed to load character data.")
