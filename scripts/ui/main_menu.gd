extends Control

@onready var transition_layer = $ScreenTransitionLayer
@onready var transition_time = transition_layer.fade_time
@onready var project_version = ProjectSettings.get_setting("application/config/version")
@onready var version_label = $VersionLabel

# | Main Menu

func _ready():
	transition_layer.visible = true
	version_label.text = "v%s" % project_version
	
	transition_layer.fade('IN')
	await get_tree().create_timer(transition_time).timeout
	$ButtonsContainer/StartButton.grab_focus()
	transition_layer.visible = false

func _on_start_button_pressed(): # StartButton
	transition_layer.fade('OUT')
	transition_layer.visible = true
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
