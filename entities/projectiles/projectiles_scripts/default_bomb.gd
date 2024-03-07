extends Area2D

signal bomb_exploded()

const base_rate_of_fire : float = 150
@export var debug : bool = false
@export var initial_projectile_speed = 800
@export var projectile_slow_rate = 0.05

var explosion_size : Vector2 = Vector2(20,20)
var hitbox_explosion_size : Vector2 = Vector2(13,13)
@export var explosion_delay : float = 2
@export var can_damage_player : bool = false

var self_damage : int = 1
@export var projectile_damage : int = 2
var penetration_factor : float = 0.6
var damage_factor_against_bosses : float = 1
var critical_damage_factor : float = 2


var projectile_speed : int = initial_projectile_speed
var exploded_status : bool = false
var imploding_sequence : bool = false
const bomb_expansion_factor : float = 0.3
const bomb_imploding_factor : float = 0.4

func _ready():
	if can_damage_player == true:
		$HitboxComponent.set_collision_layer_value(1, true)
		$HitboxComponent.set_collision_mask_value(1, true)

func _physics_process(delta):
	projectile_speed = lerp(projectile_speed, 0, projectile_slow_rate)
	if exploded_status == false:
		global_position.x += projectile_speed * delta
	elif exploded_status == true and imploding_sequence == false:
		$BombExplosionSprite.scale = $BombExplosionSprite.scale.lerp(Vector2(1.842,1.842), bomb_expansion_factor)
		$HitboxComponent/SelfProjectileBox.scale = $HitboxComponent/SelfProjectileBox.scale.lerp(explosion_size, bomb_expansion_factor)
	else:
		$BombExplosionSprite.scale = $BombExplosionSprite.scale.lerp(Vector2(0,0), bomb_imploding_factor)
		$HitboxComponent/SelfProjectileBox.scale = $HitboxComponent/SelfProjectileBox.scale.lerp(Vector2(0,0), bomb_imploding_factor)
	
	if projectile_speed == 0:
		# await get_tree().create_timer(explosion_delay).timeout # No need, projectile lerp already gives enough time
		_bomb_exploded()

func _on_outside_screen_check_exit_detected():
	queue_free()

func _on_hitbox_area_entered(area):
	var damage_buildup : float
	var real_damage : int
	if area is HitboxComponent:
		for group in area.owner.get_groups():
			match group:
				'player': # Detects player and only works if can_damage_player is turned on
					damage_buildup = self_damage
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
		
		_bomb_exploded()

func _bomb_exploded():
	exploded_status = true
	$BombProjectileSprite.visible = false
	$BombExplosionSprite.visible = true
	
	# Activate explosion effects
	$BombExplosionParticles.emitting = true
	await get_tree().create_timer(0.5).timeout
	imploding_sequence = true
	await get_tree().create_timer(0.5).timeout
	queue_free() 
