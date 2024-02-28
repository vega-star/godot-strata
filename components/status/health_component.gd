class_name HealthComponent extends Node

signal health_change(previous_value: int, new_value: int, type : bool)

@export var health_bar : HealthBarComponent
@export var max_health: int
var set_max_health:
	set(override):
		max_health = override
		current_health = override
		if health_bar: health_bar.set_health_bar_size = override
var current_health : int
var lock_health_changes : bool
var component_on_player : bool = false

## HealthComponent provides a health value for all entities and a condition on which the entity starts a death sequence

func _ready(): # Loads the max health of the entity. Can be set differently to each scene this component is instantiated
	if max_health: set_max_health = max_health
	if health_bar: health_bar.visible = true
	
	if owner is Player: component_on_player = true

func reset_health():
	var previous_value := current_health
	set_max_health = max_health
	if health_bar: health_bar.health_bar_sync = current_health
	
	health_change.emit(previous_value, current_health, false)

func change_health(amount : int, negative : bool = true):
	if !lock_health_changes:
	# Negative = By default this function cause damage, but can also be used to heal.
		var previous_value := current_health
		
		if negative: # Damaging value
			current_health -= amount
			if component_on_player: Profile.add_run_data("STATISTICS", "DAMAGE_TAKEN", amount)
		else: # Healing value, prevents health overflow, etc.
			if current_health + amount > max_health: # Patch overflow
				current_health = max_health
			else:
				current_health += amount
				if component_on_player: Profile.add_run_data("STATISTICS", "HEALTH_RECOVERED", amount)
		
		if current_health <= 0:
			lock_health_changes = true
			owner.die() # Let the owner itself execute its death sequence, including queue_free()
		
		health_change.emit(previous_value, current_health, negative)
		
		if health_bar: health_bar.visible = true # Turns the health_bar visible after the first change
		if health_bar: health_bar.health_bar_sync = current_health # Sync with health_bar ONLY if there's a health_bar node attributed

func lock_health(lock): # A switch for invulnerability
	lock_health_changes = lock
