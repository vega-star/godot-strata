extends Area2D

signal weapon_destroyed(gun_name)

const alpha_modulation = 0.5
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const self_scene_path = "res://entities/dummy_enemies/enemy_gun.tscn"

## Nodes
@export var deactivate_instead : bool = true
@export var override_projectile_speed : int = 620
@export var move_with_scene : bool = true
var speed = 150
@export var self_sprite : Sprite2D
@export var muzzle : Marker2D
@export var health_component : HealthComponent
@export var health_bar_component : HealthBarComponent

@onready var self_hitbox = $HitboxComponent
@onready var combat_component : CombatComponent = $CombatComponent
@onready var hitbox_component : HitboxComponent = $HitboxComponent
@onready var projectile_container = get_tree().get_first_node_in_group('ProjectileContainer')

## Properties
@export var set_health_bar : bool = false
@export var contact_damage = 1
@export var rate_of_fire : float = 1
@export var rof_randomness : float = 1.01
@onready var projectile_scene = preload("res://entities/projectiles/enemy_laser.tscn")

var shoot_cooldown : bool = false
var shoot_lock : bool = false

func _ready():
	# Default node connections
	if !health_component:
		health_component = $HealthComponent
	
	if !self_sprite: 
		self_sprite = $EnemySprite
		self_sprite.visible = true
	
	if !muzzle: muzzle = $GunMuzzle
	
	randomize()
	if health_bar_component: health_bar_component.lock_bar = set_health_bar
	
	set_timed_destroy(15)

func _physics_process(delta):
	
	if move_with_scene:
		global_position.x -= speed * delta
	
	if !shoot_cooldown and !shoot_lock:
		shoot_cooldown = true
		var projectile = projectile_scene.instantiate()
		
		projectile.global_position = $GunMuzzle.global_position
		projectile.rotation = global_rotation
		projectile.projectile_speed = override_projectile_speed
		
		if move_with_scene:
				projectile.horizontal_offset = speed
		
		if projectile_container:
			projectile_container.call_deferred("add_child", projectile)
		else:
			$TemporaryContainer.call_deferred("add_child", projectile)
		
		var shuffle_rof = randf_range(rate_of_fire * rof_randomness, rate_of_fire / rof_randomness)
		await get_tree().create_timer(shuffle_rof, false).timeout
		shoot_cooldown = false

func _on_area_entered(body):
	if body is Player: # Generate damage to itself if it collides with player
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent:
		body.generate_damage(contact_damage)

func die(): # Temporarily destroys the enemy, but not really
	if deactivate_instead: weapon_destroyed.emit(self)
	else: destroy()

func set_timed_destroy(time):
	await get_tree().create_timer(time, false).timeout
	destroy()

func destroy(): # Destroys the enemy definetely
	queue_free()

func deactivate():
	shoot_lock = true
	self.visible = false
	for n in projectile_container.get_children():
		n.queue_free()

func reactivate():
	health_component.reset_health()
	health_component.lock_health(false)
	self.visible = true
	shoot_lock = false

func _on_health_component_health_change(_previous_value, _new_value, type):
	if type:
		for n in damage_effect_flicker_count:
			self_sprite.modulate = Color(0,0,0)
			await get_tree().create_timer(damage_effect_flicker).timeout
			self_sprite.modulate = Color(255,255,255)
			await get_tree().create_timer(damage_effect_flicker).timeout

