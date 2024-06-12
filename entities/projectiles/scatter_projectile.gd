extends Projectile

## Scatter Bullet
# Decays VERY quickly after shot, shortening in both size and damage based on distance traveled

const factor_from_dist : int = 10
const base_target_frames : int = 8 # 1/4 of a second

@onready var scatter_animations = $ScatterAnimations
@onready var target_frames = base_target_frames
# @onready var target_frames = base_target_frames + (max_distance / factor_from_dist)

var frames : int = 0

func _physics_process(delta):
	global_position += Vector2(
		projectile_speed * delta,
		0
	).rotated(rotation)
	
	var distance = (global_position - initial_position).x
	if distance >= max_distance: delete_projectile()
	
	frames += 1
	if frames >= target_frames:
		if projectile_damage > 0: projectile_damage -= 1
		else: scatter_animations.play("decayed_bullet")
		
		frames = 0
