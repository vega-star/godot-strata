extends Button

@export var keybind : String = ""

var do_set = false

func _pressed():
	text = ""
	Options.settings_changed = true
	do_set = true

func _input(event):
	if(do_set):
		if(event is InputEventKey):
			# | Erase old keys
			var newkey = InputEventKey.new()
			newkey.keycode = int(Options.key_dict[keybind])
			InputMap.action_erase_event(keybind,newkey)
			# | Add the new key for this action
			InputMap.action_add_event(keybind,event)
			# | Return to the user
			text = OS.get_keycode_string(event.keycode)
			# | Update the key_dict with the keycode function
			Options.key_dict[keybind] = event.keycode
			# | Stop keybind process
			do_set = false

# Foundation learned from a tutorial from Rungeon, most parts had to be rewritten due to changes in Godot 4.2 and new functions were added
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial
