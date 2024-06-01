extends Control

const main_menu_scene = "res://scenes/ui/main_menu.tscn"

func _ready():
	Options.visibility_changed.connect(_on_options_visibility_changed)

func _on_config_button_pressed():
	Options.visible = true

func _on_options_visibility_changed():
	if !Options.visible:
		$CentralPanel/ReturnToMenu.grab_focus()

func _on_return_to_menu_pressed():
	await UI.fade('OUT')
	LoadManager.load_scene(main_menu_scene)
