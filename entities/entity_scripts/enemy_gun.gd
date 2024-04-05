extends HitboxComponent

signal weapon_destroyed(gun_name)

## Constants
const alpha_modulation = 0.5
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const contact_damage = 1
const self_scene_path = "res://entities/prototype_entities/enemy_gun.tscn"

## Properties
@export var enemy_name : String = 'default_gun'
@export var projectile_id : String = "default_enemy_laser"
@export var deactivate_instead : bool = false
@export var activation_time : float = 2.5
@export var self_sprite : Sprite2D
@export var muzzle : Marker2D
@export var rate_of_fire : float = 1
@export var rof_randomness : float = 1.15
@export var temporary_container : Node2D
@export var switch_from_temporary : bool = false
@export var switch_timer : float = 2
@export var limit_angle : bool = false
@export var min_angle_limit : float = -90 # If both are positive, the angle is locked facing the player. You can test it in remote tab and tweak the values
@export var max_angle_limit : float = 90
@export var health_bar_component : HealthBarComponent
@export var hitbox_component : HitboxComponent = self

## Nodes
@onready var projectile_container = get_tree().get_first_node_in_group('ProjectileContainer')
@onready var projectile_scene = load("res://entities/projectiles/%s.tscn" % projectile_id)
@onready var player = get_tree().get_first_node_in_group('Player')

## Behavior
var shoot_cooldown : bool = false
var shoot_lock : bool = true

func _ready():
	# Default node connections
	if !health_component:
		health_component = $HealthComponent
	
	if override_max_health > 0:
		if !health_component: push_error('%s has override_max_health but no HealthComponent node connected. This is a node misconfiguration.' % owner.name)
		health_component.set_max_health = override_max_health
	
	if !self_sprite: push_warning('GUN WITHOUT SPRITE | INVISIBLE')
	if !muzzle: push_error('GUN WITHOUT MUZZLE | CANNOT SPAWN PROJECTILE')
	
	randomize()
	if health_bar_component:
		health_bar_component.lock_bar = set_health_bar
	
	## Await to get ready
	await get_tree().create_timer(activation_time).timeout
	shoot_lock = false

func _physics_process(_delta):
	if get_tree().has_group('Player'): 
		look_at(player.global_position)
	
	if limit_angle:
		rotation_degrees = clamp(rotation_degrees, min_angle_limit, max_angle_limit)
	
	if !shoot_cooldown and !shoot_lock:
		shoot_cooldown = true
		var projectile = projectile_scene.instantiate()
		projectile.global_position = muzzle.global_position
		projectile.rotation = global_rotation
		
		if switch_from_temporary:
			temporary_container.call_deferred("add_child", projectile)
			await get_tree().create_timer(switch_timer).timeout
			if is_instance_valid(projectile): projectile.reparent(projectile_container)
		else:
			projectile_container.call_deferred("add_child", projectile)
		
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
