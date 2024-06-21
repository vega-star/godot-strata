extends Control

signal message_displayed

const default_growth : Vector2 = Vector2(400, 120)
const growth_speed : float = 0.5
const default_timeout : float = 3
const text_dict : Dictionary = {
	0: "This is a debug message and should [b]NOT[/b] be appearing in normal gameplay",
	1: "This is message number 1.\nTest 1 successful",
	2: "Welcome! This is a simulation meant to test your movement and action.",
	3: "Press [color=#f9c22b][b][{shoot}][/b][/color] to fire the [color=#4d9be6]primary weapon[/color]. Firing can be also be toggled instead of pressed.",
	4: "Press [color=#f9c22b][b][{bomb}][/b][/color] to fire the [color=#4d9be6]secondary weapon[/color]. A red light indicator in the top right of the screen signals when you can fire again.",
	5: "Ammo is limited, but regenerates very slowly.\n\nYou can speed up the process with items.",
	6: "For mobility, you can use the afterburner pressing [color=#f9c22b][b][{dash}][/b][/color].\n\nThe trail signals when dash is available.",
	7: "You can also roll by pressing [color=#f9c22b][b][{roll}][/b][/color].\n\nRolling makes you immune but prevents you from shooting your primary weapon.",
	8: "You can also set your own keybinds in options.\n\nThe game also supports controllers, even on web!",
	9: "Sometimes [color=#ea4f36][b]Enemies[/b][/color] can also spawn from behind. A [color=#f9c22b][b]danger indicator[/b][/color] will appear on screen.",
	10: "All stages have a progress bar.\n\nSometimes the bar pauses and only resumes after completion of an event.",
	11: "Items are mostly dropped by [color=#ea4f36][b]challenging foes[/b][/color], combining them how you get stronger.",
	14: "Everything you discover in the game will be registered in the codex [currently WIP], so you can further research them and plan your future runs",
	15: "That's all for now. Thanks for playing, and good luck!"
}

@onready var message_timer = $MessageTimer
@onready var text_node = $MessageText
@onready var keybinds_dict : Dictionary = {}

@export var default_position_marker : Marker2D
var message_ready : bool = true
var message_closing : bool = false
var message_opening : bool = false

func _ready():
	load_keys()
	Options.options_changed.connect(load_keys)

func _on_message_timer_timeout():
	close_message()

func load_keys():
	for key in Options.key_dict:
		var value = Options.key_dict[key]
		var parsed_value = OS.get_keycode_string(value)
		keybinds_dict[key] = parsed_value

## FUNCTION | request_message
## text_id : String OR int 			| Can be a string or an integer ID pulling from a filled dictionary
## timeout : float 					| Time until the message closes. If it's set to 0, it will only close when called externally.
## message_position_node : Marker2D | Gets the position on which the message will spawn
## await_ready : bool				| Defaults to true. If another message is currently active, it awaits its completion than resumes normally.
func request_message(
		text_id,
		timeout : float = default_timeout,
		message_position_node : Marker2D = default_position_marker,
		new_size : Vector2 = default_growth,
		await_ready : bool = true
	):
	if !message_ready: 
		if await_ready: await message_displayed
		else: return 1
	message_ready = false
	
	if message_position_node:
		global_position = message_position_node.global_position
	
	await open_message(new_size)
	if text_id is String: manual_set_text(text_id)
	else: load_text(text_id)
	
	if timeout != 0: # If explicitly said '0', it will only close when close_message is called. Useful for custom tooltips.
		message_timer.start(timeout)

func open_message(new_size = default_growth):
	if message_closing or message_opening: return 1
	message_opening = true
	
	size = Vector2(0, 0)
	visible = true
	
	var size_tween = get_tree().create_tween()
	size_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	size_tween.tween_property(self, "size", new_size, growth_speed).as_relative().set_trans(Tween.TRANS_EXPO)
	await size_tween.finished
	size_tween.kill()
	
	message_displayed.emit()
	message_opening = false

func close_message(force_close : bool = true, speed : float = growth_speed):
	if !force_close: if message_closing or message_opening: return 1
	message_closing = true
	
	if !message_timer.is_stopped(): message_timer.stop()
	
	var size_tween = get_tree().create_tween()
	text_node.set_text("")
	size_tween = get_tree().create_tween()
	size_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	size_tween.tween_property(self, "size", Vector2(0, 0), speed).set_trans(Tween.TRANS_EXPO)
	await size_tween.finished
	size_tween.kill()
	
	visible = false
	message_ready = true
	message_closing = false

func load_text(text_id):
	var text = text_dict[text_id]
	
	text = text.format(keybinds_dict)
	
	text_node.set_text(
		"[center]{0}[/center]".format({0:text})
	)

func manual_set_text(text):
	text_node.set_text(text)
