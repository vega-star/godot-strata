extends State

## Death Spin
# Rotates in the center of the screen firing the laser

const initial_rotation_speed : int = 3

@export var state_time : float = 7
@export var charge_time : float = 3
@export var laser : RayCast2D
@export var rotation_speed = initial_rotation_speed
@export var animation_player : AnimationPlayer

@onready var player = get_tree().get_first_node_in_group('player')

var entity
var player_position : Vector2
var target_angle

func enter():
	entity = state_machine.entity
	await initiate_spin()
	transitioned.emit(self, "idle")

func exit():
	laser.set_casting(false)
	animation_player.play_backwards("open_carapace")
	await get_tree().create_timer(1.5).timeout

func state_physics_update(delta : float):
	if !is_instance_valid(player): return
	entity.global_position.y = lerp(entity.global_position.y, entity.get_viewport_rect().size.y / 2, entity.maneuver_speed * delta)

func initiate_spin():
	if is_instance_valid(player): player_position = player.global_position
	
	animation_player.play("open_carapace")
	laser.charge()
	
	await get_tree().create_timer(charge_time, false).timeout
	await get_tree().create_timer(state_time, false).timeout
	return
