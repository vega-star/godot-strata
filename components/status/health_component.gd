class_name HealthComponent extends Node

signal health_change(previous_value: int, new_value: int)
signal damage_inferred()
signal heal_inferred()

@export var max_health: int
var current_health: int

const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.1
var damage_effect_running : bool = false

func _ready():
	current_health = max_health

func heal_damage(amount: int):
	var previous_value := current_health
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	health_change.emit(previous_value,current_health)
	heal_inferred.emit()

func infer_damage(damage):
	var previous_value := current_health
	current_health -= damage
	health_change.emit(previous_value,current_health)
	damage_inferred.emit()
	
	if current_health <= 0:
		owner.die()
