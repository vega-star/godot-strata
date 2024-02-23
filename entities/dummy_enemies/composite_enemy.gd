extends Area2D

signal enemy_defeated

# Terms
# CM (Composite module) | Modular part of a composite enemy

const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const alpha_modulation = 0.5

var player_y_position : float
var weapons_dict : Dictionary
@export var speed = 150
@export var contact_damage = 1
@onready var self_sprite = $CESprite
@onready var self_hitbox = $HitboxComponent
@onready var composite_parts_root = $CompositeParts
@onready var barriers = $Barriers
@onready var player = get_tree().get_first_node_in_group('player')

# Behaviour variables
@export var debug : bool = false
var pursuit : bool = true
const base_pursuit_speed : float = 0.2
const max_pursuit_speed : float = 1
var pursuit_speed : float
var pursuit_speed_acceleration : float = 1.01

func _ready():
	pursuit_speed = base_pursuit_speed
	
	var initial_tween = get_tree().create_tween()
	initial_tween.tween_property(self, "position",Vector2(720,270),0.7)
	
	for barrier in barriers.get_children():
		barrier.shielding_destroyed.connect(update_barrier_status)
	
	for part in composite_parts_root.get_children():
		part.cm_update.connect(update_composite_status)
		part.cm_weapon_update.connect(update_weapon_status)
		weapons_dict[part.name] = {
			"active": true
		}

func _physics_process(delta):
	if is_instance_valid(player):
		player_y_position = player.global_position.y
	
	if pursuit:
		global_position.y = lerp(global_position.y, player_y_position, pursuit_speed * delta)
		clamp(global_position.y, 100, 450)
	
	if pursuit_speed < max_pursuit_speed:
		pursuit_speed *= pursuit_speed_acceleration
	
	#if laser_active:
	#	if laser_charging:
	#		pass
	pass

func _on_area_entered(body):
	if body.owner.get_class() == 'CharacterBody2D': # Generate damage to itself
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent: # Generate damage to the player
		body.generate_damage(contact_damage)

func die():
	enemy_defeated.emit()
	queue_free()

func _on_damage_inferred():
	for n in damage_effect_flicker_count:
		modulate = Color(190,190,190)
		await get_tree().create_timer(damage_effect_flicker).timeout
		modulate = Color(255,255,255)
		await get_tree().create_timer(damage_effect_flicker).timeout

func update_composite_status(part_node, status):
	match status:
		0: # CM destroyed
			part_node.queue_free()
		1: # CM nominal
			pass
		2: # CM weaponry disabled
			print('All weapons are disabled')
			pass

func update_weapon_status(part_node, is_active):
	var gun_activity_sum : int
	var gun_activity = []
	
	weapons_dict[part_node.name]["active"] = is_active
	
	for weapon in weapons_dict:
		gun_activity.append(int(weapons_dict[weapon]["active"]))
	
	for activity in gun_activity:
		gun_activity_sum += activity
	
	if gun_activity_sum == 0:
		if debug: print('No active guns detected')
	elif gun_activity_sum == gun_activity.size() / 2:
		if debug: print('Half of the guns are active')
	else:
		if debug: print('Guns appear to be nominal')

func update_barrier_status():
	# print('Barrier destroyed')
	pass

func update_shielding_status(node_id, status):
	pass
