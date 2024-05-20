extends Node

signal profile_loaded
signal profile_changed(profile)
signal run_data_changed
signal statistics_changed
signal stage_started
signal stage_ended
signal run_started(current_data_file)
signal run_ended(current_data_file)

#region Variables
# Selected profile
@export var selected_profile : String
var selected_profile_folder : String
var profile_history_folder : String

# Data
const data_folder_path : String = "user://profiles"
var check_data_folder = DirAccess.make_dir_recursive_absolute(data_folder_path)

var profiles_data = ConfigFile.new()
var history_data = ConfigFile.new()
var current_run_data = ConfigFile.new()
var previous_run_data = ConfigFile.new()
var codex_data = ConfigFile.new()

var history_data_path : String
var current_run_data_path : String
var previous_run_data_path : String
var codex_data_path : String

# Active
var profile_data_path = "{0}/profiles.cfg".format({0:data_folder_path})
var profile_data_load = profiles_data.load(profile_data_path)
var save_data : bool = true
@export var debug : bool = false
#endregion

func _ready():
	if profile_data_load != OK: # Create profiles config file if not exists
		save_new_profile("Anonymous", "Mysterious Pilot", "icon", "color", 0, false)
	
	if !selected_profile: # If no profile is selected, anonymous is chosen
		selected_profile = 'Anonymous'
		save_data = profiles_data.get_value("Anonymous", "SAVE_DATA")
	
	await load_profile()
	profile_loaded.emit()
	
	reset_run_data()
	run_started.emit()

func load_profile(profile = selected_profile):
	var data_load
	selected_profile_folder = "{0}/{1}".format({
		0:data_folder_path,
		1:profile
	})
	var check_profile_folder = DirAccess.make_dir_recursive_absolute(selected_profile_folder) 
	
	profile_history_folder = "{0}/history".format({0:selected_profile_folder})
	var check_history_folder = DirAccess.make_dir_recursive_absolute(profile_history_folder) 
	
	history_data_path = "{0}/history.cfg".format({0:selected_profile_folder})
	data_load = history_data.load(history_data_path)
	if data_load != OK:
		history_data.save(history_data_path)
	
	current_run_data_path = "{0}/active_data.cfg".format({0:selected_profile_folder})
	data_load = current_run_data.load(current_run_data_path)
	if data_load != OK:
		current_run_data.save(current_run_data_path)
		
	previous_run_data_path = "{0}/backup_data.cfg".format({0:selected_profile_folder})
	data_load = previous_run_data.load(previous_run_data_path)
	if data_load != OK:
		previous_run_data.save(previous_run_data_path)
	
	codex_data_path = "{0}/codex.cfg".format({0:selected_profile_folder})
	data_load = codex_data.load(codex_data_path)
	if data_load != OK:
		codex_data.save(codex_data_path)

func change_profile(profile):
	var profile_list : Array = ['anonymous']
	
	for profiles in profiles_data.get_sections():
		profile_list.append(profiles)
	
	if profile_list.has(profile):
		selected_profile = profile
		load_profile()
	else:
		push_error('INVALID PROFILE | No profile with this name found')

func save_new_profile(profile_name, pilot_name, icon, color, xp : int = 0, save_data : bool = true):
	var profile_data_load = profiles_data.load(profile_data_path)
	
	profiles_data.set_value(profile_name, "PROFILE_PILOT_NAME", pilot_name)
	profiles_data.set_value(profile_name, "PROFILE_ICON", icon)
	profiles_data.set_value(profile_name, "PROFILE_COLOR", color)
	profiles_data.set_value(profile_name, "PROFILE_EXPERIENCE", xp)
	profiles_data.set_value(profile_name, "SAVE_DATA", save_data)
	
	profiles_data.set(profile_name, "ACHIEVEMENTS")
	profiles_data.set(profile_name, "CODEX")
	
	profiles_data.save(profile_data_path)

func save_profile_data():
	profiles_data.save(profile_data_path)

