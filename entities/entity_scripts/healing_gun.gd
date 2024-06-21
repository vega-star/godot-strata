extends HitboxComponent

signal focus_changed
signal target_changed(target)
signal weapon_destroyed(gun_name)

## Constants
const recent_heal_decline_factor : int = 5
const alpha_modulation = 0.5
const damage_effect_flicker_count = 3
const damage_effect_flicker = 0.15
const contact_damage = 1
const self_scene_path = "res://entities/projectiles/healing_laser.tscn"

## Properties
@export var enemy_name : String = 'default_gun'
@export var deactivate_instead : bool = false
@export var activation_time : float = 1.5
@export var self_sprite : Sprite2D
@export var reset_focus : bool = true
@export var rate_of_fire : float = 8
@export var rof_randomness : float = 1.15
@export var switch_timer : float = 2
@export var limit_angle : bool = false
@export var min_angle_limit : float = -90 # If both are positive, the angle is locked facing the player. You can test it in remote tab and tweak the values
@export var max_angle_limit : float = 90
@export var health_bar_component : HealthBarComponent

## Nodes
@onready var healing_laser = $HealingLaser
@onready var player = get_tree().get_first_node_in_group('Player')


## Behavior
@export var locked : bool = false
@export var shoot_lock : bool = false
var direction : Vector2
var target_position : Vector2
var lock_sucessful : bool = false
var locked_target
var available_targets : Array
var shoot_cooldown : bool = false

func _ready():
	# Default node connections
	if !health_component:
		health_component = $HealthComponent
	
	if override_max_health > 0:
		if !health_component: push_error('%s has override_max_health but no HealthComponent node connected. This is a node misconfiguration.' % owner.name)
		health_component.set_max_health = override_max_health
	
	if !self_sprite: push_warning('GUN WITHOUT SPRITE | INVISIBLE')
	
	randomize()
	if health_bar_component:
		health_bar_component.lock_bar = set_health_bar

func execute_reset_focus():
	focus_changed.emit()
	locked = false
	lock_sucessful = false

func _physics_process(_delta):
	if locked_target:
		if !is_instance_valid(locked_target[0]):
			execute_reset_focus()
			return
		look_at(locked_target[0].global_position)
	
	if limit_angle:
		rotation_degrees = clamp(rotation_degrees, min_angle_limit, max_angle_limit)
	
	if !locked:
		locked = true
		available_targets = []
		var enemies_on_screen = get_tree().get_nodes_in_group("enemy")
		if enemies_on_screen:
			for enemy in enemies_on_screen: # Fills an array with all the enemies on screen
				if !is_instance_valid(enemy.hitbox_component): return
				var enemy_health = enemy.hitbox_component.health_component.current_health
				var max_enemy_health = enemy.hitbox_component.health_component.max_health
				
				if enemy == self or enemy == owner: # Skip if detects itself
					pass
				elif enemy_health == max_enemy_health or !enemy.hitbox_component.combat_component.is_valid_target: 
					pass # Ignore if the entity it's already on max health or is not a valid target
				else:
					var enemy_priority : float = enemy_health / max_enemy_health
					for g in enemy.get_groups():
						match g:
							"welder": return # Prevents healing loop between healers
							"enemy": pass
							"composite_enemy": enemy_priority *= 3
							"miniboss": enemy_priority *= 5
							"boss": enemy_priority *= 10
							"unset", _: pass
					
					# If the entity has healed recently, tweak its chances to be targeted next
					if enemy.combat_component.has_healed_recently: enemy_priority /= recent_heal_decline_factor
					available_targets.append([enemy, enemy_priority])
			
			available_targets.sort_custom(func(a, b): return a[1] > b[1]) # Sorts the array from the highest priority to the lowest
			
			if available_targets.size() > 0:
				locked_target = available_targets[0] # Chooses the first target
				target_position = locked_target[0].global_position
				healing_laser.set_target(locked_target[0])
				lock_sucessful = true
				
				target_changed.emit(locked_target[0])
			else:
				await get_tree().create_timer(0.3, false).timeout
				execute_reset_focus()
	
	if !shoot_cooldown and !shoot_lock and lock_sucessful:
		shoot_cooldown = true
		
		visible = true
		healing_laser.charge()
		
		var shuffle_rof = randf_range(rate_of_fire * rof_randomness, rate_of_fire / rof_randomness)
		await get_tree().create_timer(shuffle_rof, false).timeout
		
		if is_instance_valid(locked_target[0]): # Sometimes the enemy dies before the laser is charged off
			locked_target[0].combat_component.has_healed_recently = true
		shoot_cooldown = false
		visible = false
		
		if reset_focus: execute_reset_focus()
	
	# As it updates 60 times per second, we could calculate really short immunity frames without creating a timer node
	# This is actually recommended by Godot's documentation and works fine. Tiny timers are unreliable and inneficient.
	# (DUPLICATED BECAUSE OF INHERITANCE OVERRIDE)
	if immunity_frames_count < immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = true
		immunity_frames_count += 1
	
	if immunity_frames_count == immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = false
		is_immune = false


func _on_healing_laser_target_missed(): execute_reset_focus()

func _on_area_entered(body):
	if body is Player: # Generate damage to itself if it collides with player
		hitbox_component.generate_damage(contact_damage)
	if body is HitboxComponent:
		body.generate_damage(contact_damage, self)

func die(_source): # Temporarily destroys the enemy, but not really
	if deactivate_instead: weapon_destroyed.emit(self)
	else: destroy()

func destroy(): # Destroys the enemy definetely
	queue_free()

func deactivate():
	shoot_lock = true
	self.visible = false

func reactivate():
	health_component.reset_health()
	health_component.lock_health(false)
	self.visible = true
	
	await get_tree().create_timer(activation_time).timeout
	shoot_lock = false

func _on_health_component_health_change(_previous_value, _new_value, type):
	if type:
		for n in damage_effect_flicker_count:
			self_sprite.modulate.r = Color.RED.r
			await get_tree().create_timer(damage_effect_flicker).timeout
			self_sprite.modulate.r = Color(1,1,1).r
			await get_tree().create_timer(damage_effect_flicker).timeout
