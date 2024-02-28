extends CanvasLayer

# | Pause Menu

@export var pause_state : bool = false
@onready var unpause_button = $PauseMenu/ButtonsContainer/UnpauseButton
@onready var return_prompt = $ReturnPrompt

func pause():
	unpause_button .grab_focus()
	get_tree().paused = true
	pause_state = true
	show()

func unpause():
	get_tree().paused = false
	pause_state = false
	hide()

func _process(_delta):
	if !Options.visible: # | Only pauses game outside Options menu - prevents game unpausing during confirmation prompt
		if Input.is_action_just_pressed("pause") and !pause_state:
			pause()
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("quit") and pause_state:
			unpause()

func _on_unpause_button_pressed():
	unpause()

func _on_config_button_pressed():
	Options.visible = true

func _on_return_menu_button_pressed():
	return_prompt.visible = true

func _on_confirmation_dialog_confirmed():
	get_tree().paused = false
	pause_state = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")