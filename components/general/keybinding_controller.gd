extends CanvasLayer

var file_path = "res://components/keybinding_reg.json"

var key_dict = {
	"move_up":4194320,
	"move_down":4194322,
	"move_right":4194321,
	"move_left":4194319,
	"shoot":90,
	"bomb":88,
	"reset":82,
	"pause":4194305,
	"quit":81
}

var setting_key : bool = false
var settings_changed : bool = false

func _ready():
	load_keys()
	pass

#func _input(event):
#	if event is InputEventKey:
#		print(event.get_keycode_with_modifiers()) # Prints keycode int number to fill key_dict manually

func _on_visibility_changed(): 
	# | Converts keycode physical elements from key_dict to their respectives string labels, abling players to visualize which keys are currently bound to what.
	# Clearly theres a efficient way to automate these attributions in the case other buttons are added, but I need to prioritize other elements first, so that's it for now
	$OptionsControl/ConfigContainer/BindGrid/UP_B.text = OS.get_keycode_string(key_dict["move_up"])
	$OptionsControl/ConfigContainer/BindGrid/DOWN_B.text = OS.get_keycode_string(key_dict["move_down"])
	$OptionsControl/ConfigContainer/BindGrid/RIGHT_B.text = OS.get_keycode_string(key_dict["move_right"])
	$OptionsControl/ConfigContainer/BindGrid/LEFT_B.text = OS.get_keycode_string(key_dict["move_left"])
	$OptionsControl/ConfigContainer/BindGrid/PAUSE_B.text = OS.get_keycode_string(key_dict["pause"])
	$OptionsControl/ConfigContainer/BindGrid/RESET_B.text = OS.get_keycode_string(key_dict["reset"])
	$OptionsControl/ConfigContainer/BindGrid/SHOOT_B.text = OS.get_keycode_string(key_dict["shoot"])
	$OptionsControl/ConfigContainer/BindGrid/BOMB_B.text = OS.get_keycode_string(key_dict["bomb"])

func _on_exit_menu_pressed():
	print('Key settings changed: {0}'.format({0:settings_changed}))
	if settings_changed == true:
		$ExitCheck.visible = true
	else:
		Options.visible = false

# | Configured to autoload when the game starts 
func load_keys():
	var file = FileAccess.open(file_path, FileAccess.READ)
	if (FileAccess.file_exists(file_path)) == true:
		delete_old_keys()
		var content = file.get_as_text()
		print(content)
		var data = JSON.parse_string(content)
		file.close()
		print(data)
		if(typeof(data) == TYPE_DICTIONARY):
			key_dict = data
			setup_keys()
		else:
			printerr("WARNING | Keybind file not populated or corrupted data!")
	else:
		# | NoFile, so lets save the default keys now
		print("CAUTION | No file detected. Will create one using the default keys.")
		save_keys()
	pass
	
func delete_old_keys():
	# | Clear the old keys
	for i in key_dict:
		var oldkey = InputEventKey.new()
		oldkey.keycode = int(Options.key_dict[i])
		InputMap.action_erase_event(i,oldkey)
	settings_changed = true

func setup_keys():
	for i in key_dict:
		for j in get_tree().get_nodes_in_group("button_keys"):
			if(j.action_name == i):
				j.text = OS.get_keycode_string(key_dict[i])
		var newkey = InputEventKey.new()
		newkey.keycode = int(key_dict[i])
		InputMap.action_add_event(i,newkey)
	settings_changed = true
	
func save_keys():
	# | Save the new key bindings to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	var result = JSON.stringify(key_dict, "\t")
	file.store_string(result)
	file.close()
	print("Key saved")
	pass

func _on_exit_check_confirmed():
	save_keys()
	Options.visible = false

func _on_exit_check_canceled():
	Options.visible = false

# Learned from a tutorial from Rungeon, some parts had to be rewritten due to changes in Godot 4.2
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial
