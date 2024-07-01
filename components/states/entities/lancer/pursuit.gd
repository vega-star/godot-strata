extends State

const state_timer : float = 8
const exit_timeout : float = 3
const y_clamp : Vector2 = Vector2(100, 450)
const initial_pursuit_speed : float = 0.2
const max_pursuit_speed : float = 1.5 
const default_pursuit_speed_acceleration : float = 1.02

@export_range(1, 1.5) var pursuit_speed_acceleration : float = default_pursuit_speed_acceleration

@onready var player = get_tree().get_first_node_in_group('player')

var entity
var pursuit_speed : float = initial_pursuit_speed
var stop : bool = false

func enter():
	pursuit_speed = initial_pursuit_speed
	
	entity = state_machine.entity
	await get_tree().create_timer(state_timer, false).timeout
	transitioned.emit(self, "idle")

func exit():
	stop = true
	await get_tree().create_timer(exit_timeout, false).timeout

func state_physics_update(delta):
	if !is_instance_valid(player): return
	
	if stop:
		entity.global_position.y = lerp(entity.global_position.y, entity.get_viewport_rect().size.y / 2, (entity.maneuver_speed / 2) * delta)
		entity.global_position.x = lerp(entity.global_position.x, (entity.get_viewport_rect().size.x / 4) * 3, (entity.maneuver_speed / 2) * delta)
	else:
		entity.global_position.y = lerp(entity.global_position.y, player.global_position.y, pursuit_speed * delta)
		clamp(entity.global_position.y, y_clamp.x, y_clamp.y)
		if pursuit_speed < max_pursuit_speed:
			pursuit_speed *= pursuit_speed_acceleration
