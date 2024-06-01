extends TextureButton

@export var sound_when_pressed : String = "select_sound_2"
@export var sound_when_focus : String = "select_sound_3"
@export var sound_when_hovered : String = "hover_sound_1"

func _emit_sound(sound_id : String):
	AudioManager.emit_sound_effect(null, sound_id, false, true)

func _on_pressed():
	_emit_sound(sound_when_pressed)

func _on_focus_entered():
	_emit_sound(sound_when_focus)

func _on_mouse_entered():
	_emit_sound(sound_when_hovered)
