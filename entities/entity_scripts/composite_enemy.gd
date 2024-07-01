extends Area2D

signal enemy_defeated
signal behavior_changed(previous_behavior, current_behavior)
signal behavior_ended

const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const alpha_modulation = 0.5

@export var enemy_name = "lancer"
@export var enemy_title = "Light Breacher"
@export var speed = 150
@export var maneuver_speed = 0.2
@export var pursuit_speed = 0.2
@export var rotation_speed = 0.9
@export var contact_damage = 1
@export var set_health_bar : bool = true
@export var animation_player : AnimationPlayer
@export var debug : bool = false

@onready var self_sprite = $CESprite
@onready var self_hitbox = $HitboxComponent
@onready var composite_parts_root = $CompositeParts
@onready var health_component = $HealthComponent
@onready var barriers = $Barriers
@onready var player = get_tree().get_first_node_in_group('player')

var weapons_dict : Dictionary

func _ready():
	var initial_tween = get_tree().create_tween()
	initial_tween.tween_property(self, "position",Vector2(720,270),0.7)
	
	for part in composite_parts_root.get_children():
		part.cm_update.connect(update_composite_status)
		part.cm_weapon_update.connect(update_weapon_status)
		weapons_dict[part.name] = {
			"node": part,
			"active": true
		}
	
	await initial_tween.finished
	initial_tween.kill()

func _on_area_entered(body):
	if body.owner.get_class() == 'CharacterBody2D': # Generate damage to itself
		self_hitbox.generate_damage(contact_damage)
	if body is HitboxComponent: # Generate damage to the player
		body.generate_damage(contact_damage)

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
	
	for weapon in weapons_dict: gun_activity.append(int(weapons_dict[weapon]["active"]))
	
	for activity in gun_activity: gun_activity_sum += activity
	
	if gun_activity_sum == 0: if debug: print('No active guns detected')
	elif gun_activity_sum == gun_activity.size() / 2: if debug: print('Half of the guns are active')
	else: if debug: print('Guns appear to be nominal')

func die(_source):
	enemy_defeated.emit()
	queue_free()
