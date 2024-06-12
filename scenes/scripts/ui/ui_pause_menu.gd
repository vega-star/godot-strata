extends CanvasLayer

signal reset_focus

var lock_pause : bool = false # Locks only input, functions can still pause/unpause game!
@export var pause_state : bool = false
@onready var unpause_button = $PauseMenu/ButtonsContainer/UnpauseButton
@onready var return_prompt = $ReturnPrompt

func _ready():
	Options.visibility_changed.connect(_on_options_visibility_changed)

func pause():
	unpause_button.grab_focus()
	pause_state = true
	
	UI.set_pause(true)
	AudioManager.set_pause(true)
	UI.UIOverlay.bars.toggle_progress_bar(true)
	show()

func unpause():
	pause_state = false
	
	UI.set_pause(false)
	AudioManager.set_pause(false)
	UI.UIOverlay.bars.toggle_progress_bar(false)
	hide()

func lock(lock_bool):
	if visible: visible = false
	lock_pause = lock_bool

func _input(_event):
	if !Options.visible and UI.UIOverlay.visible and !lock_pause: # | Only pauses game outside Options menu - prevents game unpausing during confirmation prompt
		if Input.is_action_just_pressed("pause") and !pause_state:
			pause()
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("quit") and pause_state:
			unpause()

func _on_unpause_button_pressed():
	unpause()
	reset_focus.emit()

func _on_config_button_pressed():
	Options.visible = true

func _on_return_menu_button_pressed():
	return_prompt.visible = true

func _on_confirmation_dialog_confirmed():
	get_tree().paused = false
	pause_state = false
	
	await UI.end_stage(true)
	
	UI.UIOverlay.visible = false
	LoadManager.load_scene(UI.main_menu_path)
	# get_tree().change_scene_to_file(UI.main_menu_path)
	unpause()

func _on_options_visibility_changed():
	if !Options.visible:
		unpause_button.grab_focus()
