extends State

@export var prevent_drifting : bool = true

const enter_screen_offset : int = 150
const outside_screen_offset : int = 450
var active : bool = true

func enter():
	move(active)

func move(mode : bool):
	var entity = state_machine.entity
	var position_tween = get_tree().create_tween()
	
	if entity.drifting and prevent_drifting: entity.drifting = false
	
	if active: # Move in
		position_tween.tween_property(
			entity,
			"global_position",
			Vector2(entity.global_position.x - enter_screen_offset, entity.global_position.y),
			3
		).set_trans(Tween.TRANS_EXPO)
		await position_tween.finished
		transitioned.emit(self, "update")
	else: # Move out
		position_tween.tween_property(
			entity,
			"global_position",
			Vector2(entity.global_position.x + outside_screen_offset, entity.global_position.y),
			3
		).set_trans(Tween.TRANS_EXPO)
		await position_tween.finished
		entity.request_deletion()
	
	position_tween.kill()