## RUN DATA
func reset_run_data():
	var start_time = Time.get_unix_time_from_system()
	
	## STATISTICS
	current_run_data.set_value("STATISTICS", "RUN_TIME_ELAPSED", 0)
	current_run_data.set_value("STATISTICS", "SCORE", 0)
	current_run_data.set_value("STATISTICS", "ENEMIES_DEFEATED", 0)
	current_run_data.set_value("STATISTICS", "DAMAGE_TAKEN", 0)
	current_run_data.set_value("STATISTICS", "HEALTH_RECOVERED", 0)
	current_run_data.set_value("STATISTICS", "AMMO_CONSUMED", 0)
	current_run_data.set_value("STATISTICS", "AMMO_RECOVERED", 0)
	
	## INVENTORY
	current_run_data.set_value("INVENTORY", "PRIMARY_WEAPON", "")
	current_run_data.set_value("INVENTORY", "SECONDARY_WEAPON", "")
	current_run_data.set_value("INVENTORY", "CURRENT_HEALTH", 1)
	current_run_data.set_value("INVENTORY", "MAX_HEALTH", 5)
	current_run_data.set_value("INVENTORY", "HEALTH_REGENERATION", false)
	current_run_data.set_value("INVENTORY", "CURRENT_AMMO", 1)
	current_run_data.set_value("INVENTORY", "MAX_AMMO", 7)
	current_run_data.set_value("INVENTORY", "AMMO_REGENERATION", false)
	current_run_data.set_value("INVENTORY", "ACTIVE_ITEM", "")
	current_run_data.set_value("INVENTORY", "ITEMS_STORED", [])
	
	## BUFFS
	current_run_data.set_value("EFFECTS", "ACTIVE_EFFECTS", [])
	current_run_data.set_value("EFFECTS", "BONUS_HEALTH", 0)
	current_run_data.set_value("EFFECTS", "BONUS_AMMO", 0)
	
	## RESET
	if current_run_data.has_section("STAGES"): current_run_data.erase_section("STAGES")
	if current_run_data.has_section("RUN_DETAILS"): current_run_data.erase_section("RUN_DETAILS")
	if current_run_data.has_section_key("STATISTICS", "DEFEATED_BY"): current_run_data.erase_section_key("STATISTICS", "DEFEATED_BY")
	
	## START
	save_active_data()
	run_started.emit(current_run_data)

func start_run():
	var start_time = Time.get_unix_time_from_system()
	await reset_run_data()
	
	current_run_data.set_value("RUN_DETAILS", "SUCCESS", false)
	current_run_data.set_value("RUN_DETAILS", "STARTED_AT", start_time)
	current_run_data.set_value("RUN_DETAILS", "TIME_ELAPSED", 0)

func end_run(success : bool = false, source : Variant = null):
	run_ended.emit()
	
	var start_time = current_run_data.get_value("RUN_DETAILS", "STARTED_AT")
	var final_time = Time.get_unix_time_from_system()
	var time_diff_in_sec = int(final_time - start_time)
	
	var time_sec = time_diff_in_sec % 60
	var time_min = (time_diff_in_sec/60) % 60
	var time_h = (time_diff_in_sec/60)/60
	var time_diff =  "%02d:%02d:%02d" % [time_h, time_min, time_sec]
	
	current_run_data.set_value("RUN_DETAILS", "ENDED_AT", final_time)
	current_run_data.set_value("STATISTICS", "RUN_TIME_ELAPSED", time_diff)
	current_run_data.set_value("RUN_DETAILS", "SUCCESS", success)
	
	if !success:
		## Source patching
		if !source:
			current_run_data.set_value("RUN_DETAILS", "DEFEATED_BY", "UNKNOWN")
		else:
			current_run_data.set_value("RUN_DETAILS", "DEFEATED_BY", source.enemy_name)
	
	save_active_data(true)

func add_run_data(section, statistic, value, bulk : bool = false): # Change one value, save changes in file
	var current_data = current_run_data.get_value(section, statistic)
	var data
	
	match typeof(current_data): # Sorter for addition with different data types
		TYPE_NIL:
			data = value
		TYPE_INT:
			data = int(current_data + value)
		TYPE_FLOAT:
			data = float(current_data + value)
		TYPE_STRING:
			data = String(current_data + value)
		TYPE_ARRAY:
			current_data.append(value)
			data = current_data
		TYPE_DICTIONARY:
			current_data[data] = value
		_:
			push_warning('Type may not be supported by configuration file. Simple addition will be used')
			data = current_data + value
	current_run_data.set_value(section, statistic, data)
	
	if !bulk:
		save_active_data()

func add_bulk_data(data): # Change multiple values in one execution, save changes in file a single time after completion
	assert(data is Dictionary)
	for command in data:
		var section = data[command]["section"]
		var stat = data[command]["stat"]
		var value = data[command]["value"]
		add_run_data(section, stat, value, true)
	save_active_data()

func save_previous_data():
	previous_run_data = current_run_data
	previous_run_data.save(previous_run_data_path)

func load_previous_data():
	await reset_run_data()
	current_run_data = previous_run_data
	await save_active_data()

func save_active_data(close : bool = false):
	current_run_data.save(current_run_data_path)
	
	if close:
		var timestamp = current_run_data.get_value("RUN_DETAILS", "STARTED_AT")
		var final_run_data_path = "{0}/RUN_{1}.cfg".format({
			0:profile_history_folder,
			1:timestamp
		})
		current_run_data.save(final_run_data_path)
	
	statistics_changed.emit()
	run_data_changed.emit()
