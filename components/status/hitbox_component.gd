class_name HitboxComponent extends Node

@export var health_component : HealthComponent

@export var immunity_frame_limit : int = 5
var immunity_frames_count = 0
var is_immune : bool = false

## HitboxComponent communicates with HealthComponent to react with projectiles and collision
# When this component is present in an entity scene, it needs a unique CollisionPolygon2D/CollisionShape2D node to work properly
# It needs to have a HealthComponent appointed to it

func _ready():
	clamp(immunity_frames_count, 0, immunity_frame_limit)

func _physics_process(_delta): # As it updates 60 times per second, we could calculate really short immunity frames without creating a timer node
	immunity_frames_count += 1
	if immunity_frames_count == immunity_frame_limit:
		is_immune = false

func generate_damage(damage):
	if health_component and !is_immune:
		is_immune = true
		immunity_frames_count = 0
		health_component.change_health(damage)
