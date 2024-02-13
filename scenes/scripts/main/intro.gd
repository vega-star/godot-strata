extends Control

@export var intro_timer : float = 2.5
var fade_time : float = 1.5

func _ready():
	$IntroAnimation.play('LOGO_FADE_IN')
	await get_tree().create_timer(intro_timer).timeout
	$IntroAnimation.play_backwards('LOGO_FADE_IN')
	await get_tree().create_timer(fade_time).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
