extends Area2D

const base_rate_of_fire : float = 20
@export var projectile_speed = 1300
@export var projectile_damage = 1
@export var explosion_damage = 10
@export var debug : bool = false
@export var can_damage_player : bool = false
@export var enemy_pass_limit : int = 1

var enemy_pass_count = 0

func _physics_process(delta):
	global_position.x += projectile_speed * delta

func _on_outside_screen_check_exit_detected():
	queue_free()

func _on_hitbox_area_entered(area):
	if area is HitboxComponent:
		area.generate_damage(projectile_damage)
		enemy_pass_count += 1
		if enemy_pass_count == enemy_pass_limit:
			queue_free()
