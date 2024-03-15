class_name HitboxComponent extends Node

signal shielding_destroyed

# Linked components
@onready var hitsound_emitter = $HitsoundEmitter

@export var health_component : HealthComponent
@export var combat_component : CombatComponent

# Properties
@export var immunity_frame_limit : int = 5
@export var hitbox : CollisionPolygon2D
@export var simple_hitbox : CollisionShape2D
var active_hitbox
var immunity_frames_count = 0
var is_immune : bool = false

# Toggle behaviors
@export var set_health_bar : bool = true
@export var is_shielding : bool = false
@export var immune_to_damage : bool = false
@export var is_composite_module : bool = false
@export var override_max_health : int = 0

## HitboxComponent communicates with HealthComponent to react with projectiles and collision
# As this component is a Area2D with body/area signals, needs one or multiple CollisionPolygon2D/CollisionShape2D nodes to work as intended
# It also needs to have a HealthComponent tied to it to update health

func _ready():
	clamp(immunity_frames_count, 0, immunity_frame_limit)
	
	if override_max_health > 0:
		if !health_component: push_error('%s has override_max_health but no HealthComponent node connected. This is a node misconfiguration.' % owner.name)
		health_component.set_max_health = override_max_health
	
	# Hitbox patcher
	if hitbox:
		active_hitbox = hitbox
	elif !hitbox and simple_hitbox:
		active_hitbox = simple_hitbox
	else:
		pass
		# In that case, the entity without an active hitbox.
		# Hitbox still works as it inherits the child hitbox node, but will not flicker when recieving constant damage, rendering some weapons useless.
	
	if is_shielding:
		for child in get_children():
			if child is HealthComponent:
				health_component = child
			elif child is CollisionPolygon2D or child is CollisionShape2D:
				active_hitbox = child
		
		self.add_to_group('shielding')
	elif is_composite_module:
		var hitbox_position = get_parent().get_child_count()
		active_hitbox = get_parent().get_child(hitbox_position)

func _physics_process(_delta): # As it updates 60 times per second, we could calculate really short immunity frames without creating a timer node
	if immunity_frames_count < immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = true
		immunity_frames_count += 1
	
	if immunity_frames_count == immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = false
		is_immune = false

func toggle_immunity(boolean_value):
	immune_to_damage = boolean_value

func generate_damage(damage):
	if !immune_to_damage:
		hitsound_emitter.play()
		
		if health_component and !is_immune:
			is_immune = true
			immunity_frames_count = 0
			health_component.change_health(damage)

func die(): # Deletes itself. Should only be invoked when the component is shielding
	shielding_destroyed.emit()
	queue_free()
