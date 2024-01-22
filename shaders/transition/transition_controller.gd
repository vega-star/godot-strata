extends Control

@onready var animation_node = $FadeAnimation
@onready var fade_time : float = animation_node.current_animation_length

signal fade_output(mode)

func fade(mode):
	if mode == 'in' or mode == 'IN':
		animation_node.play('FADE')
	if mode == 'out' or mode == 'OUT':
		animation_node.play_backwards('FADE')
