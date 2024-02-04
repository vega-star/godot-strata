class_name Enemy extends Area2D

const alpha_modulation = 0.5

@export var speed = 150
@export var contact_damage = 1
@onready var self_sprite = $EnemySprite
@onready var self_hitbox = $HitboxComponent
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15

func _physics_process(delta):
	global_position.x -= speed * delta

func _on_area_entered(body):
	if body.owner.get_class() == 'CharacterBody2D': # Generate damage to itself
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent: # Generate damage to the player
		body.generate_damage(contact_damage)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func die():
	queue_free()

func _on_damage_inferred():
	for n in damage_effect_flicker_count:
		modulate = Color(0,10,10)
		await get_tree().create_timer(damage_effect_flicker).timeout
		modulate = Color(255,255,255)
		await get_tree().create_timer(damage_effect_flicker).timeout
