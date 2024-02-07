extends Area2D

@export var ammo_quantity : int = 1
@export var item_drift : float = 1
@export var max_item_drift : float = 120

func _physics_process(delta):
	global_position.x -= item_drift * delta
	get_tree().create_tween().tween_property(self, "item_drift", max_item_drift, 0.999)

func _on_presence_checker_screen_exited(): # Deletes item if it goes away from the screen
	queue_free()

func _on_area_entered(area):
	print('{0} COLLIDED'.format({0:area}))
	if area is HitboxComponent:
		var equipment_module = area.get_owner().equipment_module
		# equipment_module.secondary_ammo += ammo_quantity
		equipment_module.add_ammo(ammo_quantity)
		queue_free()
