extends CanvasLayer

signal loading_screen_has_full_coverage

@onready var loading_panel = $LoadingPanel
@onready var animation_player = $LoadingPanel/AnimationPlayer
@onready var progress_bar = $LoadingPanel/ProgressBarFrame/ProgressBar

func _ready():
	_start_intro_animation()

func _update_progress_bar(new_value : float) -> void:
	progress_bar.set_value_no_signal(new_value * 100)

func _start_intro_animation():
	animation_player.play("start_load")

func _start_outro_animation():
	animation_player.play("end_load")
	UI.fade('IN')
	await animation_player.animation_finished
	queue_free()
