extends CanvasLayer

# | Pause Menu

@export var pause_state : bool = false
@onready var return_prompt = $ReturnPrompt
@onready var screen_transition = $"../ScreenTransitionLayer/ScreenTransition"
@onready var fade_time = screen_transition.fade_time

func pause():
	$PauseMenu/ButtonsContainer/UnpauseButton.grab_focus()
	get_tree().paused = true
	pause_state = true
	show()

func unpause():
	get_tree().paused = false
	pause_state = false
	hide()

func _process(_delta):
	if Options.visible == false: # | Only pauses game outside Options menu - prevents game unpausing during confirmation prompt
		if Input.is_action_just_pressed("pause") and pause_state == false:
			pause()
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("quit") and pause_state == true:
			unpause()

func _on_unpause_button_pressed():
	unpause()

func _on_options_button_pressed():
	Options.visible = true

func _on_return_menu_button_pressed():
	return_prompt.visible = true

func _on_confirmation_dialog_confirmed():
	get_tree().paused = false
	pause_state = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
