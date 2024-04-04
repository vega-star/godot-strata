extends HitboxComponent

signal shielding_destroyed

@export var set_max_health : int

func _ready():
	health_component.set_max_health = set_max_health

func die(_source):
	shielding_destroyed.emit()
	queue_free()
