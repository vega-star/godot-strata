extends State

@export var timeout : float
@export var next_state : State

## TimedIdle
# Waits for a specific period of time before changing to an more active state

func enter():
	await get_tree().create_timer(timeout, false).timeout
	transitioned.emit(self, next_state.name)
