class_name Enemy extends Area2D

@export var speed = 150
@export var contact_damage = 1

@onready var self_hitbox = $HitboxComponent

func _physics_process(delta):
	global_position.x -= speed * delta

func _on_area_entered(body):
	if body.owner.get_class() == 'CharacterBody2D':
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent:
		body.generate_damage(contact_damage)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func die():
	queue_free()
