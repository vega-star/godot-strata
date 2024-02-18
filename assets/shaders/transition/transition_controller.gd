extends CanvasLayer

@onready var animation_node = $ScreenTransition/FadeAnimation
@onready var fade_time : float = animation_node.current_animation_length
@export var debug : bool = false

signal fade_output(mode)

func fade(mode):
	if mode == 'IN':
		animation_node.play('FADE')
		fade_output.emit(mode)
	if mode == 'OUT':
		animation_node.play_backwards('FADE')
		fade_output.emit(mode)
