extends Control

@onready var project_version = ProjectSettings.get_setting("application/config/version")
@onready var version_label = $MenuPages/CentralPage/VersionLabel
@onready var menu_pages = $MenuPages

var screen_size : Vector2
var page_direction : bool
var page_position : int = 0
var page_position_offset : int = 78

const page_position_offset_x : int = 72
const page_position_offset_y : int = 81

func _ready():
	if UI.UIOverlay.visible: UI.UIOverlay.visible = false
	
	Options.visibility_changed.connect(_on_options_visibility_changed)
	
	if OS.is_debug_build():
		$MenuPages/CentralPage/ButtonsContainer/ProfileButton.disabled = false
		$MenuPages/CentralPage/ButtonsContainer/CodexButton.disabled = false
	
	version_label.text = "v%s" % project_version
	screen_size = get_viewport_rect().size
	await UI.fade('IN')
	$MenuPages/CentralPage/ButtonsContainer/StartButton.grab_focus()
	
	AudioManager.set_music("first_in_line-placeholder")

func set_focus(focus_position, direction):
	var page = get_page_from_position(focus_position, direction)
	page.set_focus()

func get_page_from_position(select_position, direction : bool) -> Node:
	var page : Node
	match direction:
		true: # Horizontal
			match select_position:
				-1: page = $MenuPages/LoadoutPage
				0: page = $MenuPages/CentralPage
				1: page = $MenuPages/LoadoutPage
		false: # Vertical
			match select_position:
				-1: page = $MenuPages/CreditsPage
				0: page = $MenuPages/CentralPage
				1: page = $MenuPages/CodexPage
	return page

func set_page_position(new_position, direction : bool = true):
	var previous_page_position = page_position
	var previous_page_direction = page_direction
	var previous_page = get_page_from_position(previous_page_position, previous_page_direction) 
	
	page_position = new_position
	page_direction = direction
	var new_page = get_page_from_position(page_position, page_direction)
	new_page.visible = true
	
	var position_tween = get_tree().create_tween()
	match page_direction:
		true: # Horizontal
			position_tween.tween_property(menu_pages, "position", Vector2((screen_size.x + page_position_offset_x) * page_position, 0), 0.95).set_trans(Tween.TRANS_EXPO)
		false: # Vertical
			position_tween.tween_property(menu_pages, "position", Vector2(0, (screen_size.y + page_position_offset_y) * page_position), 0.95).set_trans(Tween.TRANS_EXPO)
	set_focus(page_position, page_direction)
	
	await position_tween.finished
	previous_page.visible = false

## Reactive Signals
func _on_config_button_pressed():
	Options.visible = true

func _on_options_visibility_changed():
	if !Options.visible:
		set_focus(page_position, page_direction)

func _exiting_menu():
	AudioManager.set_pause(true)
