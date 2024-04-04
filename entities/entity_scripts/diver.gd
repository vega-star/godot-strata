extends "res://entities/entity_scripts/wingman.gd"

## Main variables
@onready var charge = $Charge

@export var initial_speed : float = 1
@export var max_entity_speed : float = 3
@export var entity_acceleration : int = 2
@export var timeout_for_flee : float = 7
@export var wait_for_activation : bool = false
@export var max_maneuverability : float = 3
@export var lock_on_player : bool = false

const flee_maneuverability : float = 0.32
const lock_cooldown : float = 0.3

var player
var target_position
var entity_speed : float
var maneuverability : float = 0.5
var locked : bool
var lock_sucessful : bool

# Behavior controllers
var active : bool = false

## Diver behavior
# Almost the same as the enemy_missile script, but with sufficient changes to be another one entirely
func _ready():
	if wait_for_activation:
		set_physics_process(false)
	else:
		activate()

func activate():
	charge.start(timeout_for_flee)
	charge.connect("timeout", _on_charge_timeout)
	
	set_physics_process(true)
	active = true
	
	var speed_tween = get_tree().create_tween()
	speed_tween.tween_property(self, "entity_speed", max_entity_speed, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await speed_tween.finished

func _physics_process(delta):
	## Targeting
	if !locked and lock_on_player:
		locked = true
		player = get_tree().get_first_node_in_group("player")
		if player:
			var distance_to_player = player.global_position.distance_to(self.global_position)
			
			if player.combat_component: 
				player.combat_component.is_being_targeted = true
			
			lock_sucessful = true
		else:
			await get_tree().create_timer(lock_cooldown).timeout
			locked = false
	elif !lock_on_player:
		global_rotation = lerp_angle(self.global_rotation, 180, maneuverability * delta)
	
	## Guidance
	if lock_sucessful: # Targed adquired
		if is_instance_valid(player): 
			target_position = player.global_position
			var target_angle = (target_position - self.global_position).angle()
			global_rotation = lerp_angle(self.global_rotation, target_angle, maneuverability * delta)
		else: # Target adquired, but lost. Will try to find another target
			locked = false
			lock_sucessful = false
	
	## Acceleration
	if entity_speed < max_entity_speed:
		entity_speed *= 1.02
	
	## Behavior
	if active:
		# Active when enemy is actively attacking/pursuiting the player
		if maneuverability < max_maneuverability:
			maneuverability *= 1.05
	else:
		# Presence charge is empty and the enemy should flee the screen
		global_rotation = lerp_angle(self.global_rotation, 180, flee_maneuverability * delta) # Locks on to the left of the screen
	
	## Movement
	global_position += Vector2(2, 0).rotated(rotation) * entity_speed # Moves the entity forward

func _on_charge_timeout():
	active = false
	maneuverability = 0
