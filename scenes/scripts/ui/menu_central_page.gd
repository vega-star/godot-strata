extends Control

func set_focus(): $ButtonsCover/ButtonsContainer/StartButton.grab_focus()

func _ready():
	if OS.has_feature("web"): $Links/ItchIoLink.visible = false
	
	if OS.is_debug_build():
		$ButtonsCover/ButtonsContainer/ProfileButton.disabled = false
		$ButtonsCover/ButtonsContainer/CodexButton.disabled = false
	else:
		$ButtonsCover/ButtonsContainer/ProfileButton.set_tooltip_text('WORK IN PROGRESS')
		$ButtonsCover/ButtonsContainer/CodexButton.set_tooltip_text('WORK IN PROGRESS')
	
	# var page_manager = get_tree().get_first_node_in_group("page_manager")
	# await page_manager.ready
	# $ItchIoLink.set_focus_neighbor(SIDE_TOP, get_path_to(page_manager.config_button))

func emit_button_sound(button_status):
	if button_status:
		AudioManager.emit_sound_effect(null, "error_select", false, true)
	else:
		AudioManager.emit_sound_effect(null, "select_sound_1", false, true)

func _on_start_button_pressed(): 
	owner.set_page_position(-1) # Loadout

func _on_profile_button_pressed(): 
	owner.set_page_position(1) # Profile

func _on_credits_button_pressed(): 
	owner.set_page_position(1, false) # Credits

func _on_codex_button_pressed(): 
	owner.set_page_position(-1, false) # Codex

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

func _on_git_hub_link_pressed():
	OS.shell_open("https://github.com/vega-star/godot-strata")

func _on_itch_io_link_pressed():
	OS.shell_open("https://nyeptun.itch.io/strata-zero")

func _on_youtube_link_pressed():
	#TODO WILL PUT YOUTUBE SERIES HERE
	#OS.shell_open("")
	pass
