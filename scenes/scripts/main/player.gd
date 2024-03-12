extends CharacterBody2D
class_name Player

# Load configuration file
var config = ConfigFile.new()
var config_load = config.load("user://config.cfg")
var toggle_mode : bool
# @onready var deadzone = config.get_value("MAIN_OPTIONS","DEADZONE") | TO DO
var primary_fire_toggled = false

# Signals
signal fire_primary(initial_position) # Sends a signal to spawn projectile, as well as the coordinates of player from which the projectile should spawn relative to
signal fire_secondary(initial_position, secondary_ammo) # Also sends signal to spawn projectile as similar to primary
signal health_change(previous_value, new_value) # Notifies health change for a variety of other nodes
signal status_change
signal player_killed # Self explanatory

# Movement
const limit_offset : int = 16
var vertical_limit : Vector2
var horizontal_limit : Vector2

@onready var is_control_locked : bool = false
@onready var direction : Vector2 = Vector2.ZERO
@export var speed : float = 400
@export var max_speed_factor : float = 2
@export var acceleration = 1.1
@export var deadzone = 0.25 # Useful for controller compatibility
@export var air_friction = 0.5

@export var dash_speed : float = 2300
@export var dash_cooldown_timer : float = 2.5
@export var roll_cooldown_timer : float = 4
var dash_cooldown_factor : float = 1.0
var roll_cooldown_factor : float = 1.0

var damage_knockback : bool = false
const knockback_speed = 1200
const knockback_randomness = 0.2
const roll_timer : float = 1

# Status
@onready var stage_camera : Camera2D = $"../StageCamera"
@onready var health_component : HealthComponent = $HealthComponent
@onready var equipment_module : EquipmentModule = $EquipmentModule
@onready var hitbox_component : HitboxComponent = $HitboxComponent
@onready var animation_tree = $PlayerAnimationTree

# Control booleans
var primary_fire_cooldown : bool = false
var secondary_fire_cooldown : bool = false
var dash_cooldown : bool = false
var roll_cooldown : bool = false

## Inventory
@onready var muzzle_node = $Muzzles
@onready var main_muzzle = $Muzzles/MainMuzzle
@onready var secondary_ammo : int = equipment_module.ammo

var muzzles : Array

var primary_fire_rof : float # The rate of fire already comes with added multipliers
var set_primary_rof:
	set(value):
		primary_fire_rof = value
var secondary_fire_rof : float
var set_secondary_rof:
	set(value):
		secondary_fire_rof = value

var burst : bool = false
var burst_quantity : int = 3

# Debug
@export var debug : bool = true

func _ready():
	if config_load != OK: printerr("Config file not found | Impossible to gather crucial data, will crash the game")
	self.add_to_group('Player')
	
	# Loading config
	toggle_mode = config.get_value("MAIN_OPTIONS","TOGGLE_FIRE")
	Options.options_changed.connect(_on_config_changed)
	
	set_muzzles()
	set_movement_limit()

func set_muzzles():
	for m in muzzle_node.get_children():
		muzzles.append(m)

func set_movement_limit():
	vertical_limit = Vector2(
		(stage_camera.get_limit(1)) + (limit_offset),
		(stage_camera.get_limit(3)) - (limit_offset)
	)
	
	horizontal_limit = Vector2(
		(stage_camera.get_limit(0)) + (limit_offset),
		(stage_camera.get_limit(2)) - (limit_offset)
	)

func _on_config_changed(): 
	config_load = config.load("user://config.cfg")
	toggle_mode = config.get_value("MAIN_OPTIONS","TOGGLE_FIRE")

## Controls, movement and animation
func _process(delta): # Frequent listener for input with delay (weapons, items, etc.)
	if toggle_mode:
		if Input.is_action_just_pressed("shoot") and !primary_fire_toggled:
			primary_fire_toggled = true
		elif Input.is_action_just_pressed("shoot") and primary_fire_toggled:
			primary_fire_toggled = false
		
		if primary_fire_toggled: shoot_loop()
	else: # Toggle firing off
		if Input.is_action_pressed("shoot"): 
			if !primary_fire_cooldown: shoot_loop()
	
	if Input.is_action_just_pressed("bomb"):
		if secondary_ammo >= 1:
			if !secondary_fire_cooldown:
				secondary_fire_cooldown = true
				shoot_secondary()
				await get_tree().create_timer(secondary_fire_rof, false).timeout
				secondary_fire_cooldown = false
		else:
			if debug: print("No ammo left!")
	
	if Input.is_action_just_pressed("roll"):
		if !roll_cooldown:
			roll_cooldown = true
			
			hitbox_component.toggle_immunity(true)
			hitbox_component.set_collision_layer_value(1, false)
			$HunterSprites.modulate.a = 0.5
			
			# await get_tree().create_timer((roll_cooldown_timer * roll_cooldown_factor) * delta, false, true).timeout
			await get_tree().create_timer(roll_timer / roll_cooldown_factor, false).timeout
			
			hitbox_component.toggle_immunity(false)
			hitbox_component.set_collision_layer_value(1, true)
			$HunterSprites.modulate.a = 1
			
			roll_cooldown = false
	
	update_animation_state()

