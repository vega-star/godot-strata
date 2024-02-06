extends Area2D

@export var ammo_quantity : int = 1
@export var item_drift : float = 100

func _physics_process(delta):
	global_position.x -= item_drift

func _on_capsule_collided(body):
	if body == Player:
		body.equipment_component.secondary_ammo += ammo_quantity
		queue_free()
