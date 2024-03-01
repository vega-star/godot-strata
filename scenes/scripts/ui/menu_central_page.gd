extends Control

func set_focus():
	$ButtonsContainer/StartButton.grab_focus()

func _on_start_button_pressed(): # StartButton
	owner.set_page_position(-1)

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

func _on_git_hub_link_pressed():
	OS.shell_open("https://github.com/vega-star/godot-strata")
