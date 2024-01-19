extends Control

# | Main Menu

func _ready():
	$ButtonsContainer/StartButton.grab_focus()

func _on_start_button_pressed(): # StartButton
	get_tree().change_scene_to_file("res://scenes/strata_scene.tscn")

func _on_options_button_pressed(): # OptionsButton
	Options.visible = true

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

func _on_git_hub_link_pressed():
	OS.shell_open("https://github.com/vega-star/godot-strata")
