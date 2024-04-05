extends Area2D

signal enemy_defeated
signal behavior_changed(previous_behavior, current_behavior)
signal behavior_ended

# Terms
# CM (Composite module) | Modular part of a composite enemy

const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const alpha_modulation = 0.5

var enemy_name = "composite_enemy"
var player_y_position : float
var weapons_dict : Dictionary
@export var speed = 150
@export var rotation_speed = 0.9
@export var contact_damage = 1
@export var set_health_bar : bool = true
@export var animation_player : AnimationPlayer

@onready var self_sprite = $CESprite
@onready var self_hitbox = $HitboxComponent
@onready var composite_parts_root = $CompositeParts
@onready var barriers = $Barriers
@onready var player = get_tree().get_first_node_in_group('player')

# Behavior variables
var behavior
var move_available : bool = true
var pursuit : bool = false
var stop : bool = true
var charge : bool = false
var charge_time : float = 3
var charge_cooldown : bool = false
var rotate : bool = false
var rotate_fixed : bool = false
var fixed_rotation_speed : float
var go_to_center : bool = false
const base_pursuit_speed : float = 0.2
const max_pursuit_speed : float = 1.5
var pursuit_speed : float
var pursuit_speed_acceleration : float = 1.02

@export var debug : bool = false

func _ready():
	pursuit_speed = base_pursuit_speed
	
	var initial_tween = get_tree().create_tween()
	initial_tween.tween_property(self, "position",Vector2(720,270),0.7)
	
	for part in composite_parts_root.get_children():
		part.cm_update.connect(update_composite_status)
		part.cm_weapon_update.connect(update_weapon_status)
		weapons_dict[part.name] = {
			"active": true
		}

func _physics_process(delta):
	if is_instance_valid(player):
		player_y_position = player.global_position.y
	
	if stop:
		pursuit_speed = 0.2
		global_position.y = lerp(global_position.y, get_viewport_rect().size.y / 2, pursuit_speed * delta)
		global_position.x = lerp(global_position.x, (get_viewport_rect().size.x / 4) * 3, (pursuit_speed * 2) * delta)
	elif pursuit:
		global_position.y = lerp(global_position.y, player_y_position, pursuit_speed * delta)
		clamp(global_position.y, 100, 450)
		if pursuit_speed < max_pursuit_speed:
			pursuit_speed *= pursuit_speed_acceleration
	elif go_to_center:
		global_position = lerp(global_position, get_viewport_rect().size / 2, (pursuit_speed * 2) * delta)
	
	if charge and !charge_cooldown:
		charge = false
		charge_cooldown = true
		
		animation_player.play("open_carapace")
		$Laser.charge()
		if rotate_fixed:
			await behavior_ended
		
		await get_tree().create_timer(charge_time, false).timeout
		$Laser.set_casting(false)
		charge_cooldown = false
		animation_player.play("cycle_carapace")
	
	if rotate:
		var player_position : Vector2
		if is_instance_valid(player): player_position = player.global_position
		var target_angle = (global_position - player_position).angle()
		global_rotation = lerp_angle(global_rotation, target_angle, rotation_speed * delta)
	elif rotate_fixed:
		fixed_rotation_speed = lerpf(0, 6, 0.2)
		global_rotation += fixed_rotation_speed * delta
	else:
		global_rotation = lerp_angle(global_rotation, 0, (rotation_speed * 1.5) * delta)
	
	if move_available:
		change_behavior()

var behaviors : Dictionary = {
	"KeepStatic": {
		"activate": ["stop"],
		"deactivate": ["pursuit", "rotate"],
		"activate_after_completion": null,
		"deactivate_after_completion": null,
		"period": 5,
		"after_period": 2
	},
	"NormalPursuit": {
		"activate": ["pursuit"],
		"deactivate": ["stop"],
		"activate_after_completion": null,
		"deactivate_after_completion": null,
		"period": 15,
		"after_period": 2
	},
	"StopAndCharge": {
		"activate": ["stop", "charge"],
		"deactivate": ["pursuit"],
		"activate_after_completion": null,
		"deactivate_after_completion": ["charge"],
		"period": 8,
		"after_period": 2
	},
	"PursuitAndCharge": {
		"activate": ["pursuit", "charge"],
		"deactivate": ["stop"],
		"activate_after_completion": null,
		"deactivate_after_completion": ["charge"],
		"period": 10,
		"after_period": 2
	},
	"StopRotateAndCharge": {
		"activate": ["rotate", "stop", "charge"],
		"deactivate": ["pursuit"],
		"activate_after_completion": null,
		"deactivate_after_completion": ["rotate"],
		"period": 5,
		"after_period": 2
	},
	"GoToCenterRotateAndCharge": {
		"activate": ["go_to_center", "charge", "rotate_fixed"],
		"deactivate": ["stop", "pursuit"],
		"activate_after_completion": ["stop"],
		"deactivate_after_completion": ["rotate_fixed", "go_to_center", "charge"],
		"period": 15,
		"after_period": 3,
	}
}

func change_behavior():
	move_available = false
	var next_behavior = randi_range(0, behaviors.size())
	var keys = behaviors.keys()
	
	if keys[next_behavior - 1] == behavior:
		change_behavior()
		return
	
	behavior_changed.emit(behavior, keys[next_behavior - 1])
	behavior = keys[next_behavior - 1]
	print('{0} | Current behavior: {1}'.format({0: self.name, 1: behavior}))
	
	if behaviors[behavior]["activate"]:
		for active in behaviors[behavior]["activate"]:
			toggle_behavior_variables(true, active)
	
	if behaviors[behavior]["deactivate"]:
		for deactive in behaviors[behavior]["deactivate"]:
			toggle_behavior_variables(false, deactive)
	
	print("period started")
	await get_tree().create_timer(behaviors[behavior]["period"], false).timeout
	
	if behaviors[behavior]["activate_after_completion"]:
		for active in behaviors[behavior]["activate_after_completion"]:
			toggle_behavior_variables(true, active)
	
	if behaviors[behavior]["deactivate_after_completion"]:
		for deactive in behaviors[behavior]["deactivate_after_completion"]:
			toggle_behavior_variables(false, deactive)
	
	await get_tree().create_timer(behaviors[behavior]["after_period"], false).timeout
	print("period ended")
	behavior_ended.emit()
	move_available = true

func toggle_behavior_variables(active, variable):
	match variable:
		"pursuit": pursuit = active
		"stop": stop = active
		"charge": charge = active
		"rotate": rotate = active
		"rotate_fixed": rotate_fixed = active
		"go_to_center": go_to_center = active

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

func die(_source):
	enemy_defeated.emit()
	queue_free()
