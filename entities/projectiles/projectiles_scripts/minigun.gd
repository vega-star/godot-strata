extends Area2D

const base_rate_of_fire : float = 30
@export var projectile_speed = 1300
@export var projectile_damage = 1

var enemy_pass_count = 0

# Factors and multiplyers
@export var can_damage_player : bool = false
@export var enemy_pass_limit : int = 1
var penetration_factor : float = 0.5
var damage_factor_against_bosses : float = 1
var critical_damage_factor : float = 2

@export var debug : bool = false

func _physics_process(delta):
	global_position.x += projectile_speed * delta

func _on_outside_screen_check_exit_detected():
	queue_free()

func _on_hitbox_area_entered(area):
	var damage_buildup : float
	var real_damage : int
	if area is HitboxComponent:
		
		enemy_pass_count += 1
		
		for group in area.owner.get_groups():
			match group:
				'shielding':
					damage_buildup = projectile_damage * penetration_factor
				'miniboss', 'boss':
					damage_buildup = projectile_damage * damage_factor_against_bosses
				'core':
					damage_buildup = projectile_damage * critical_damage_factor
				_:
					damage_buildup = projectile_damage
		
		real_damage = int(damage_buildup)
		area.generate_damage(real_damage)
	
	if enemy_pass_count == enemy_pass_limit:
		queue_free()

