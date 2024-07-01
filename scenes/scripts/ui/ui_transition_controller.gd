extends CanvasLayer

const bg_forward_color : Color = Color(0.047, 0.035, 0.059)
const bg_compatibility_color : Color = Color(0.243, 0.208, 0.275)

@onready var shader = $ScreenTransition/Shader
@onready var animation_node = $ScreenTransition/FadeAnimation
@onready var fade_time : float = animation_node.current_animation_length
@export var debug : bool = false

signal fade_output(mode)

func _ready():
	## Renderer check
	var renderer = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	match renderer:
		"forward_plus": shader.material.set_shader_parameter("color", bg_forward_color)
		"gl_compatibility": shader.material.set_shader_parameter("color", bg_compatibility_color)
		_: printerr('RENDERER INVALID | Current renderer: {0}'.format({0:renderer}))

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
