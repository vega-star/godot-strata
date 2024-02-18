class_name CombatComponent extends Node

signal target_status_changed(status)

@onready var set_target:
	set(value):
		is_being_targeted = value
		target_status_changed.emit(value)
@export var is_being_targeted : bool = false
@export var debug : bool = false

func _on_target_status_changed(status):
	if status:
		if debug: print('Target adquired on %s' % owner.name)
