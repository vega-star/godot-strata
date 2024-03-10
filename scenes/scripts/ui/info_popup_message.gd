extends Control

signal message_displayed

const default_growth : Vector2 = Vector2(400, 120)
const growth_speed : float = 0.5
const default_timeout : float = 3

@onready var text_dict : Dictionary = {
	1: "This is message number 1.\nTest 1 successful",
	2: "This is message number 2.\nTest 2 successful"
}

@onready var text_node = $MessageText

func request_message(text_id, manual_text : bool = false):
	visible = true
	
	if manual_text:
		manual_set_text(text_id)
	else:
		load_text(text_id)
	
	size = Vector2(0, 0)
	var size_tween = get_tree().create_tween()
	size_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	size_tween.tween_property(self, "size", default_growth, growth_speed).as_relative().set_trans(Tween.TRANS_EXPO)
	await size_tween.finished
	size_tween.kill()
	await get_tree().create_timer(default_timeout, false).timeout
	
	size_tween = get_tree().create_tween()
	size_tween.tween_property(self, "size", Vector2(0, 0), growth_speed).set_trans(Tween.TRANS_EXPO)
	await size_tween.finished
	size_tween.kill()
	
	message_displayed.emit()
	visible = false

func load_text(text_id):
	text_node.set_text(
		"[center]{0}[/center]".format({0:text_dict[text_id]})
	)

func manual_set_text(text):
	text_node.set_text(text)
