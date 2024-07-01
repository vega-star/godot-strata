extends Projectile

## Scatter Bullet
# Decays VERY quickly after shot, shortening in both size and damage based on distance traveled
# Does at least 1 damage if hit far

const factor_from_dist : int = 10
const base_target_frames : int = 8 # 1/4 of a second

@onready var self_hitbox = $SelfHitbox
@onready var self_projectile_box = $HitboxComponent/SelfProjectileBox
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
		if projectile_damage > 1: projectile_damage -= 1
		else: 
			self_hitbox.shape.set_radius(5)
			self_projectile_box.shape.set_radius(5)
			scatter_animations.play("decayed_bullet")
		
		frames = 0
