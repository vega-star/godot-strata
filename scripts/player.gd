extends CharacterBody2D
class_name Player

@export var debug : bool = true

# Signals
signal fire_primary(primary_projectile_scene, location) # Sends a signal to spawn projectile, as well as the coordinates of player from which the projectile should spawn relative to
signal fire_secondary(secondary_projectile_scene, location)
signal health_change(previous_value, new_value) # Notifies health change for a variety of other nodes

# Movement
@export var speed : float = 400
@export var max_speed_factor : float = 2
@export var acceleration = 1.1
@export var deadzone = 0.25 # Useful for controller compatibility
@export var air_friction = 0.5

var dash_cooldown : bool = false
var roll_cooldown : bool = true

@export var dash_speed : float = 1200
@export var dash_cooldown_timer : float = 1.5
@export var roll_cooldown_timer : float = 1.5

# Weapon Status
var primary_fire_cooldown : bool = false
var secondary_fire_cooldown : bool = false

@onready var muzzle = $Muzzle
@export var primary_fire_rof = 20
@export var secondary_fire_rof = 200

# Weaponry
	# | Primary
var primary_projectile_scene : PackedScene = load("res://entities/projectiles/default_laser.tscn") # If you change 'load' to 'preload' it corrupts the scene and inhibits you from accessing it, however the scene is still working fine, so that's weird
	# | Secondary
var secondary_projectile_scene : PackedScene = load("res://entities/projectiles/default_bomb.tscn")

# Status
signal player_killed
@onready var health_component = $HealthComponent

func die(): # Emits player_killed signal
	if health_component.current_health <= 0:
		print("Player killed status fired")
		player_killed.emit()
		queue_free()

func _process(delta): # Frequent listener for input with delay (weapons, items, etc.)
	if Input.is_action_pressed("shoot"):
		if !primary_fire_cooldown:
			primary_fire_cooldown = true
			shoot_primary()
			await get_tree().create_timer(primary_fire_rof * delta).timeout
			primary_fire_cooldown = false
	
	if Input.is_action_pressed("bomb"):
		if !secondary_fire_cooldown:
			secondary_fire_cooldown = true
			shoot_secondary()
			await get_tree().create_timer(secondary_fire_rof * delta).timeout
			secondary_fire_cooldown = false
	
	if Input.is_action_just_pressed("roll"):
		print('Roll pressed')
		pass

func _physics_process(delta): # General movement function
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	velocity = velocity.lerp(direction * speed, 0.1) # Thanks DeeRaghooGames for blessing me with this secret sauce: https://www.youtube.com/watch?v=KadtbetXTGc
	
	if Input.is_action_just_pressed("dash") and dash_cooldown == false:
		print('Dash pressed')
		dash_cooldown = true
		var target_direction = direction.normalized()
		velocity = target_direction * dash_speed
		await get_tree().create_timer(dash_cooldown_timer * delta).timeout
		dash_cooldown = false
		pass
	
	velocity *= 1.0 - (air_friction * delta)
	move_and_slide()
	
	global_position = global_position.clamp(Vector2.ZERO,get_viewport_rect().size)

func shoot_primary(): # Equipped weapon in primary.
	fire_primary.emit(primary_projectile_scene, muzzle.global_position)

func shoot_secondary(): # Equipped weapon in secondary. 
	fire_secondary.emit(secondary_projectile_scene, muzzle.global_position)

func _on_health_component_health_change(previous_value, new_value): # Relaying signal
	health_change.emit(previous_value, new_value)

# Most code is based on tutorial video from Kaan Alpar, and it's a great tutorial detailing steps of building a fully complete game. 
# Some parts that I've written are closely similar, while some others are literally the same line of code. 
# It helped me a lot when I begun this project and had no prior experience on Godot.
# It's awesome for learning, if you're reading this to learn, go check it out:
# Source: https://www.youtube.com/watch?v=QoNukqpolS8
