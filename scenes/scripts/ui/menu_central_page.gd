extends Control

func set_focus(): $ButtonsContainer/StartButton.grab_focus()

func _on_start_button_pressed(): owner.set_page_position(-1) # Loadout

func _on_profile_button_pressed(): owner.set_page_position(1) # Profile

func _on_credits_button_pressed(): owner.set_page_position(1, false) # Credits

func _on_codex_button_pressed(): owner.set_page_position(-1, false) # Codex

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

func _on_git_hub_link_pressed():
	OS.shell_open("https://github.com/vega-star/godot-strata")
