extends CharacterBody2D
class_name Player

@export var debug : bool = true

# Load configuration file
var config = ConfigFile.new()
var config_load = config.load("user://config.cfg")
@onready var toggle_mode = config.get_value("MAIN_OPTIONS","TOGGLE_FIRE")
# @onready var deadzone = config.get_value("MAIN_OPTIONS","DEADZONE") | TO DO
var primary_fire_toggled = false

# Signals
signal fire_primary(primary_projectile_scene, location) # Sends a signal to spawn projectile, as well as the coordinates of player from which the projectile should spawn relative to
signal fire_secondary(secondary_projectile_scene, location, secondary_ammo) # Also sends signal to spawn projectile as similar to primary
signal health_change(previous_value, new_value) # Notifies health change for a variety of other nodes
signal player_killed # Self explanatory
signal lock_controls # Useful for cutscenes, animations, or similar

# Movement
@onready var is_control_locked : bool = false
@onready var direction : Vector2 = Vector2.ZERO
@export var speed : float = 400
@export var max_speed_factor : float = 2
@export var acceleration = 1.1
@export var deadzone = 0.25 # Useful for controller compatibility
@export var air_friction = 0.5

var dash_cooldown : bool = false
var roll_cooldown : bool = false

@export var dash_speed : float = 1200
@export var dash_cooldown_timer : float = 75
@export var roll_cooldown_timer : float = 120

# Weaponry
@onready var muzzle = $Muzzles/MuzzleRightWing
@onready var left_wing_muzzle = $Muzzles/MuzzleLeftWing
@export var secondary_ammo : int = 8

var primary_projectile_scene : PackedScene = load("res://entities/projectiles/default_laser.tscn")
var secondary_projectile_scene : PackedScene = load("res://entities/projectiles/default_bomb.tscn")

@export var primary_rof_buff : float = 1
@export var secondary_rof_buff : float = 1
var primary_fire_rof : float = primary_projectile_scene.instantiate().base_rate_of_fire * primary_rof_buff
var secondary_fire_rof : float = secondary_projectile_scene.instantiate().base_rate_of_fire * secondary_rof_buff

var primary_fire_cooldown : bool = false
var secondary_fire_cooldown : bool = false

# Status
@onready var health_component = $HealthComponent
@onready var animation_tree = $PlayerAnimationTree

func _ready():
	if config_load != OK: printerr("Config file not found | Impossible to gather crucial data, will crash the game")
	Options.options_changed.connect(_on_config_changed)

func _process(delta): # Frequent listener for input with delay (weapons, items, etc.)
	if toggle_mode == true:
		if Input.is_action_just_pressed("shoot") and primary_fire_toggled == false: primary_fire_toggled = true
		elif Input.is_action_just_pressed("shoot") and primary_fire_toggled == true: primary_fire_toggled = false
		if primary_fire_toggled == true:
			shoot_loop(delta)
	else:
		if Input.is_action_pressed("shoot"):
			shoot_loop(delta)
	
	if Input.is_action_just_pressed("bomb"):
		if secondary_ammo >= 1:
			if !secondary_fire_cooldown:
				if debug: print("Bomb launched! %d ammo left" % int(secondary_ammo - 1))
				secondary_fire_cooldown = true
				shoot_secondary()
				await get_tree().create_timer(secondary_fire_rof * delta).timeout
				secondary_fire_cooldown = false
				secondary_ammo -= 1
		else:
			if debug: print("No ammo left!")
	
	if Input.is_action_just_pressed("roll"):
		if !roll_cooldown:
			print('Roll pressed')
			roll_cooldown = true
			
			$HitboxComponent/PlayerHitbox.disabled = true
			$HunterSprites/HunterIdleSprite.modulate.a = 0.5
			
			await get_tree().create_timer(roll_cooldown_timer * delta).timeout
			
			$HitboxComponent/PlayerHitbox.disabled = false
			$HunterSprites/HunterIdleSprite.modulate.a = 1
			
			roll_cooldown = false
		pass
	
	update_animation_state()

func _physics_process(delta): # General movement function
	if is_control_locked == false:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
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
	
	# global_position = global_position.clamp(Vector2.ZERO,get_viewport_rect().size) # Clamps player position inside screen size
	
	var limit_below = Vector2(get_viewport_rect().size.x - 30, get_viewport_rect().size.y - 40)
	global_position = global_position.clamp(Vector2.ZERO,limit_below)

func update_animation_state(): # Learned from Chris Tutorials | source: https://www.youtube.com/watch?v=WrMORzl3g1U
	if direction == Vector2.ZERO:
		animation_tree["parameters/conditions/idle"] = true
		animation_tree["parameters/conditions/moving"] = false
	else:
		animation_tree["parameters/conditions/idle"] = false
		animation_tree["parameters/conditions/moving"] = true
	
	if Input.is_action_just_pressed("roll") and roll_cooldown == true:
		print('Roll animation')
	else:
		animation_tree["parameters/conditions/on_roll"] = false
		pass
	
	animation_tree["parameters/Idle/blend_position"] = direction
	animation_tree["parameters/Moving/blend_position"] = direction
	animation_tree["parameters/Roll/blend_position"] = direction

func die(): # Emits player_killed signal
	if health_component.current_health <= 0:
		print("Player killed status fired")
		player_killed.emit()
		queue_free()

func shoot_loop(delta):
	if !primary_fire_cooldown:
		primary_fire_cooldown = true
		shoot_primary(muzzle.global_position)
		await get_tree().create_timer(primary_fire_rof * delta).timeout
		primary_fire_cooldown = false

func shoot_primary(muzzle_position): # Equipped weapon in primary.
	fire_primary.emit(primary_projectile_scene, muzzle_position)

func shoot_secondary(): # Equipped weapon in secondary. 
	fire_secondary.emit(secondary_projectile_scene, muzzle.global_position, secondary_ammo)

func _on_health_component_health_change(previous_value, new_value): # Relaying signal
	health_change.emit(previous_value, new_value)

func _on_config_changed():
	config_load = config.load("user://config.cfg")
	toggle_mode = config.get_value("MAIN_OPTIONS","TOGGLE_FIRE")
	if debug: print("Toggled firing mode is: %s" % toggle_mode)

func _on_lock_controls(): # Control lock switch
	if is_control_locked: is_control_locked = true
	else: is_control_locked = false

# Most code is based on tutorial video from Kaan Alpar, and it's a great tutorial detailing steps of building a fully complete game. 
# Some parts that I've written are closely similar, while some others are literally the same line of code. 
# It helped me a lot when I begun this project for I had no prior experience on Godot.
# It's awesome for learning, if you're reading this to learn, go check it out:
# Source: https://www.youtube.com/watch?v=QoNukqpolS8
