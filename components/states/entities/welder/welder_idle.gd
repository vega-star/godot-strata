extends State

const check_cooldown : int = 5
var frame_count : int = 0
var check_available : bool = true

func check_update():
	if !conditions["target_adquired"]: 
		transitioned.emit(self, "update")
	
	if conditions["healing_left"] <= 0:
		state_machine.change_conditional("active", false)
		transitioned.emit(self, "moving")

func enter(): 
	state_machine.change_conditional("active", true)
	check_update()

func exit(): pass

func state_physics_update(_delta : float):
	frame_count += 1
	if check_available and frame_count >= check_cooldown:
		check_available = false
		await check_update()
		frame_count = 0
		check_available = true
