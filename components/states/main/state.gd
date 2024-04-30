extends Node
class_name State

## State
# Serves as a template and basis for entity states, that are children to a StateMachine. 
# States are used to control enemy behavior without cluttering and hardcoding it, and can be used by multiple enemies!
# The foundations of it are explained wonderfully by Bitlytic, check its tutorial below:
# Source: https://www.youtube.com/watch?v=ow_Lum-Agbs

signal transitioned(current_state, new_state_name)

func enter():
	pass

func exit():
	pass

func state_update(_delta : float):
	pass

func state_physics_update(_delta : float):
	pass
