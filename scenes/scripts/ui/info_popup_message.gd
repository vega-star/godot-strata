extends Control

signal message_displayed

const default_growth : Vector2 = Vector2(400, 120)
const growth_speed : float = 0.5
const default_timeout : float = 3

@onready var keybinds_dict : Dictionary = {}

@onready var text_dict : Dictionary = {
	0: "This is a debug message and should [b]NOT[/b] be appearing in normal gameplay",
	1: "This is message number 1.\nTest 1 successful",
	2: "Welcome! This stage is a simulation meant to test your movement and action.",
	3: "Press [color=#f9c22b][b][{shoot}][/b][/color] to fire the [color=#4d9be6]primary weapon[/color]. Firing can be also be toggled in the configuration menu.",
	4: "Press [color=#f9c22b][b][{bomb}][/b][/color] to fire the [color=#4d9be6]secondary weapon[/color]. It consumes ammo, but deals a lot more damage.",
	5: "Ammo can be retrieved from fallen enemies, but its limited by a max amount.\n\nYou can increase it with items.",
	6: "For more mobility, you can press [color=#f9c22b][b][{dash}][/b][/color] and dash in a direction.\n\nThe trail emits a burst when it resets.",
	7: "You can also roll by pressing [color=#f9c22b][b][{roll}][/b][/color] and evade projectiles and collisions.\n\nIt also can be used simultaneously with dash.",
	8: "If the current settings aren't confortable to you, you can set your own keybinds in options.\n\nThe game also supports controllers, even on web!",
	9: "[color=#ea4f36][b]Enemies[/b][/color] can also spawn from far behind. A [color=#f9c22b][b]danger indicator[/b][/color] will appear on screen.",
	10: "Stages have a progress bar.\n\nSometimes the bar pauses and only resumes after completion of an event.",
	11: "Items are mostly dropped by [color=#ea4f36][b]challenging foes[/b][/color], but combining them is essential.",
	14: "Everything you discover in the game will be registered in the codex [currently WIP], so you can further research them and plan your future runs",
	15: "That's all for now. Thanks for playing, and good luck!"
}

@onready var text_node = $MessageText

func _ready():
	load_keys()
	
	Options.options_changed.connect(load_keys)

func load_keys():
	for key in Options.key_dict:
		var value = Options.key_dict[key]
		var parsed_value = OS.get_keycode_string(value)
		keybinds_dict[key] = parsed_value

func request_message(text_id, manual_text : bool = false, timeout : float = default_timeout):
	visible = true
	
	
	## Open box
	size = Vector2(0, 0)
	var size_tween = get_tree().create_tween()
	size_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	size_tween.tween_property(self, "size", default_growth, growth_speed).as_relative().set_trans(Tween.TRANS_EXPO)
	await size_tween.finished
	size_tween.kill()
	
	## Set text
	if manual_text:
		manual_set_text(text_id)
	else:
		load_text(text_id)
	
	await get_tree().create_timer(timeout, false).timeout
	
	## Close box
	text_node.set_text("")
	size_tween = get_tree().create_tween()
	size_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	size_tween.tween_property(self, "size", Vector2(0, 0), growth_speed).set_trans(Tween.TRANS_EXPO)
	await size_tween.finished
	size_tween.kill()
	
	message_displayed.emit()
	visible = false

func load_text(text_id):
	var text = text_dict[text_id]
	
	text = text.format(keybinds_dict)
	
	text_node.set_text(
		"[center]{0}[/center]".format({0:text})
	)

func manual_set_text(text):
	text_node.set_text(text)
