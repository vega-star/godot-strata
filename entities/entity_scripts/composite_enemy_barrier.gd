extends Node2D

signal barrier_destroyed

@export var set_health_bar : bool = false

func die(_source):
	barrier_destroyed.emit()
	queue_free()
