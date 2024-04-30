class_name CombatComponent extends Node

signal target_status_changed(status)
signal effect_applied(effect)
signal effect_removed(effect)

@onready var set_target:
	set(value):
		is_being_targeted = value
		target_status_changed.emit(value)
@export var is_being_targeted : bool = false
var is_valid_target : bool = true
var has_healed_recently : bool = false

# Other variables
@export var debug : bool = false

func _on_target_status_changed(status):
	if status:
		if debug: print('Target adquired on %s' % owner.name)

func apply_effect(effect_type, duration, strength):
	match effect_type:
		"stasis":
			pass
		"fire":
			pass
		"energy":
			pass
		"gravity":
			pass
