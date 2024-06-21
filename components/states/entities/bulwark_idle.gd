extends State

var frame_count : int = 0
var check_cooldown : int = 15
var check_available : bool = true

func enter():
	pass

func exit():
	pass

func state_physics_update(_delta : float):
	frame_count += 1
	if check_available and frame_count >= check_cooldown:
		check_available = false
		if !conditions["shield_up"]:
			transitioned.emit(self, "chargeshield")
		frame_count = 0
		check_available = true
