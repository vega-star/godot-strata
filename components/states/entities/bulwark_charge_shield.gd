extends State

@export var shield_container : Node2D
@export var shield_spawn_marker : Marker2D

const shield_cooldown : float = 2.5
const shield_scene = preload("res://entities/enemies/bulwark_shield.tscn")

var shield : Node
var frame_count : int = 0
var check_cooldown : int = 20
var check_available : bool = true

func enter():
	if state_machine.state_conditions["shield_up"]:
		transitioned.emit(self, "idle")

func exit():
	pass

func state_physics_update(_delta : float):
	frame_count += 1
	if check_available and frame_count >= 20:
		check_available = false
		if !is_instance_valid(shield):
			transitioned.emit(self, "idle")
			state_machine.change_conditional("shield_up", false)
		
		if !state_machine.state_conditions["shield_up"]:
			await get_tree().create_timer(shield_cooldown).timeout
			spawn_shield()
		
		await get_tree().create_timer(shield_cooldown).timeout
		check_available = true

func spawn_shield():
	shield = shield_scene.instantiate()
	shield.position = shield_spawn_marker.position
	shield_container.call_deferred("add_child", shield)
	state_machine.change_conditional("shield_up", true)
