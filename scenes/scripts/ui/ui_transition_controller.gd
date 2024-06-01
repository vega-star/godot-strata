extends CanvasLayer

@onready var animation_node = $ScreenTransition/FadeAnimation
@onready var fade_time : float = animation_node.current_animation_length
@export var debug : bool = false

signal fade_output(mode)

func fade(mode):
	match mode:
		0, 'IN':
			animation_node.play('FADE')
			AudioManager.set_pause(false)
			fade_output.emit(mode)
		1, 'OUT':
			animation_node.play_backwards('FADE')
			AudioManager.set_pause(true)
			fade_output.emit(mode)
