class_name HitboxComponent extends Area2D

# Main variables
@export var hitsound : AudioStream
@export var hitsound_emitter : AudioStreamPlayer2D
@export var hitbox : CollisionPolygon2D
@export var simple_hitbox : CollisionShape2D
@export var health_component : HealthComponent
@export var combat_component : CombatComponent
@export var immunity_frame_limit : int = 5

# Properties
var active_hitbox
var immunity_frames_count = 0
var is_immune : bool = false

# Toggle behaviors
@export var set_health_bar : bool = false
@export var immune_to_damage : bool = false
@export var override_max_health : int = 0

## HitboxComponent communicates with HealthComponent to react with projectiles and collision
# As this component is a Area2D with body/area signals, needs one or multiple CollisionPolygon2D/CollisionShape2D nodes to work as intended
# It also needs to have a HealthComponent tied to it to update health, or else it just detects collision

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
		# In that case, the entity is missing an 'active' hitbox.
		# Collisions still works as it inherits the child hitbox node, but will not flicker when recieving constant damage, rendering some weapons useless.
	
	if hitsound:
		hitsound_emitter.set_stream(hitsound)

func _physics_process(_delta): 
	# As it updates 60 times per second, we could calculate really short immunity frames without creating a timer node
	# This is actually recommended by Godot's documentation and works fine. Tiny timers are unreliable and inneficient.
	if immunity_frames_count < immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = true
		immunity_frames_count += 1
	
	if immunity_frames_count == immunity_frame_limit:
		if active_hitbox: active_hitbox.disabled = false
		is_immune = false

func toggle_immunity(boolean_value):
	immune_to_damage = boolean_value

func generate_damage(damage, source = null):
	if !immune_to_damage:
		if is_instance_valid(hitsound_emitter): hitsound_emitter.play()
		
		if health_component and !is_immune:
			is_immune = true
			immunity_frames_count = 0
			health_component.change_health(damage, true, source)

func die(_source): #! Should only be invoked when the component is shielding or other entity type that doesn't use any other components
	queue_free()
