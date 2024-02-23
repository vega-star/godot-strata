class_name StatisticsConsole extends Control

@export var output_list : ItemList
@export var values_list : ItemList

func _on_visibility_changed():
	update_data()

func update_data():
	if !output_list:
		output_list = $DefaultStatisticsList
		values_list = $DefaultValuesList
	
	output_list.clear()
	values_list.clear()
	
	var statistics = Profile.current_run_data.get_section_keys("STATISTICS")
	output_list.max_columns = 1
	values_list.max_columns = 1
	for stat in statistics:
		var stat_title = stat.capitalize()
		output_list.add_item(stat_title)
		var value = Profile.current_run_data.get_value("STATISTICS", stat)
		values_list.add_item(str(value))
