extends Area2D

@onready var projectile_sound = $ProjectileSound

@export var projectile_speed = 350
@export var projectile_damage = 1
@export var horizontal_offset : float = 0
@export var pitch_variation : float = 0.09

var direction : Vector2
var is_on_screen : bool

func _ready():
	randomize()
	
	projectile_sound.set_pitch_scale(randf_range(1 - pitch_variation, 1 + pitch_variation))
	projectile_sound.play()
	
	request_deletion() # Sometimes projectiles are launched outside the screen area, so they have a certain amount of time to enter or else the object gets deleted. 
	# This saves a bit of memory, useful in long stages and web port

func _physics_process(delta):
	direction = Vector2.RIGHT.rotated(rotation)
	global_position += projectile_speed * direction * delta
	
	if horizontal_offset > 0:
		global_position.x -= horizontal_offset * delta

func request_deletion():
	await get_tree().create_timer(5).timeout
	if !is_on_screen:
		queue_free()

func _on_screen_entered():
	is_on_screen = true

func _on_outside_screen_check_exit_detected():
	is_on_screen = false
	request_deletion()

func _on_hitbox_area_entered(area):
	if area is HitboxComponent:
		area.generate_damage(projectile_damage)
		queue_free()

