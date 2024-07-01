extends State

const entity_id = 'welder'
const threat_generator_group = 'threat_generator'
const reset_time : float = 2.5
const timed_hard_limit : float = 8

@export var animation_player : AnimationPlayer
@onready var threat_generator = get_tree().get_first_node_in_group(threat_generator_group)
@onready var scene_enemy_container = threat_generator.enemies_container

var entity
var strength : int
var welders : Array = []
var closing : bool = false
var position : bool = false
var reset_position : bool = false

func enter():
	entity = state_machine.entity
	randomize()
	initiate_state()
	strength = randi_range(1,3)
	await get_tree().create_timer(timed_hard_limit).timeout
	close_state()

func exit():
	if !closing: await close_state()
	return

func state_physics_update(delta):
	if position:
		entity.global_position = lerp(entity.global_position, entity.get_viewport_rect().size / 2, (entity.maneuver_speed / 2) * delta)
	elif reset_position:
		entity.global_rotation = lerp_angle(entity.global_rotation, 0, entity.maneuver_speed * delta)
		entity.global_position.y = lerp(entity.global_position.y, entity.get_viewport_rect().size.y / 2, entity.maneuver_speed * delta)
		entity.global_position.x = lerp(entity.global_position.x, (entity.get_viewport_rect().size.x / 4) * 3, (entity.maneuver_speed * 2) * delta)

func close_state():
	closing = true
	
	var turn_tween = get_tree().create_tween()
	turn_tween.tween_property(entity, "global_rotation_degrees", 0, 2.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	reset_position = true
	animation_player.play("cycle_carapace")
	await get_tree().create_timer(reset_time, false).timeout
	transitioned.emit(self, "idle")

func initiate_state():
	position = true
	closing = false
	animation_player.play("open_carapace")
	
	var turn_tween = get_tree().create_tween()
	turn_tween.tween_property(entity, "global_rotation_degrees", -90, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	await get_tree().create_timer(1).timeout
	match strength:
		1: 
			spawn_welder("center")
		2: 
			spawn_welder("middle_bottom")
			spawn_welder("middle_top")
		3:
			spawn_welder("center")
			spawn_welder("middle_bottom")
			spawn_welder("middle_top")

func spawn_welder(position_override : String):
	var rule_override : Dictionary = { "spawn_override": position_override }
	var welder = await threat_generator.generate_threat(entity_id, rule_override)
	welders.append(welder)
	welder.enemy_died.connect(check_welders)

func check_welders():
	if welders.size() == 0:
		close_state()
