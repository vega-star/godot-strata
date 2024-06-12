extends CanvasLayer

signal options_changed

const keybind_file_path = "res://data/keybinding_reg.json"
const config_file_path = "user://config.cfg"
const screen_dict : Array = [
	"WINDOWED",
	"WINDOWED + BORDERLESS",
	"MAXIMIZED",
	"FULLSCREEN",
	"EXCLUSIVE FULLSCREEN"
]
var config_file = ConfigFile.new()
var config_file_load = config_file.load(config_file_path) 

@export var show_keycode : bool = false
@export var debug : bool = false

var default_key_dict : Dictionary = {
	"move_up":4194320,
	"move_down":4194322,
	"move_right":4194321,
	"move_left":4194319,
	"dash":32,
	"roll":4194328,
	"shoot":90,
	"bomb":88,
	"reset":82,
	"pause":96,
	"quit":81
}

var key_dict : Dictionary = {}
var setting_key : bool = false
var settings_changed : bool = false
var photosens_mode : bool

## Node references
@onready var master_slider = $"ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol/Master_Toggle/Master_Slider"
@onready var music_slider = $"ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol/Music_Toggle/Music_Slider"
@onready var effect_slider = $"ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol/Effect_Toggle/Effect_Slider"
@onready var master_toggle = $"ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol/Master_Toggle"
@onready var music_toggle = $"ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol/Music_Toggle"
@onready var sound_effect_toggle = $"ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol/Effect_Toggle"
@onready var effect_menu = $ConfigTabs/Graphics/Scroll/ConfigPanel/VisualEffects/VisualEffectsMenu

func _ready():
	await load_keys()
	
	if config_file_load == OK: # Config file generator and loader checker
		# DisplayServer.window_set_mode(config_file.get_value("MAIN_OPTIONS","WINDOW_MODE"))
		
		var current_photosens_state = config_file.get_value("MAIN_OPTIONS","PHOTOSENS_MODE")
		photosens_mode = current_photosens_state
		$ConfigTabs/Accessibility/Scroll/ConfigPanel/Photosens_Mode.button_pressed = current_photosens_state
		$ConfigTabs/Accessibility/Scroll/ConfigPanel/ScreenShake.button_pressed = config_file.get_value("MAIN_OPTIONS","SCREEN_SHAKE")
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/ToggleFiring'.button_pressed = config_file.get_value("MAIN_OPTIONS","TOGGLE_FIRE")
		master_slider.value = config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME")
		music_slider.value = config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME")
		effect_slider.value = config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME")
		_on_master_toggle_toggled(config_file.get_value("MAIN_OPTIONS","MASTER_TOGGLED"))
		_on_music_toggle_toggled(config_file.get_value("MAIN_OPTIONS","MUSIC_TOGGLED"))
		_on_effect_toggle_toggled(config_file.get_value("MAIN_OPTIONS","EFFECTS_TOGGLED"))
		
		config_file.save(config_file_path)
	else: 
		printerr("CONFIG FILE NOT FOUND | GENERATING DEFAULT VALUES")
		config_file.set_value("MAIN_OPTIONS","WINDOW_MODE", "WINDOW_MODE_WINDOWED")
		config_file.set_value("MAIN_OPTIONS","MINIMUM_WINDOW_SIZE", Vector2(480,270))
		config_file.set_value("MAIN_OPTIONS","PHOTOSENS_MODE", false)
		config_file.set_value("MAIN_OPTIONS","TOGGLE_FIRE", false)
		config_file.set_value("MAIN_OPTIONS","SCREEN_SHAKE", true)
		config_file.set_value("MAIN_OPTIONS","MASTER_VOLUME", 0.7)
		config_file.set_value("MAIN_OPTIONS","MASTER_TOGGLED", true)
		config_file.set_value("MAIN_OPTIONS","MUSIC_VOLUME", 0.6)
		config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", true)
		config_file.set_value("MAIN_OPTIONS","EFFECTS_VOLUME", 0.6)
		config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", true)
		
		config_file.save(config_file_path)
	
	if visible: visible = false # Just in case I forgot to make this node invisible after making UI changes
	
	# Setting some menu's based on distant node configurations
	await UI.ready
	for key in UI.ScreenEffect.effects:
		$ConfigTabs/Graphics/Scroll/ConfigPanel/VisualEffects/VisualEffectsMenu.add_item(key)
	
	for mode in screen_dict:
		$ConfigTabs/Graphics/Scroll/ConfigPanel/ScreenMode/ScreenModeMenu.add_item(mode)

func _exit(): # Clean temporary data and reset signal
	Options.visible = false
	settings_changed = false

# OPTIONS MENU FUNCTIONS

