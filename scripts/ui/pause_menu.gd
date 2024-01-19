extends Control

# | Pause Menu

var pause_state : bool = false

func _ready():
	$ButtonsContainer/UnpauseButton.grab_focus()

func _process(_delta):
	if Input.is_action_just_pressed("pause") and pause_state == false:
		get_tree().paused = true
		pause_state = true
		show()
	elif Input.is_action_just_pressed("pause") and pause_state == true:
		get_tree().paused = false
		pause_state = false
		hide()

func _on_unpause_button_pressed():
	pass # Replace with function body.

func _on_options_button_pressed():
	pass # Replace with function body.

func _on_return_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
