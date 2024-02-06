class_name HealthComponent extends Node

signal health_change(previous_value: int, new_value: int, type : bool)

@export var health_bar : HealthBarComponent
@export var max_health: int
var current_health: int

## HealthComponent provides a health value for all entities and a condition on which the entity starts a death sequence

func _ready(): # Loads the max health of the entity. Can be set differently to each scene this component is instantiated
	current_health = max_health
	clamp(current_health, 0, max_health) # Prevents enemy from overflowing health value
	
	if health_bar: health_bar.visible = false

func change_health(amount : int, negative : bool = true):
	# Negative = By default this function cause damage, but can also be used to heal.
	var previous_value := current_health
	
	if negative: current_health -= amount
	else: current_health += amount
	
	health_change.emit(previous_value, current_health, negative)
	
	if current_health <= 0:
		owner.die() # Let the owner itself execute queue_free() after a unique death sequence
	
	if health_bar: health_bar.visible = true # Turns the health_bar visible after the first change
	if health_bar: health_bar.health_bar_sync = current_health # Sync with health_bar ONLY if there's a health_bar node attributed
