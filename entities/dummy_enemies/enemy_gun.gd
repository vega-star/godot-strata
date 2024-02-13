extends Area2D

const enemy_id = 0
const enemy_name = "enemy"
const alpha_modulation = 0.5

@export var contact_damage = 1
@onready var self_sprite = $EnemySprite
@onready var self_hitbox = $HitboxComponent
@onready var drop_component : DropComponent
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15

@onready var projectile_scene = preload("res://entities/projectiles/default_enemy_laser.tscn")
@onready var player = get_tree().get_first_node_in_group('Player')
@onready var projectile_container = $TemporaryContainer
var shoot_cooldown : bool = false
@export var rate_of_fire : float = 1
@export var rof_randomness : float = 1.2

func _ready():
	randomize()

func _physics_process(delta):
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

func die():
	queue_free()

func _on_health_component_health_change(_previous_value, _new_value, type):
	if type:
		for n in damage_effect_flicker_count:
			self_sprite.modulate = Color(0,0,0)
			await get_tree().create_timer(damage_effect_flicker).timeout
			self_sprite.modulate = Color(255,255,255)
			await get_tree().create_timer(damage_effect_flicker).timeout

