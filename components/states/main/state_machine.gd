extends Node
class_name StateMachine

## StateMachine
# Serves as a container for multiple states used by an entity to inherit behavior.
# It provides updates to a selected state and manages smooth transitions between them.
# The foundations of it are explained wonderfully by Bitlytic, check its tutorial below:
# Source: https://www.youtube.com/watch?v=ow_Lum-Agbs
#
# HOW TO USE:
# This state machine is modified and different from its source material, so if you're intending to use this state machine in your project, please read:
# States have 4 main functions: enter, exit, state_update, and state_physics_update
# 
# 1 - Create a state node for each desired behavior (don't forget to make the script unique or extend it!)
# 2 - Plan your behavior and create functions as desired. 
#     	If you've already created these behaviors hardcoding it in your enemy code, it's easy to extract those lines and convert into states. Try it!
# 3 - Plan your conditionals. When transitioning from a state to other, you can declare conditionals for your active state to check, and decide what to do after.
#     	Ideally, these conditionals are string keys with boolean values stored in the state_conditions dictionary.
# 4 - Be creative! You can design complex and modular behaviors to use in a variety of enemies simultaneously. (I'll make sure to leave some examples for you to try on)

@export var entity : Node
@export var initial_state : State
@export var initial_state_conditions : Dictionary
@export var debug : bool = false

var current_state : State
var state_conditions : Dictionary = initial_state_conditions
var states : Dictionary = {}

func _ready():
	if !entity: entity = owner
	
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(_on_child_transition)
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta):
	if current_state: current_state.state_update(delta)

func _physics_process(delta):
	if current_state: current_state.state_physics_update(delta)

func _on_child_transition(state, new_state_name):
	if state != current_state: return
	
	var new_state = states.get(new_state_name.to_lower())
	if !new_state: return
	if debug: print('STATE MACHINE | {0} TRANSITIONING STATE FROM {1} TO {2}'.format({0: owner.name, 1:state.name.to_lower(), 2:new_state_name}))
	
	if current_state: await current_state.exit()
	
	new_state.enter()
	current_state = new_state

func change_conditional(key, value):
	if debug: print('STATE MACHINE | {2} CONDITION CHANGED: {0} | {1}'.format({0: key, 1: value, 2: owner.name}))
	state_conditions[key] = value
