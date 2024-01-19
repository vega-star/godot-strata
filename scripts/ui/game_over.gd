extends CanvasLayer

signal retry_button_pressed()
signal exit_button_pressed()

@export var active_timeout = 1.5
var player_killed_status : bool = false

func _on_player_killed(): # Toggles node visibiliy, as well as quit and reset functions.
	await get_tree().create_timer(active_timeout).timeout
	self.visible = true
	player_killed_status = true

func _input(event : InputEvent): # Able us to use hotkeys instead of clicking the buttons, but should only work when this node is active
	if player_killed_status == true:
		if Input.is_action_just_pressed("quit"):
			_on_exit_button_pressed()
		elif Input.is_action_just_pressed("reset"):
			_on_retry_button_pressed()

func _on_retry_button_pressed(): # Recieves signal from 'RetryButton', reloads tree directly
	get_tree().reload_current_scene()

func _on_exit_button_pressed(): # Recieves signal from 'ExitButton', closes the game immediately
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
	# get_tree().quit()
	# This probably isn't ideal for browser games, and it could contain a conditional to send state to 'main menu' instead

# The node order of this scene is highly inspired by a video from jmbiv, the link for it is below:
# https://www.youtube.com/watch?v=aPN7k7irDnY
