class_name Enemy extends Area2D

signal enemy_died

const enemy_id = 0
const enemy_name = "enemy"
const alpha_modulation = 0.5

@export var speed = 150
@export var contact_damage = 1
@onready var self_sprite = $EnemySprite
@onready var self_hitbox = $HitboxComponent
@onready var drop_component : DropComponent
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15

func _physics_process(delta):
	global_position.x -= speed * delta

func _on_area_entered(body):
	if body is Player: # Generate damage to itself if it collides with player
		self_hitbox.generate_damage(contact_damage)
		
	if body is HitboxComponent:
		body.generate_damage(contact_damage)

func _on_visible_on_screen_notifier_2d_screen_exited(): # Deletes the enemy entity if it somehow goes beyond the left side of the screen
	queue_free()

func die(): # Entity death sequence, called by HealthComponent when health <= 0
	enemy_died.emit()
	if drop_component: await drop_component.item_dropped
	queue_free()

func _on_damage_inferred():
	for n in damage_effect_flicker_count:
		modulate = Color(0,0,0)
		await get_tree().create_timer(damage_effect_flicker).timeout
		modulate = Color(255,255,255)
		await get_tree().create_timer(damage_effect_flicker).timeout
