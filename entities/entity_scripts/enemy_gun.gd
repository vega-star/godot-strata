class_name Gun
extends HitboxComponent

signal weapon_destroyed(gun_name)

## Constants
const alpha_modulation : float = 0.5
const damage_effect_flicker_count : int = 3
const damage_effect_flicker : float = 0.15
const contact_damage : int = 1
const self_scene_path : String = "res://entities/prototype_entities/enemy_gun.tscn"
const alignment_collision_dict : Dictionary = {
	'Enemy Gun': {'layers' = [2], 'masks' = [1,3]},
	'Ally Gun': {'layers' = [2], 'masks' = [1,3]},
	'Player Gun': {}
}

# $HitboxComponent.set_collision_mask_value(4, true)

## Properties
@export_category('Main Configuration')
@export_enum('Enemy Gun', 'Ally Gun', 'Player Gun') var gun_alignment : String = 'Enemy Gun'
@export var enemy_name : String = 'default_gun'
@export var projectile_id : String = "enemy_laser" ## Changing this in export will also change which projectile this gun shoots entirely
@export var deactivate_instead : bool = false
@export var activation_time : float = 2.5
@export var rate_of_fire : float = 1
@export var rof_randomness : float = 1.15

@export_group('Nodes')
@export var self_sprite : Sprite2D
@export var muzzle : Marker2D
@export var temporary_container : Node2D
@export var health_bar_component : HealthBarComponent
@export var switch_from_temporary : bool = false
@export var switch_timer : float = 2

@export_group('Rotation')
@export var limit_angle : bool = false
@export_range(0,360) var min_angle_limit : float = -90 # If both are positive, the angle is locked facing the player. You can test it in remote tab and tweak the values
@export_range(0,360) var max_angle_limit : float = 90

@export_group('Charging')
@export var charge : bool = true
@export var charge_time : float = 1
@export var charge_timer : Timer
@export var charging_particles : CPUParticles2D
@export_range(0, 10) var charging_glow_strength : float = 2

## Nodes
var target : Object
@onready var detector = $Detector
@onready var detector_aim = $DetectorAim
@onready var detection_sphere = $DetectionSphere
@onready var projectile_container = get_tree().get_first_node_in_group('ProjectileContainer')
@onready var projectile_scene = load("res://entities/projectiles/%s.tscn" % projectile_id)
@onready var player = get_tree().get_first_node_in_group('Player')

## Behavior
var eligible_target : Object
var charge_configured : bool = false
var shoot_cooldown : bool = false
var shoot_lock : bool = true

func _ready():
	assert(projectile_scene)
	
	# Default node connections
	if !charge_timer: $ChargeTimer
	if !charging_particles: $ChargingParticles
	if !health_component: health_component = $HealthComponent
	
	if override_max_health > 0:
		if !health_component: push_error('%s has override_max_health but no HealthComponent node connected. This is a node misconfiguration.' % owner.name)
		health_component.set_max_health = override_max_health
	
	if !self_sprite: push_warning('GUN WITHOUT SPRITE | INVISIBLE')
	if !muzzle: push_error('GUN WITHOUT MUZZLE | CANNOT SPAWN PROJECTILE')
	if muzzle and charging_particles: charging_particles.position = muzzle.position
	
	randomize()
	if health_bar_component:
		health_bar_component.lock_bar = set_health_bar
	
	## Await to get ready
	await get_tree().create_timer(activation_time).timeout
	shoot_lock = false

func seek_target():
	match gun_alignment:
		'Enemy Gun': 
			if !is_instance_valid(player): return null
			target = player
		'Ally Gun', 'Player Gun':
			detection_sphere.visible = true
			detection_sphere.disabled = false
			await self.area_entered
			if is_instance_valid(eligible_target): target = eligible_target

func _physics_process(_delta):
	if is_instance_valid(target): look_at(target.global_position)
	else:
		seek_target()
		return
	
	if limit_angle:
		rotation_degrees = clamp(rotation_degrees, min_angle_limit, max_angle_limit)
	
	if !shoot_cooldown and !shoot_lock:
		shoot_cooldown = true
		
		var projectile = projectile_scene.instantiate()
		
		if charge and charging_particles:
			if !charge_configured:
				charge_configured = true
				charging_particles.set_modulate(projectile.get_modulate() * charging_glow_strength)
			
			charging_particles.set_emitting(true)
			charge_timer.start(charge_time)
			await charge_timer.timeout
		
		projectile.global_position = muzzle.global_position
		projectile.rotation = global_rotation
		
		if detector:
			detector.force_raycast_update()
			if detector.is_colliding(): pass
			else: 
				if charging_particles: charging_particles.set_emitting(false)
				shoot_cooldown = false
				return # Do not shoot if player is not in line of sight
		
		if switch_from_temporary:
			temporary_container.call_deferred("add_child", projectile)
			if charging_particles: charging_particles.set_emitting(false)
			await get_tree().create_timer(switch_timer).timeout
			if is_instance_valid(projectile): projectile.reparent(projectile_container)
		else:
			projectile_container.call_deferred("add_child", projectile)
			if charging_particles: charging_particles.set_emitting(false)
		
		var shuffle_rof = randf_range(rate_of_fire * rof_randomness, rate_of_fire / rof_randomness)
		await get_tree().create_timer(shuffle_rof).timeout
		shoot_cooldown = false
	
	# As it updates 60 times per second, we could calculate really short immunity frames without creating a timer node
	# This is actually recommended by Godot's documentation and works fine. Tiny timers are unreliable and inneficient.
	# (DUPLICATED BECAUSE OF INHERITANCE OVERRIDE)
	if immunity_frames_count < immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = true
		immunity_frames_count += 1
	
	if immunity_frames_count == immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = false
		is_immune = false

func _on_area_entered(body):
	if detection_sphere:
		if !detection_sphere.disabled:
			eligible_target = body
			detection_sphere.visible = false
			detection_sphere.disabled = true
			return
	
	if body is Player: # Generate damage to itself if it collides with player
		hitbox_component.generate_damage(contact_damage)
	if body is HitboxComponent:
		body.generate_damage(contact_damage, self)

func die(_source): # Temporarily destroys the enemy, but not really
	if deactivate_instead: weapon_destroyed.emit(self)
	else: destroy()

func destroy(): # Destroys the enemy definetely
	queue_free()

func deactivate():
	shoot_lock = true
	self.visible = false

func reactivate():
	health_component.reset_health()
	health_component.lock_health(false)
	self.visible = true
	
	await get_tree().create_timer(activation_time).timeout
	shoot_lock = false

func _on_health_component_health_change(_previous_value, new_value, type):
	if type:
		for n in damage_effect_flicker_count:
			self_sprite.modulate.r = Color.RED.r
			await get_tree().create_timer(damage_effect_flicker).timeout
			self_sprite.modulate.r = Color(1,1,1).r
			await get_tree().create_timer(damage_effect_flicker).timeout
