extends Area2D

signal weapon_destroyed(gun_name)

# Nodes

@export var self_sprite : Sprite2D
@export var muzzle : Marker2D
@onready var self_hitbox = $HitboxComponent
@onready var drop_component : DropComponent
@onready var combat_component : CombatComponent = $CombatComponent
@onready var health_component : HealthComponent = $HealthComponent
@onready var health_bar_component : HealthBarComponent = $HealthBarComponent
@onready var hitbox_component : HitboxComponent = $HitboxComponent
@onready var projectile_container = $TemporaryContainer

# Properties
const alpha_modulation = 0.5
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const self_scene_path = "res://entities/dummy_enemies/enemy_gun.tscn"

@onready var projectile_scene = preload("res://entities/projectiles/default_enemy_laser.tscn")
@onready var player = get_tree().get_first_node_in_group('Player')
@export var contact_damage = 1
@export var set_health_bar : bool = false
@export var rate_of_fire : float = 1
@export var rof_randomness : float = 1.15
 
var shoot_cooldown : bool = false

# Unique identifier for modularization

func _ready():
	# Default node connections
	if !self_sprite: self_sprite = $EnemySprite
	if !muzzle: muzzle = $GunMuzzle
	
	randomize()
	health_bar_component.visible = set_health_bar

func _physics_process(_delta):
	if get_tree().has_group('Player'): look_at(player.global_position)
	
	if !shoot_cooldown:
		shoot_cooldown = true
		var projectile = projectile_scene.instantiate()
		projectile.global_position = $GunMuzzle.global_position
		projectile.rotation = self.rotation
		projectile_container.call_deferred("add_child", projectile)
		var shuffle_rof = randf_range(rate_of_fire * rof_randomness, rate_of_fire / rof_randomness)
		await get_tree().create_timer(shuffle_rof).timeout
		shoot_cooldown = false

func _on_area_entered(body):
	if body is Player: # Generate damage to itself if it collides with player
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent:
		body.generate_damage(contact_damage)

func die(): # Temporarily destroys the enemy, but not really
	weapon_destroyed.emit(self)

func destroy(): # Destroys the enemy definetely
	queue_free()

func deactivate():
	self.visible = false

func reactivate():
	health_component.reset_health()
	health_component.lock_health(false)
	self.visible = true

func _on_health_component_health_change(_previous_value, _new_value, type):
	if type:
		for n in damage_effect_flicker_count:
			self_sprite.modulate = Color(0,0,0)
			await get_tree().create_timer(damage_effect_flicker).timeout
			self_sprite.modulate = Color(255,255,255)
			await get_tree().create_timer(damage_effect_flicker).timeout

