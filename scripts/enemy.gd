class_name Enemy extends Area2D

const alpha_modulation = 0.5

@export var speed = 150
@export var contact_damage = 1
@onready var self_sprite = $EnemySprite
@onready var self_hitbox = $HitboxComponent

func _physics_process(delta):
	global_position.x -= speed * delta

func _on_area_entered(body):
	if body.owner.get_class() == 'CharacterBody2D': # Generate damage to itself
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent: # Generate damage to the player
		body.generate_damage(contact_damage)
	
	for n in 3:
		self_sprite.modulate.a = 122
		await get_tree().create_timer(alpha_modulation).timeout
		self_sprite.modulate.a = 255

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func die():
	queue_free()
