extends State

## Update
# Checks for multiple parameters and decide what to do next

@onready var healing_gun = $"../../HealingGun"
@onready var healing_state = $"../Healing"
@onready var moving_state = $"../Moving"

@export var max_updates : int = 6

const iterations_till_update_drain : int = 30
const check_cooldown : int = 5

var iterations : int = 0
var updates_left : int = max_updates
var frame_count : int = 0
var check_available : bool = true

func check_update():
	iterations += 1
	
	if !updates_left > 0:
		moving_state.active = false
		transitioned.emit(self, "moving")
	
	if healing_state.healing_left > 0 and healing_gun.lock_sucessful:
		transitioned.emit(self, "healing")
	
	if iterations >= iterations_till_update_drain:
		updates_left -= 1

func enter(): 
	updates_left -= 1
	check_update()

func exit(): pass

func state_physics_update(_delta : float):
	frame_count += 1
	if check_available and frame_count >= check_cooldown:
		check_available = false
		check_update()
		frame_count = 0
		check_available = true
