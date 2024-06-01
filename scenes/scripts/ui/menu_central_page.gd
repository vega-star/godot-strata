extends Control

const abrupt_closure_speed : float = 0.25

@onready var message_player = UI.InfoHUD.message_player

func set_focus(): $ButtonsCover/ButtonsContainer/StartButton.grab_focus()

func _ready():
	if OS.has_feature("web"): # Web patches
		$Links/ItchIoLink.visible = false
		$ButtonsCover/ButtonsContainer/QuitButton.visible = false
	
	if OS.is_debug_build():
		$ButtonsCover/ButtonsContainer/ProfileButton.disabled = false
		$ButtonsCover/ButtonsContainer/CodexButton.disabled = false
	else:
		$ButtonsCover/ButtonsContainer/ProfileButton.set_tooltip_text('W.I.P')
		$ButtonsCover/ButtonsContainer/CodexButton.set_tooltip_text('W.I.P')

func emit_button_sound(button_status):
	if button_status:
		AudioManager.emit_sound_effect(null, "error_select", false, true)
	else:
		AudioManager.emit_sound_effect(null, "select_sound_1", false, true)

func _on_start_button_pressed(): 
	message_player.close_message(true, abrupt_closure_speed)
	owner.set_page_position(-1) # Loadout

func _on_profile_button_pressed():
	message_player.close_message(true, abrupt_closure_speed)
	owner.set_page_position(1) # Profile

func _on_credits_button_pressed(): 
	message_player.close_message(true, abrupt_closure_speed)
	owner.set_page_position(1, false) # Credits

func _on_codex_button_pressed():
	message_player.close_message(true, abrupt_closure_speed)
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

## Debug sign
const message_timeout : float = 7
const message_size : Vector2 = Vector2(200,280)
const message_content : String = "You're playing an alpha version. There'll be weird things, have fun!"
func _on_sprite_zone_mouse_entered():
	message_player.request_message(
		message_content,
		message_timeout,
		$RadishHoldingSign/MessageMarker,
		message_size,
		false
	)

func _on_sprite_zone_mouse_exited():
	message_player.close_message(false)