func _input(event): # Able the player to exit options screen using actions, needed for when using controllers
	if Input.is_action_pressed("quit") or Input.is_action_pressed("pause") and Options.visible == true:
		_on_exit_menu_pressed()

	if show_keycode == true: ## This conditional prints every input as its keycode integer. 
		# This is useful to fill key_dict manually, and I think it's faster than searching in docs.
		if event is InputEventKey: 
			print(event.get_keycode_with_modifiers()) 

func _emit_sound(sound_id : String):
	AudioManager.emit_sound_effect(null, sound_id, false, true)

func _on_reset_default_keybinds_button(): # Prompt to reset keybindings, preventing players from resetting accidentally
	$OptionsControl/ResetBinds.visible = true
	settings_changed = true

func _on_reset_default_keybinds(): # Reloads keys after redefining key_dict
	delete_old_keys()
	key_dict = default_key_dict
	for key in key_dict:
		setup_keys()
	_on_options_visibility_changed()
	save_keys()

func _on_options_visibility_changed(): 
	# | Converts keycode physical elements from key_dict to their respectives string labels, abling players to visualize which keys are currently bound to what.
	# I already know there's a efficient way to automate these attributions in the case other buttons are added, but I need to prioritize other elements first, so that's it for now
	if visible:
		$ConfigTabs.current_tab = 0
		$ConfigTabs.get_tab_bar().grab_focus() # Direct controller focus to this specific button
		
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridLeft/UP_B.text = OS.get_keycode_string(key_dict["move_up"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridLeft/DOWN_B.text = OS.get_keycode_string(key_dict["move_down"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridLeft/RIGHT_B.text = OS.get_keycode_string(key_dict["move_right"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridLeft/LEFT_B.text = OS.get_keycode_string(key_dict["move_left"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridLeft/PAUSE_B.text = OS.get_keycode_string(key_dict["pause"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridRight/DASH_B.text = OS.get_keycode_string(key_dict["dash"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridRight/ROLL_B.text = OS.get_keycode_string(key_dict["roll"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridRight/RESET_B.text = OS.get_keycode_string(key_dict["reset"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridRight/SHOOT_B.text = OS.get_keycode_string(key_dict["shoot"])
		$ConfigTabs/Controls/Scroll/ConfigPanel/BindGrids/BindGridRight/BOMB_B.text = OS.get_keycode_string(key_dict["bomb"])

func _on_config_tabs_tab_selected(_tab): $ConfigTabs.get_tab_bar().grab_focus()

func _on_exit_menu_pressed():
	if debug == true: print('Has the keybind configuration changed?: {0}'.format({0:settings_changed}))
	if settings_changed == true:
		$OptionsControl/ExitCheck.visible = true
	else:
		_exit()

func load_keys():
	var file = FileAccess.open(keybind_file_path, FileAccess.READ)
	
	if (FileAccess.file_exists(keybind_file_path)):
		delete_old_keys()
		var content = file.get_as_text()
		var data = JSON.parse_string(content)
		file.close()
		
		if debug == true:# | (DEBUG) |
			print(content)
			print(data)
		
		if(typeof(data) == TYPE_DICTIONARY):
			key_dict = data
			setup_keys()
		elif data == {}:
			key_dict = default_key_dict
			setup_keys()
			print("CAUTION | File is empty. Populating input binds")
		else:
			printerr("ERROR | Data from keybind file exists, but it is either corrupted or in another format.")
	else:
		printerr("ERROR | Keybind path is invalid! Unable to save keybinds.")
	pass

func delete_old_keys(): # Clear the old keys when inputting new ones
	for i in key_dict:
		var oldkey = InputEventKey.new()
		oldkey.keycode = int(Options.key_dict[i])
		InputMap.action_erase_event(i,oldkey)

func setup_keys(): # Registry keys in dict as events
	for i in key_dict: # | Iterates through elements in a dictionary
		for j in get_tree().get_nodes_in_group("button_keys"): # | Iterates through buttons
			if(j.action_name == i): # | Stops when the action name is equivalent to key
				j.text = OS.get_keycode_string(key_dict[i]) # | Sets button text to the string label of a key
			if debug == true: print('Element: {0} | Button {1}'.format({0:i,1:j})) # | (DEBUG |
		var newkey = InputEventKey.new() # | Waits for a key press
		newkey.keycode = int(key_dict[i]) # | Recieves keycode from 
		InputMap.action_add_event(i,newkey) # | Finally, adds the new key to InputMap
	
func save_keys(): # Save the new key bindings to file
	var file = FileAccess.open(keybind_file_path, FileAccess.WRITE)
	var result = JSON.stringify(key_dict, "\t")
	file.store_string(result)
	file.close()
	
	if debug == true:
		print(result)
		print("Key saved")
	pass

func _on_exit_check_confirmed():
	save_keys()
	options_changed.emit()
	
	config_file.save(config_file_path)
	_exit()

func _on_exit_check_canceled():
	_exit()

func _on_toggle_firing_pressed():
	button_toggle($'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/ToggleFiring', "TOGGLE_FIRE")

func _on_photosens_mode_pressed():
	button_toggle($ConfigTabs/Accessibility/Scroll/ConfigPanel/Photosens_Mode, "PHOTOSENS_MODE")
	photosens_mode = $ConfigTabs/Accessibility/Scroll/ConfigPanel/Photosens_Mode.button_pressed

func _on_screen_shake_pressed():
	button_toggle($ConfigTabs/Accessibility/Scroll/ConfigPanel/ScreenShake, "SCREEN_SHAKE")

func button_toggle(button, config):
	var button_status = bool(button.button_pressed)
	
	config_file.set_value("MAIN_OPTIONS", config, button_status)
	settings_changed = true

func _on_screen_mode_selected(index):
	var window_modes = { # Reason behind this weird dict: https://docs.godotengine.org/en/stable/classes/class_displayserver.html#enum-displayserver-windowmode
		0:0, #? WINDOWED
		1:0, #? WINDOWED + BORDERLESS
		2:2, #? MAXIMIZED
		3:3, #? FULLSCREEN
		4:4  #? EXCLUSIVE FULLSCREEN
	}
	if index == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
	DisplayServer.window_set_mode(window_modes[index])
	config_file.set_value("MAIN_OPTIONS","WINDOW_MODE",window_modes[index])
	if debug: print('Display format selected: {0}'.format({0:window_modes[index]}))
	config_file.save(config_file_path)

# Foundation based on a tutorial from Rungeon, mostly rewritten due to changes in Godot 4.2 and a lot of other functions were added
# Even so, his tutorial is great and explore more details about registering and updating keybindings
# Source: https://www.youtube.com/watch?v=WHGHevwhXCQ
# Github: https://github.com/trolog/godotKeybindingTutorial

#region Toggle
func _on_master_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","MASTER_TOGGLED", toggled_on)
	config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", toggled_on)
	config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", toggled_on)
	
	master_slider.editable = toggled_on
	music_slider.editable = toggled_on
	effect_slider.editable = toggled_on
	
	if toggled_on:
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol'.modulate.a = 1
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 1
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 1
		
		set_volume(0, linear_to_db(config_file.get_value("MAIN_OPTIONS","MASTER_VOLUME")))
	else:
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MasterVol'.modulate.a = 0.5
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 0.5
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 0.5
		
		set_volume(0, linear_to_db(0))

func _on_music_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","MUSIC_TOGGLED", toggled_on)
	music_slider.editable = toggled_on
	
	if toggled_on:
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 1
		set_volume(2, linear_to_db(config_file.get_value("MAIN_OPTIONS","MUSIC_VOLUME")))
	else:
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/MusicVol'.modulate.a = 0.5
		set_volume(2, linear_to_db(0))

func _on_effect_toggle_toggled(toggled_on):
	config_file.set_value("MAIN_OPTIONS","EFFECTS_TOGGLED", toggled_on)
	effect_slider.editable = toggled_on
	
	if toggled_on:
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 1
		set_volume(1, linear_to_db(config_file.get_value("MAIN_OPTIONS","EFFECTS_VOLUME")))
	else:
		$'ConfigTabs/Main Options/Scroll/ConfigPanel/OptionsButtons/VolumeContainer/SoundEffectVol'.modulate.a = 0.5
		set_volume(1, linear_to_db(0))
#endregion

#region Audio
func set_volume(bus_id, new_db):
	AudioServer.set_bus_volume_db(bus_id, new_db)

func _on_master_slider_value_changed(value):
	config_file.set_value("MAIN_OPTIONS","MASTER_VOLUME", value)
	set_volume(0, linear_to_db(master_slider.value))

func _on_music_slider_value_changed(value):
	config_file.set_value("MAIN_OPTIONS","MUSIC_VOLUME", value)
	set_volume(2, linear_to_db(music_slider.value))

func _on_effect_slider_value_changed(value):
	config_file.set_value("MAIN_OPTIONS","EFFECTS_VOLUME", value)
	set_volume(1, linear_to_db(effect_slider.value))

func _on_master_slider_drag_ended(_value_changed):
	config_file.save(config_file_path)

func _on_music_slider_drag_ended(_value_changed):
	config_file.save(config_file_path)

func _on_effect_slider_drag_ended(_value_changed):
	config_file.save(config_file_path)
#endregion

func _on_visual_effect_selected(index):
	UI.ScreenEffect.change_effect(effect_menu.get_item_text(index))
