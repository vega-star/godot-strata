extends Area2D
class_name Projectile

## BASE CONSTANTS USED IN EVERY PROJECTILE
const normal_pass_add : int = 1
const shielding_pass_add : int = 10

## MAIN VARIABLES 
# Base properties that serve as a foundation to the projectile
@export_enum('Bullet', 'Laser', 'Bomb') var projectile_type = 'Bullet'
@export var debug : bool = false

@export_group("Properties")
@export var base_rate_of_fire : float = 5
@export var base_projectile_damage : int = 2
@export var base_projectile_speed : int = 1300
@export var enemy_pass_limit : int = 1
@export var max_distance = 750
@export var penetration_factor : float = 0.3
@export var damage_on_challenge : float = 1
@export var damage_on_critical : float = 2
@export var pitch_variation = 0.2

@onready var projectile_sound = $ProjectileSound

## ENVIRONMENT CONDITIONS
# PROPERTIES THAT CHANGE THROUGHOUT THE PROJECTILE LIFETIME
var initial_position : Vector2
var projectile_speed : int = base_projectile_speed
var projectile_damage : int = base_projectile_damage
var can_damage_player : bool = false # Can change if bounced off an enemy or something similar
var enemy_pass_count = 0
var enemy_name : String = "LOST PROJECTILE" # Defaults to lost projectile, but gets set during instantiation so you can see which enemy killed you (fun!)

func _ready():
	randomize()
	
	projectile_sound.set_pitch_scale(randf_range(1 - pitch_variation, 1 + pitch_variation))
	projectile_sound.play()
	
	projectile_speed = base_projectile_speed
	initial_position = global_position

func _physics_process(delta):
	global_position += Vector2(
		projectile_speed * delta,
		0
	).rotated(rotation)
	
	var distance = (global_position - initial_position).x
	if distance >= max_distance: delete_projectile()

func change_layer(layer_id : int, layer_bool : bool): set_collision_layer_value(layer_id, layer_bool)

func change_mask(mask_id : int, mask_bool : bool): set_collision_mask_value(mask_id, mask_bool)

func _on_hitbox_area_entered(area):
	var enemy : Node = area.owner
	var damage_buildup : float
	var real_damage : int
	if area is HitboxComponent:
		enemy_pass_count += normal_pass_add
		_check_pass_count()
		
		for group in enemy.get_groups():
			match group:
				'player':
					damage_buildup = 1
				'shielding', 'shield':
					damage_buildup = projectile_damage * penetration_factor
					_check_pass_count(shielding_pass_add) # Check again to stop immediately
				'miniboss', 'boss':
					damage_buildup = projectile_damage * damage_on_challenge
				'core':
					damage_buildup = projectile_damage * damage_on_critical
				_:
					damage_buildup = projectile_damage
		
		real_damage = round(damage_buildup)
		area.generate_damage(real_damage)

func _check_pass_count(add : int = 0):
	if add > 0: enemy_pass_count += add
	if enemy_pass_count >= enemy_pass_limit: delete_projectile()

func _on_outside_screen_check_exit_detected(): delete_projectile()

func delete_projectile():
	call_deferred('free')
