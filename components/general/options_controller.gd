extends CanvasLayer

var file_path = "res://components/keybinding_reg.json"

var default_key_dict : Dictionary = {
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

var key_dict : Dictionary = {}
var setting_key : bool = false
var settings_changed : bool = false

func _ready():
	load_keys()

func _exit(): # Clean temporary data and reset signal
	Options.visible = false
	settings_changed = false

func _input(_event):
	if Input.is_action_pressed("quit") or Input.is_action_pressed("pause") and Options.visible == true:
		_on_exit_menu_pressed()

func _on_reset_default_keybinds_button():
	$ResetBinds.visible = true

func _on_reset_default_keybinds():
	key_dict = default_key_dict
	delete_old_keys()
	setup_keys()
	_on_visibility_changed()
	save_keys()


#	if event is InputEventKey:
#		print(event.get_keycode_with_modifiers()) # Prints keycode int number to fill key_dict manually

func _on_visibility_changed(): 
	# | Converts keycode physical elements from key_dict to their respectives string labels, abling players to visualize which keys are currently bound to what.
	# I already know there's a efficient way to automate these attributions in the case other buttons are added, but I need to prioritize other elements first, so that's it for now
	$OptionsControl/ConfigContainer/Binds/BindGrid/UP_B.text = OS.get_keycode_string(key_dict["move_up"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/DOWN_B.text = OS.get_keycode_string(key_dict["move_down"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/RIGHT_B.text = OS.get_keycode_string(key_dict["move_right"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/LEFT_B.text = OS.get_keycode_string(key_dict["move_left"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/PAUSE_B.text = OS.get_keycode_string(key_dict["pause"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/RESET_B.text = OS.get_keycode_string(key_dict["reset"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/SHOOT_B.text = OS.get_keycode_string(key_dict["shoot"])
	$OptionsControl/ConfigContainer/Binds/BindGrid/BOMB_B.text = OS.get_keycode_string(key_dict["bomb"])

func _on_exit_menu_pressed():
	print('Has the keybind configuration changed?: {0}'.format({0:settings_changed}))
	if settings_changed == true:
		$ExitCheck.visible = true
	else:
		_exit()

# | Configured to autoload when the game starts 
func load_keys():
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if (FileAccess.file_exists(file_path)) == true:
		delete_old_keys()
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		file.close()
		
		# | Uncomment for debugging file
		print(content)
		print(data)
		
		if(typeof(data) == TYPE_DICTIONARY):
			key_dict = data
			setup_keys()
		elif data == {}:
			key_dict = default_key_dict
			print('File is empty. Populating input binds')
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

func setup_keys(): # Sets keys in dict as events
	for i in key_dict:
		for j in get_tree().get_nodes_in_group("button_keys"):
			if(j.action_name == i):
				j.text = OS.get_keycode_string(key_dict[i])
		var newkey = InputEventKey.new()
		newkey.keycode = int(key_dict[i])
		InputMap.action_add_event(i,newkey)
	
func save_keys():
	# | Save the new key bindings to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	var result = JSON.stringify(key_dict, "\t")
	file.store_string(result)
	file.close()
	
	print(result)
	print("Key saved")
	pass

func _on_exit_check_confirmed():
	save_keys()
	_exit()

func _on_exit_check_canceled():
	_exit()

# Foundation learned from a tutorial from Rungeon, most parts had to be rewritten due to changes in Godot 4.2 and new functions were added
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial
