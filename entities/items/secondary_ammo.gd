extends Area2D

@export var ammo_quantity : int = 1
@export var item_drift : float = 1
@export var max_item_drift : float = 120

func _physics_process(delta):
	global_position.x -= item_drift * delta
	get_tree().create_tween().tween_property(self, "item_drift", max_item_drift, 3)

func _on_presence_checker_screen_exited(): # Deletes item if it goes away from the screen
	queue_free()

func _on_area_entered(area):
	if area is HitboxComponent:
		area.get_owner().equipment_module.add_ammo(ammo_quantity)
		queue_free()
