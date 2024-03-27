extends CanvasLayer

signal retry_button_pressed()
signal exit_button_pressed()

@onready var statistics_list = $GameOverPanel/Screen/TitleBox/LayoutBox/StatisticsList
@export var active_timeout = 1.5
var player_killed_status : bool = false

func game_over_prompt(): # Toggles node visibiliy, as well as quit and reset functions.
	UI.stage_timer.paused = true # Pauses stage timer
	statistics_list.update_data()
	Profile.end_run(false)
	
	await get_tree().create_timer(active_timeout).timeout
	visible = true
	UI.PauseMenu.lock(true)
	$GameOverPanel/Screen/TitleBox/LayoutBox/TextBox/MenuButton.grab_focus()
	player_killed_status = true

func _input(_event): # Able us to use hotkeys instead of clicking the buttons, but should only work when this node is active
	if player_killed_status == true:
		if Input.is_action_just_pressed("quit"):
			_on_exit_button_pressed()
		elif Input.is_action_just_pressed("reset"):
			_on_retry_button_pressed()

func _on_retry_button_pressed(): # Reloads scene directly
	visible = false
	UI.PauseMenu.lock(false)
	
	await Profile.load_previous_data()
	statistics_list.update_data()
	get_tree().reload_current_scene()

func _on_exit_button_pressed(): # Recieves signal from 'ExitButton', goes back to main menu
	visible = false
	UI.UIOverlay.visible = false
	UI.PauseMenu.lock(false)
	
	get_tree().change_scene_to_file(UI.main_menu_path)

func _on_config_button_pressed():
	Options.visible = true

# The node order of this scene is highly inspired by a video from jmbiv, the link for it is below:
# https://www.youtube.com/watch?v=aPN7k7irDnY
