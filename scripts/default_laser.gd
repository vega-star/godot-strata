extends Area2D

@export var projectile_speed = 1300
@export var projectile_damage = 1

func _physics_process(delta):
	global_position.x += projectile_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area):
	if area is HitboxComponent:
		var hitbox : HitboxComponent = area
		
		area.generate_damage(projectile_damage)
		queue_free()
