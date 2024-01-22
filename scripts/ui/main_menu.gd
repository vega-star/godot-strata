extends Control

@onready var transition_controller = $ScreenTransition
@onready var transition_time = transition_controller.fade_time
@onready var project_version = ProjectSettings.get_setting("application/config/version")
@onready var version_label = $VersionLabel

# | Main Menu

func _ready():
	version_label.text = "v%s" % project_version
	
	transition_controller.fade('in')
	await get_tree().create_timer(transition_time).timeout
	$ButtonsContainer/StartButton.grab_focus()
	transition_controller.visible = false

func _on_start_button_pressed(): # StartButton
	transition_controller.fade('out')
	transition_controller.visible = true
	await get_tree().create_timer(transition_time).timeout
	get_tree().change_scene_to_file("res://scenes/strata_scene.tscn")

func _on_quit_button_pressed(): # QuitButton
	get_tree().quit()

func _on_git_hub_link_pressed():
	OS.shell_open("https://github.com/vega-star/godot-strata")

func _on_config_button_pressed():
	Options.visible = true

func _on_options_visibility_changed():
	print('Main menu recieved return from options menu')
