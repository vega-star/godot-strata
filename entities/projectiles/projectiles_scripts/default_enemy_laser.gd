extends Area2D

@export var projectile_speed = 350
@export var projectile_damage = 1

var direction : Vector2

func _physics_process(delta):
	direction = Vector2.RIGHT.rotated(rotation)
	global_position += projectile_speed * direction * delta

func _on_outside_screen_check_exit_detected():
	queue_free()

func _on_hitbox_area_entered(area):
	if area is HitboxComponent:
		area.generate_damage(projectile_damage)
		queue_free()
