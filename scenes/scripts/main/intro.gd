extends Control

@export var intro_timer : float = 3.5
const fade_time : float = 1.5

#TODO: OUR LOGO

func _ready():
	if OS.is_debug_build(): # Skip intro when debug
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		return
	
	UI.fade('IN')
	$IntroAnimation.play('LOGO_FADE_IN')
	await get_tree().create_timer(intro_timer).timeout
	$IntroAnimation.play_backwards('LOGO_FADE_IN')
	await get_tree().create_timer(fade_time).timeout
	await UI.fade('OUT')
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
