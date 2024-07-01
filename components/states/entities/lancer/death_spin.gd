extends State

## Death Spin
# Rotates in the center of the screen firing the laser

@export var charge_time : float = 3
@export var spin_time : float = 8
@export var laser : RayCast2D
@export var animation_player : AnimationPlayer

const pursuit_speed : float = 1.5
const initial_rotation_speed : float = 0.2
const max_rotation_speed : float = 1.6
const speed_acceleration : float = 1.02
var rotation_speed : float = initial_rotation_speed

@onready var player = get_tree().get_first_node_in_group('player')

var entity
var player_position : Vector2
var target_angle
var rotation_lock : bool = true

func enter():
	rotation_speed = initial_rotation_speed
	
	entity = state_machine.entity
	await initiate_spin()
	transitioned.emit(self, "idle")

func exit():
	rotation_lock = false
	await get_tree().create_timer(1.5).timeout
	
	var reset_tween = get_tree().create_tween()
	reset_tween.tween_property(entity, "global_rotation_degrees", 0, 1.5).set_ease(Tween.EASE_OUT)
	laser.set_casting(false)
	animation_player.play_backwards("open_carapace")
	await get_tree().create_timer(1.5).timeout

func state_physics_update(delta : float):
	if !is_instance_valid(player): return
	
	# Move to center
	entity.global_position = lerp(entity.global_position, entity.get_viewport_rect().size / 2, (pursuit_speed / 2) * delta)
	
	# Begin rotation
	if !rotation_lock:
		if rotation_speed < max_rotation_speed: rotation_speed *= speed_acceleration
		entity.global_rotation += rotation_speed * delta
	else:
		if rotation_speed > 0: rotation_speed /= speed_acceleration
		elif rotation_speed < 0: rotation_speed = 0

func initiate_spin():
	animation_player.play("open_carapace")
	laser.charge()
	await get_tree().create_timer(charge_time, false).timeout
	
	rotation_lock = false
	await get_tree().create_timer(spin_time, false).timeout
	return
