class_name HealthComponent extends Node

signal health_change(previous_value: int, new_value: int)

@export var max_health: int
var current_health: int

func _ready():
	current_health = max_health

func heal_damage(amount: int):
	var previous_value := current_health
	current_health += amount
	current_health = clamp(current_health, 0, max_health)
	health_change.emit(previous_value,current_health)

func infer_damage(damage):
	var previous_value := current_health
	current_health -= damage
	health_change.emit(previous_value,current_health)
	if current_health <= 0:
		owner.die()
