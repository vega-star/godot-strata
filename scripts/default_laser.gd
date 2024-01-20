extends Area2D

@export var projectile_speed = 1300
@export var projectile_damage = 1
@export var debug : bool = false

func _physics_process(delta):
	global_position.x += projectile_speed * delta

func _on_outside_screen_check_exit_detected():
	queue_free()

func _on_area_entered(area):
	if area is HitboxComponent:
		# var hitbox : HitboxComponent = area	
		area.generate_damage(projectile_damage)
		queue_free()
