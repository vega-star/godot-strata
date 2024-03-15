extends Area2D

@export var speed = 150
@export var contact_damage = 1
@export var self_sprite : Sprite2D
@onready var self_hitbox : HitboxComponent = $HitboxComponent

# Debug / testing
@export var bulk_updating : bool = false

func _ready():
	if !self_sprite: self_sprite = $EnemySprite

func _physics_process(delta):
	global_position.x -= speed * delta

func _on_area_entered(body):
	if body is HitboxComponent:
		body.generate_damage(contact_damage)

func _on_visible_on_screen_notifier_2d_screen_exited(): # Deletes the enemy entity if it somehow goes beyond the left side of the screen
	queue_free()
