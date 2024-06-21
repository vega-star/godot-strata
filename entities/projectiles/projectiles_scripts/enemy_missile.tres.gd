extends Area2D

signal bomb_exploded()

# Node connections
@onready var combat_component = $CombatComponent
@onready var hitbox_component = $HitboxComponent

# Proprieties
const base_rate_of_fire : float = 50
const self_damage : int = 1
const explosion_duration : float = 0.3
@export var projectile_damage : int = 1
@export var damages_other_enemies : bool = true
@export var immune_to_other_projectiles : bool = false
var has_exploded : bool = false
var imploding_sequence : bool = false
var returned_to_screen : bool = false

# Factors and multiplyers
var penetration_factor : float = 0.6
var damage_factor_against_bosses : float = 2
var critical_damage_factor : float = 2
var explosion_size : Vector2 = Vector2(0.903,0.903)
var hitbox_explosion_size : Vector2 = Vector2(13,13)
var set_health_bar : bool = false

# Targeting
var direction : Vector2
var target_position : Vector2
var locked : bool = false
var lock_sucessful : bool = false
var locked_target
var available_targets = []

# Movement
@export var initial_projectile_speed : float = 1
@export var projectile_max_speed : float = 5
@export var projectile_acceleration_rate = 0.2
@export var missile_maneuverability : float = 1
@export var max_maneuverability : float = 2

var projectile_speed : float = initial_projectile_speed
var stage_speed = 5

const missile_activation_delay : float = 2.5
const bomb_expansion_factor : float = 0.3
const bomb_imploding_factor : float = 0.4

func _ready():
	set_physics_process(false)	
	_initialize()

func _initialize():
	var target_position = global_position + Vector2(100, 0).rotated(rotation)
	var initial_tween : Tween
	initial_tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	initial_tween.tween_property(self, "global_position", target_position, 0.2)
	
	await initial_tween.finished
	set_physics_process(true)
	
	await get_tree().create_timer(missile_activation_delay).timeout
	
	if damages_other_enemies:
		set_collision_mask_value(2, true)
		$HitboxComponent.set_collision_mask_value(2, true)
		$HitboxComponent.set_collision_mask_value(4, true)
	
	if immune_to_other_projectiles:
		$HitboxComponent.set_collision_mask_value(3, false)

func _physics_process(delta):
	if !locked:
		locked = true
		available_targets = []
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance_to_player = player.global_position.distance_to(self.global_position)
			
			if player.combat_component: 
				player.combat_component.is_being_targeted = true
			
			available_targets.append([player, distance_to_player]) # Uses the same system of arrays. If coop is implemented in the future, this may be useful.
			
			available_targets.sort_custom(func(a, b): return a[1] < b[1]) # Sorts the array from the closest to the farthest
			
			if available_targets.size() > 0:
				locked_target = available_targets[0]
				locked_target[0].combat_component.set_target = true
				target_position = locked_target[0].global_position
				lock_sucessful = true
			else:
				await get_tree().create_timer(0.3).timeout
				locked = false
	
	if !has_exploded:
		global_position.x += projectile_speed * delta
	elif has_exploded and !imploding_sequence:
		$BombExplosionSprite.scale = $BombExplosionSprite.scale.lerp(explosion_size, bomb_expansion_factor)
		$HitboxComponent/ProjectileRadius.scale = $HitboxComponent/ProjectileRadius.scale.lerp(hitbox_explosion_size, bomb_expansion_factor)
	else:
		$BombExplosionSprite.scale = $BombExplosionSprite.scale.lerp(Vector2(0,0), bomb_imploding_factor)
		$HitboxComponent/ProjectileRadius.scale = $HitboxComponent/ProjectileRadius.scale.lerp(Vector2(0,0), bomb_imploding_factor)
	
	if lock_sucessful and !has_exploded: # Targed adquired
		if is_instance_valid(locked_target[0]): 
			target_position = locked_target[0].global_position
			var target_angle = (target_position - self.global_position).angle()
			self.global_rotation = lerp_angle(self.global_rotation, target_angle, missile_maneuverability * delta)
			self.global_position += Vector2(2, 0).rotated(rotation) * projectile_speed
		else: # Target adquired, but lost. Will try to find another target
			locked = false
			lock_sucessful = false
	elif has_exploded: # Target collided, explosion follows stage_speed
		if locked_target: # Free target lock after exploding, in case enemy isn't killed
			if is_instance_valid(locked_target[0]): locked_target[0].combat_component.set_target = false 
		
		self.global_position.x -= stage_speed
	else: # Seeking target
		self.global_position += Vector2(2, 0).rotated(rotation) * projectile_speed
	
	if missile_maneuverability < max_maneuverability:
		missile_maneuverability += 0.3
	
	if projectile_speed < projectile_max_speed:
		projectile_speed *= projectile_acceleration_rate

func _on_screen_reentered():
	returned_to_screen = true

func _on_outside_screen_check_exit_detected():
	await get_tree().create_timer(3, false).timeout
	if returned_to_screen:
		returned_to_screen = false
	else: 
		queue_free()

func die(_source):
	if !has_exploded: _bomb_exploded()

func _on_hitbox_area_entered(area): # Causes damage to where it collides. It's the small circular hitbox at the end
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
	combat_component.is_valid_target = false
	has_exploded = true
	# Switch projectile sprites / explosion sprites
	$MissileSprite.visible = false
	$BombExplosionSprite.visible = true
	$MissileTrail.emitting = false
	$ExplosionSound.play()
	
	set_deferred("$SelfProjectileBox.disabled",true)
	
	# Implode
	await get_tree().create_timer(explosion_duration, false).timeout
	imploding_sequence = true
	
	# Clear entity
	await get_tree().create_timer(0.7, false).timeout
	$BombExplosionParticles.emitting = false
	queue_free() 
