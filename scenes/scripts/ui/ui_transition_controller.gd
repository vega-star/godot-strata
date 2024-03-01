extends CanvasLayer

@onready var animation_node = $ScreenTransition/FadeAnimation
@onready var fade_time : float = animation_node.current_animation_length
@export var debug : bool = false

signal fade_output(mode)

func fade(mode):
	match mode:
		0, 'IN':
			animation_node.play('FADE')
			fade_output.emit(mode)
		1, 'OUT':
			animation_node.play_backwards('FADE')
			fade_output.emit(mode)

func stage_completed():
	$StageCompleted.visible = true
