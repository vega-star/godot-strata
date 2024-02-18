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
signal fire_primary(initial_position) # Sends a signal to spawn projectile, as well as the coordinates of player from which the projectile should spawn relative to
signal fire_secondary(initial_position, secondary_ammo) # Also sends signal to spawn projectile as similar to primary
signal health_change(previous_value, new_value) # Notifies health change for a variety of other nodes
signal player_killed # Self explanatory
signal switch_controls_lock # Useful for cutscenes, animations, or certain sequences similar

# Movement
@onready var is_control_locked : bool = false
@onready var direction : Vector2 = Vector2.ZERO
@export var speed : float = 400
@export var max_speed_factor : float = 2
@export var acceleration = 1.1
@export var deadzone = 0.25 # Useful for controller compatibility
@export var air_friction = 0.5

@export var dash_speed : float = 1200
@export var dash_cooldown_timer : float = 75
@export var roll_cooldown_timer : float = 120

# Status
@onready var health_component : HealthComponent = $HealthComponent
@onready var inventory_module : InventoryModule = $InventoryModule
@onready var equipment_module : EquipmentModule = $EquipmentModule
@onready var animation_tree = $PlayerAnimationTree

var primary_fire_cooldown : bool = false
var secondary_fire_cooldown : bool = false
var dash_cooldown : bool = false
var roll_cooldown : bool = false

# Inventory
@onready var muzzle = $Muzzles/MuzzleRightWing
@onready var secondary_ammo : int = equipment_module.secondary_ammo
var primary_fire_rof : float
var secondary_fire_rof : float

# Modifiers
@export var primary_rof_buff : float = 1
@export var secondary_rof_buff : float = 1

func _ready():
	if config_load != OK: printerr("Config file not found | Impossible to gather crucial data, will crash the game")
	self.add_to_group('Player')
	Options.options_changed.connect(_on_config_changed)

func _process(delta): # Frequent listener for input with delay (weapons, items, etc.)
	if toggle_mode == true:
		if Input.is_action_just_pressed("shoot") and primary_fire_toggled == false: primary_fire_toggled = true
		elif Input.is_action_just_pressed("shoot") and primary_fire_toggled == true: primary_fire_toggled = false
		if primary_fire_toggled == true: shoot_loop(delta)
	else:
		if Input.is_action_pressed("shoot"): shoot_loop(delta)
	
	if Input.is_action_just_pressed("bomb"):
		if secondary_ammo >= 1:
			if !secondary_fire_cooldown:
				secondary_fire_cooldown = true
				shoot_secondary()
				await get_tree().create_timer(secondary_fire_rof * delta).timeout
				secondary_fire_cooldown = false
		else:
			if debug: print("No ammo left!")
	
	if Input.is_action_just_pressed("roll"):
		if !roll_cooldown:
			print('Roll pressed')
			roll_cooldown = true
			
			$HitboxComponent/PlayerHitbox.disabled = true
			$HunterSprites.modulate.a = 0.5
			
			await get_tree().create_timer(roll_cooldown_timer * delta).timeout
			
			$HitboxComponent/PlayerHitbox.disabled = false
			$HunterSprites.modulate.a = 1
			
			roll_cooldown = false
	
	update_animation_state()

func _physics_process(delta): # General movement function
	if !is_control_locked:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	velocity = velocity.lerp(direction * speed, 0.1) # Thanks DeeRaghooGames for blessing me with this secret sauce: https://www.youtube.com/watch?v=KadtbetXTGc
	
	if Input.is_action_just_pressed("dash") and dash_cooldown == false:
		print('Dash pressed')
		dash_cooldown = true
		$HunterSprites.modulate.g = 0.5
		$HunterSprites.modulate.b = 0.5
		var target_direction = direction.normalized()
		velocity = target_direction * dash_speed
		
		await get_tree().create_timer(dash_cooldown_timer * delta).timeout
		
		$HunterSprites.modulate.g = 1
		$HunterSprites.modulate.b = 1
		dash_cooldown = false
		pass
	
	velocity *= 1.0 - (air_friction * delta)
	move_and_slide()
	
	var limit_below = Vector2(get_viewport_rect().size.x - 30, get_viewport_rect().size.y - 25)
	global_position = global_position.clamp(Vector2.ZERO,limit_below)

func update_animation_state(): 
	## AnimationTree controls learned from Chris Tutorials | source: https://www.youtube.com/watch?v=WrMORzl3g1U
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

func shoot_loop(delta):
	if !primary_fire_cooldown:
		primary_fire_cooldown = true
		shoot_primary()
		await get_tree().create_timer(primary_fire_rof * delta).timeout
		primary_fire_cooldown = false

# Equipped weapon in primary.
func shoot_primary(): 
	fire_primary.emit(muzzle.global_position)
	
# Equipped weapon in secondary. 
func shoot_secondary():
	# secondary_ammo = equipment_module.secondary_ammo
	if secondary_ammo > 0:
		if debug: print("Bomb launched! %d ammo left" % int(secondary_ammo - 1))
		fire_secondary.emit(muzzle.global_position, secondary_ammo) # This signal alters the hud value and emits the projectile at the same time
	else: if debug: print("No ammo left!")

func _on_ammo_changed(current_ammo, _previous_ammo):
	secondary_ammo = current_ammo

func _on_health_component_health_change(previous_value, new_value, _negative): # Relaying health value as a signal, so it can be changed in the hud
	health_change.emit(previous_value, new_value)

func _on_config_changed(): 
	config_load = config.load("user://config.cfg")

func _switch_controls_lock(): # Control lock switch
	if !is_control_locked: is_control_locked = true
	else: is_control_locked = false

func die():
	if health_component.current_health <= 0:
		print("Player killed status fired")
		player_killed.emit()
		queue_free()

# Most code were based on tutorial video from Kaan Alpar, and it's a great tutorial detailing steps of building a fully complete game. 
# Some parts that I've written are closely similar, while some others are literally the same line of code. 
# It helped me a lot when I begun this project for I had no prior experience on Godot.
# It's awesome for learning, if you're reading this to learn, go check it out:
# Source: https://www.youtube.com/watch?v=QoNukqpolS8
