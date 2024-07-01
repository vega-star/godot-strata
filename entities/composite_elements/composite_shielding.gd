class_name Shielding
extends HitboxComponent

signal shielding_destroyed

@export_enum("Solid", "Energy", "Hull", "Reinforced") var barrier_type = "Solid"
@export var set_max_health : int

func _ready():
	health_component.set_max_health = set_max_health

func die(_source):
	match barrier_type:
		"Solid":
			destroy()
		"Energy":
			deactivate()
		_:
			destroy()

func destroy():
	shielding_destroyed.emit()
	queue_free()

func deactivate(reactivate_timeout : float = 0):
	if reactivate_timeout > 0: 
		await get_tree().create_timer(reactivate_timeout).timeout
		activate()

func activate():
	pass
