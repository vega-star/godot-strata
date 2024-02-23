extends Node

signal profile_loaded
signal profile_changed(profile)
signal statistics_changed
signal stage_started
signal stage_ended
signal run_started
signal run_ended

#region Variables
# Selected profile
@export var selected_profile : String
var selected_profile_folder : String

# Data
const data_folder_path : String = "user://profiles"
var check_data_folder = DirAccess.make_dir_recursive_absolute(data_folder_path)

var profiles_data = ConfigFile.new()
var history_data = ConfigFile.new()
var current_run_data = ConfigFile.new()

var history_data_path : String
var current_run_data_path : String

# Active
var profile_data_path = "{0}/profiles.cfg".format({0:data_folder_path})
var profile_data_load = profiles_data.load(profile_data_path)
var save_data : bool = true

var current_score : int
#endregion

func _ready():
	if profile_data_load != OK: # Create profiles config file if not exists
		save_new_profile("Anonymous", "Mysterious Pilot", "icon", "color", 0, false)
	
	if !selected_profile: # If no profile is selected, anonymous is chosen
		selected_profile = 'Anonymous'
		save_data = profiles_data.get_value("Anonymous", "SAVE_DATA")
	
	await load_profile()
	profile_loaded.emit()
	
	start_run()
	run_started.emit()

func load_profile(profile = selected_profile):
	selected_profile_folder = "{0}/{1}".format({0:data_folder_path,1:profile})
	var check_profile_folder = DirAccess.make_dir_recursive_absolute(selected_profile_folder) 
	
	history_data_path = "{0}/history.cfg".format({0:selected_profile_folder})
	var history_data_load = history_data.load(history_data_path)
	history_data.save(history_data_path)
	
	current_run_data_path = "{0}/active_data.cfg".format({0:selected_profile_folder})
	var current_run_data_load = current_run_data.load(current_run_data_path)

func change_profile(profile):
	var profile_list : Array = ['anonymous']
	
	for profiles in profiles_data.get_sections():
		profile_list.append(profiles)
	
	profile_list.reverse()
	selected_profile = profile
	load_profile()

func save_new_profile(profile_name, pilot_name, icon, color, xp, save_data : bool = true):
	var profile_data_load = profiles_data.load(profile_data_path)
	
	# data_folder.make_dir(profile_name)
	profiles_data.set_value(profile_name, "PROFILE_PILOT_NAME", pilot_name)
	profiles_data.set_value(profile_name, "PROFILE_ICON", icon)
	profiles_data.set_value(profile_name, "PROFILE_COLOR", color)
	profiles_data.set_value(profile_name, "PROFILE_EXPERIENCE", xp)
	profiles_data.set_value(profile_name, "SAVE_DATA", save_data)
	
	profiles_data.save(profile_data_path)

# Run data
func start_run(loadout = 'hunter'):
	var start_time = Time.get_unix_time_from_system()
	
	## RUN DETAILS
	current_run_data.set_value("RUN_DETAILS", "SUCCESS", false)
	current_run_data.set_value("RUN_DETAILS", "STARTED_AT", start_time)
	current_run_data.set_value("RUN_DETAILS", "TIME_ELAPSED", 0)
	current_run_data.set_value("RUN_DETAILS", "LOADOUT", loadout)
	
	## STATISTICS
	current_run_data.set_value("STATISTICS", "RUN_TIME_ELAPSED", 0)
	current_run_data.set_value("STATISTICS", "SCORE", 0)
	current_run_data.set_value("STATISTICS", "ENEMIES_DEFEATED", 0)
	current_run_data.set_value("STATISTICS", "DAMAGE_TAKEN", 0)
	current_run_data.set_value("STATISTICS", "HEALTH_RECOVERED", 0)
	current_run_data.set_value("STATISTICS", "AMMO_CONSUMED", 0)
	current_run_data.set_value("STATISTICS", "AMMO_RECOVERED", 0)
	
	## START
	save_active_data()
	run_started.emit()

func end_run(success):
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
	
	save_active_data()
	
	#if FileAccess.file_exists(current_run_data_path):
	#	DirAccess.remove_absolute(current_run_data_path)
	pass

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
			data.append(value)
		TYPE_DICTIONARY:
			data = current_data + value
		_:
			push_warning('Type may not be supported by configuration file. Simple addition will be used')
			data = current_data + value
	current_run_data.set_value(section, statistic, current_data + value)
	
	if !bulk:
		save_active_data()
		statistics_changed.emit()

func add_bulk_data(data): # Change multiple values in one execution, save changes in file a single time after completion
	assert(data is Dictionary)
	for command in data:
		var section = data[command]["section"]
		var stat = data[command]["stat"]
		var value = data[command]["value"]
		add_run_data(section, stat, value, true)
	
	statistics_changed.emit()
	save_active_data()

func save_active_data():
	current_run_data.save(current_run_data_path)
