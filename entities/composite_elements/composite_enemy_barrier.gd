extends Node2D

signal barrier_destroyed

func die():
	barrier_destroyed.emit()
	queue_free()
