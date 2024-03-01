extends Control

@onready var project_version = ProjectSettings.get_setting("application/config/version")
@onready var version_label = $MenuPages/CentralPage/VersionLabel
@onready var menu_pages = $MenuPages

var screen_size : Vector2
var page_position : int = 0
var page_position_offset : int = 0

func _ready():
	if UI.UIOverlay.visible: UI.UIOverlay.visible = false
	
	version_label.text = "v%s" % project_version
	screen_size = get_viewport_rect().size
	await UI.fade('IN')
	$MenuPages/CentralPage/ButtonsContainer/StartButton.grab_focus()

func set_page_position(set_position):
	page_position = set_position
	var position_tween = get_tree().create_tween()
	position_tween.tween_property(menu_pages, "position", Vector2((screen_size.x + page_position_offset) * page_position, 0), 0.95).set_trans(Tween.TRANS_EXPO)
	match set_position:
		-1: $MenuPages/LoadoutPage.set_focus()
		0: $MenuPages/CentralPage.set_focus()

## Reactive Signals
func _on_config_button_pressed():
	Options.visible = true

func _on_options_visibility_changed():
	print('Main menu recieved return from options menu')
