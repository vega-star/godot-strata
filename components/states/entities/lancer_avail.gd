extends State

## Avail
# Stop and avail - quickly choose between multiple states depending on the conditionals of the state machine and the entity itself.
# This defines most of this entity's behavior, extracted directly from hardcoded functions.
# Next enemies are much less centered in one state, but I've maintained most of its initial structure to avoid infinite refactoring.

# Lock : ARRAY / NULL = Cannot proceed with this behavior if one of the conditions in the array is active. Will ignore if it's null
# Prerequisites : DICT / NULL = Checks if certain requirements are met for this behavior to be valid. Will ignore if it's null

var entity
const behaviors : Dictionary = {
	"idle": {
		"activate": ["stop"],
		"deactivate": ["pursuit", "rotate", "charge"],
		"lock": null,
		"prerequisite": null
	},
	"movecharge": {
		"activate": ["pursuit"],
		"deactivate": ["stop"],
		"lock": null,
		"prerequisite": null
	},
	"pursuit": {
		"activate": ["pursuit"],
		"deactivate": ["stop"],
		"lock": null,
		"prerequisite": null
	},
	"pursuitcharge": {
		"activate": ["pursuit", "charge"],
		"deactivate": ["stop"],
		"lock": null,
		"prerequisite": null
	},
	"pursuitrotatecharge": {
		"activate": ["rotate", "pursuit", "charge"],
		"deactivate": ["pursuit"],
		"lock": null,
		"prerequisite": 50
	},
	"stopcharge": {
		"activate": ["stop", "charge"],
		"deactivate": ["pursuit"],
		"lock": null,
		"prerequisite": null
	},
	"deathspin": {
		"activate": ["center", "charge", "rotate"],
		"deactivate": ["stop", "pursuit"],
		"lock": null,
		"prerequisite": 70
	}
}

func _ready():
	randomize()
	entity = state_machine.entity

func enter():
	pass

func exit():
	pass

func state_update(_delta : float):
	pass

func state_physics_update(delta : float):
	# Reset position to screen center-right
	if entity:
		entity.global_position.y = lerp(entity.global_position.y, entity.get_viewport_rect().size.y / 2, entity.maneuver_speed * delta)
		entity.global_position.x = lerp(entity.global_position.x, (entity.get_viewport_rect().size.x / 4) * 3, (entity.pursuit_speed * 2) * delta)

func avail_states():
	
	if state_machine.state_conditions["static"]:
		pass
	
	if state_machine.state_conditions["pursuit"]:
		transitioned.emit(self, 'pursuit')
	
	if state_machine.state_conditions["rotate"]:
		pass
	
	if state_machine.state_conditions["charging"]:
		pass
