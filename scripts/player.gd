class_name Player extends CharacterBody2D

# Signals
signal laser_shot(laser_scene, location)
signal health_change(previous_value, new_value)

# Movement
@export var max_speed : float = 500
@export var initial_speed : float = 1.5
@export var speed : float = initial_speed
@export var acceleration = 1.1
@export var deadzone = 0.25

# Weaponry
var shoot_cooldown := false
@export var default_laser_rof = 0.15
	# Laser
var laser_scene:PackedScene = load("res://entities/projectiles/default_laser.tscn") # without ':PackedScene' the entire scene corrupts and cannot be loaded, be careful!
@onready var muzzle = $Muzzle

# Status
signal player_killed
@onready var health_component = $HealthComponent

func die():
	if health_component.current_health == 0:
		print("Player killed status fired")
		player_killed.emit()
		queue_free()

func _process(_delta):
	if Input.is_action_pressed("shoot_primary"):
		if !shoot_cooldown:
			shoot_cooldown = true
			shoot_primary()
			await get_tree().create_timer(default_laser_rof).timeout
			shoot_cooldown = false

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	if speed >= max_speed:
		velocity = direction * max_speed
	else:
		speed += speed * acceleration
		velocity = direction * speed
	# print("Current speed: {0} | Current HP: {1}".format({0:velocity, 1:health_component.current_health}))
	move_and_slide()
	
	global_position = global_position.clamp(Vector2.ZERO,get_viewport_rect().size)

func shoot_primary():
	laser_shot.emit(laser_scene, muzzle.global_position)

func _on_health_component_health_change(previous_value, new_value): # Relaying signal
	health_change.emit(previous_value, new_value)
