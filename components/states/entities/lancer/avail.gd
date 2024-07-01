extends State

signal state_selected(previous_state, new_state)

## Avail
# Stop and avail - quickly choose between multiple states depending on the conditionals of the state machine and the entity itself.
# This defines most of this entity's behavior, extracted directly from hardcoded functions.
# Next enemies are much less centered in one state, but I've maintained most of its initial structure to avoid infinite refactoring.

# Lock : ARRAY / NULL = Cannot proceed with this behavior if one of the conditions in the array is active. Will ignore if it's null
# Prerequisites : DICT / NULL = Checks if certain requirements are met for this behavior to be valid. Will ignore if it's null

const timer_hardstop : float = 1.2

var entity
var previous_state : String
var states : Dictionary = {
	"idle": {
		"type": -1,
		"prerequisites": null
	},
	"avail": {
		"type": -1,
		"prerequisites": null
	},
	"pursuit": {
		"type": 1,
		"prerequisites": {
			"above_health": 80
		}
	},
	"pursuitcharge": {
		"type": 0,
		"prerequisites": null
	},
	"pursuitrotatecharge": {
		"type": 1,
		"prerequisites": { 
			"below_health": 50
		}
	},
	"stopcharge": {
		"type": 0,
		"prerequisites": { 
			"above_health": 70
		}
	},
	"pointcharge": {
		"type": 0,
		"prerequisites": null
	},
	"solicitrepair": {
		"type": 1,
		"prerequisites": { 
			"chance": 80,
			"below_health": 40
		}
	},
	"deathspin": {
		"type": 1,
		"prerequisites": { 
			"below_health": 70
		}
	}
}

func _ready():
	randomize()
	entity = state_machine.entity

func enter():
	await get_tree().create_timer(timer_hardstop).timeout
	avail()

func exit():
	pass

func state_physics_update(delta : float):
	# Reset position to screen center-right
	entity.global_position.y = lerp(entity.global_position.y, entity.get_viewport_rect().size.y / 2, (entity.maneuver_speed * 2) * delta)
	entity.global_position.x = lerp(entity.global_position.x, (entity.get_viewport_rect().size.x / 4) * 3, (entity.maneuver_speed * 2) * delta)

func avail():
	var next_state_id = randi_range(0, states.size() - 1)
	var keys = states.keys()
	var new_state = keys[next_state_id]
	
	if new_state == previous_state:
		avail()
		return
	
	match states[new_state]["type"]:
		-1: # Invalid choice | Means this state is either an initial state or an state that can only be transitioned to if a state declares it
			avail()
			return
		0: # Nominal | Normal state, will transition to it without any process
			pass
		1: # Prerequisite check | A state that needs to match its prerequisites, which will reroll if failed.
			var prerequisites : Dictionary = states[new_state]["prerequisites"]
			if prerequisites == null:
				push_warning('{1} | PREREQUISITES ARE MISSING IN {0}, ROLLING FOR OTHER STATE'.format({0:new_state, 1:entity.name}))
				avail()
				return
			
			for pr in prerequisites:
				match pr:
					"chance":
						var roll = randi_range(0, 100); if roll < prerequisites["chance"]: pass
						else: avail(); return
					"below_health":
						if entity.health_component.current_health < prerequisites["below_health"]: pass
						else: avail(); return
					"above_health":
						if entity.health_component.current_health < prerequisites["above_health"]: pass
						else: avail(); return
		_:
			push_error("Invalid type or prerequisite included in avail. Check {0} StateMachine nodes".format({0:entity.name}))
	
	state_selected.emit(previous_state, new_state)
	transitioned.emit(self, new_state)
