extends Area2D

@export var heal_value : int = 1
@export var item_drift : float = 100

func _physics_process(delta):
	global_position.x -= item_drift * delta

func _on_capsule_collided(body):
	if body == Player:
		body.health_component.change_health(heal_value, false)
		queue_free()