func _physics_process(delta): # General movement function
	if !is_control_locked:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down", deadzone)
	else:
		direction = Vector2(-0.1,0)
	velocity = velocity.lerp(direction * speed, 0.1) # Thanks DeeRaghooGames for blessing me with this secret sauce. This makes movement really smooth. 
	# Source: https://www.youtube.com/watch?v=KadtbetXTGc
	
	# Input and movement controls were based on a great tutorial video from Kaan Alpar. 
	# I've modified heavily his code and added a bunch of stuff, but some lines of code still are literally the same. 
	# It helped me a lot when I begun this project as I had no prior experience on Godot.
	# It's awesome for learning your first steps. If you're reading this file to learn directly from code, check it out:
	# Source: https://www.youtube.com/watch?v=QoNukqpolS8
	
	if Input.is_action_just_pressed("dash") and dash_cooldown == false:
		dash_cooldown = true
		$HunterSprites.modulate.g = 0.5
		$HunterSprites.modulate.b = 0.5
		var target_direction = direction.normalized()
		velocity = target_direction * dash_speed
		
		# await get_tree().create_timer((dash_cooldown_timer * dash_cooldown_factor) * delta, false, true).timeout
		await get_tree().create_timer(dash_cooldown_timer * dash_cooldown_factor, false).timeout
		
		$HunterSprites.modulate.g = 1
		$HunterSprites.modulate.b = 1
		dash_cooldown = false
		pass
	
	if damage_knockback:
		damage_knockback = false
		var random_knockback_direction = Vector2(
			randf_range(-knockback_randomness,knockback_randomness),
			randf_range(-knockback_randomness,knockback_randomness)
		)
		var target_direction = -(direction + random_knockback_direction) / 2
		velocity = target_direction * knockback_speed
	
	velocity *= 1.0 - (air_friction * delta)
	move_and_slide()
	
	global_position.y = clampf(
		global_position.y,
		vertical_limit.x, # -60,
		vertical_limit.y # 540
	)
	
	global_position.x = clampf(
		global_position.x,
		horizontal_limit.x, # 0,
		horizontal_limit.y # 960
	)

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
	
	animation_tree["parameters/Idle/blend_position"] = direction
	animation_tree["parameters/Moving/blend_position"] = direction
	animation_tree["parameters/Roll/blend_position"] = direction

## Weapon firing
func shoot_loop():
	if !primary_fire_cooldown:
		primary_fire_cooldown = true
		
		if burst:
			for n in burst_quantity:
				shoot_primary()
				await get_tree().create_timer(primary_fire_rof / 2, false).timeout
		else:
			shoot_primary()
		await get_tree().create_timer(primary_fire_rof, false).timeout
		primary_fire_cooldown = false

func shoot_primary():
	for m in muzzles:
		fire_primary.emit(m.global_position)

func shoot_secondary():
	if secondary_ammo > 0:
		if debug: print("Bomb launched! %d ammo left" % int(secondary_ammo - 1))
		fire_secondary.emit(main_muzzle, secondary_ammo) # This signal both alters the hud value and emits the projectile at the same time
	else: 
		if debug: print("No ammo left!")

## Status change listeners
func _on_ammo_changed(current_ammo, _previous_ammo):
	secondary_ammo = current_ammo

func _on_health_changed(previous_value, new_value, negative): # Relaying health value as a signal, so it can be changed in the hud
	health_change.emit(previous_value, new_value)
	if negative:
		damage_knockback = true
		stage_camera.start_shake()
	UI.UIOverlay.set_hp = new_value

## Additional controllers
func controls_lock(switch_bool): # Control lock switch
	is_control_locked = switch_bool

func death_sequence():
	# Death animation
	await get_tree().create_timer(2).timeout

func die():
	if health_component.current_health <= 0:
		controls_lock(true)
		stage_camera.config_shake(30, 6, true)
		
		primary_fire_toggled = false
		player_killed.emit()
		
		Profile.end_run(false)
		
		await death_sequence()
		queue_free()
