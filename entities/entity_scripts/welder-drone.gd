extends "res://entities/entity_scripts/enemy.gd"

## WELDER DRONE
# Repairs other enemies on screen, evade your attacks and sometimes do not exit the screen until finally destroyed
# This script mostly controls movement and healing gun behavior

const seek_target_cooldown : float = 5

var target : Object
var target_adquired : bool = false
var orbit : bool = false
var angle : float = 0

func _physics_process(delta):
	if target and !target_adquired:
		target_adquired = true
		if is_instance_valid(target):
			catch_orbit()
		
		await get_tree().create_timer(seek_target_cooldown).timeout
		target_adquired = false
	
	if orbit:
		var orbit_point : Vector2
		if is_instance_valid(target): 
			orbit_point = target.global_position
		else:
			orbit = false
			return
		# var angle = get_angle_to(orbit_point)
		var orbit_distance = target.self_sprite.get_rect().size / 2
		var offset = Vector2(orbit_distance.x, 0)
		# var orbit_position = orbit_point + Vector2(cos(angle), sin(angle)) * orbit_distance * (PI * delta)
		
		# look_at(orbit_point)
		# global_position = lerp(global_position, orbit_distance, 0.01)
		angle += delta
		global_transform = global_transform * Transform2D().rotated(angle).translated(offset)
	else:
		rotation_degrees = 0
	
	if drifting:
		global_position.x -= speed * delta

func _on_healing_gun_target_changed(new_target):
	target = new_target

func catch_orbit():
	pass # TODO: NOT WORKING AS INTENDED, NEED TO FIX INTERPOLATION
	# orbit = true
