class_name Player extends CharacterBody2D

# Signals
signal laser_shot(laser_scene, location) # Sends a signal to spawn projectile, as well as the coordinates of player from which the projectile should spawn relative to
signal health_change(previous_value, new_value) # Notifies health change for a variety of other nodes

# Movement
@export var initial_speed : float = 1200
var speed : float = initial_speed * 10
@export var max_speed_factor : float = 2
var max_speed : float = speed * max_speed_factor
@export var acceleration = 1.1
@export var deadzone = 0.25 # Useful for controller compatibility

# Weaponry
var shoot_cooldown := false
@onready var muzzle = $Muzzle
@export var default_laser_rof = 20
	# | Laser
var laser_scene:PackedScene = load("res://entities/projectiles/default_laser.tscn") # If you change 'load' to 'preload' it corrupts the scene and inhibits you from accessing it, however the scene is still working fine, so that's weird


# Status
signal player_killed
@onready var health_component = $HealthComponent

func die(): # Emits player_killed signal
	if health_component.current_health == 0:
		print("Player killed status fired")
		player_killed.emit()
		queue_free()

func _process(delta): # Frequent listener for input with delay (weapons, items, etc.)
	if Input.is_action_pressed("shoot"):
		if !shoot_cooldown:
			shoot_cooldown = true
			shoot_primary()
			await get_tree().create_timer(default_laser_rof * delta).timeout
			shoot_cooldown = false

func _physics_process(delta): # General movement function
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	if speed >= max_speed:
		velocity = direction * max_speed * delta
	else:
		speed = speed * acceleration
		velocity = direction * speed * delta
	# print("Current speed: {0} | Current HP: {1}".format({0:velocity, 1:health_component.current_health})) # Speed and control test. Produces a lot of messages, be careful
	move_and_slide()
	
	global_position = global_position.clamp(Vector2.ZERO,get_viewport_rect().size)

func shoot_primary(): # Equipped weapon in primary.
	laser_shot.emit(laser_scene, muzzle.global_position)

func shoot_secondary(): # Equipped weapon in secondary. 
	pass

func _on_health_component_health_change(previous_value, new_value): # Relaying signal
	health_change.emit(previous_value, new_value)

# Most code is based on tutorial video from Kaan Alpar, and it's a great tutorial detailing steps of building a fully complete game. 
# Some parts that I've written are closely similar, while some others are literally the same line of code. 
# It helped me a lot when I begun this project and had no prior experience on Godot.
# It's awesome for learning, if you're reading this to learn, go check it out:
# Source: https://www.youtube.com/watch?v=QoNukqpolS8
