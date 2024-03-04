class_name DropComponent extends Node

signal drop_selected
signal item_dropped(drop)

@export var debug : bool = false

# For each enemy in game, the drop list has two related arrays, one with the items and the other with the weights. The higher the weight respective to the item, the higher the odds for it to drop.
const item_template_scene = "res://entities/items/item_component.tscn"
const enemy_data = "res://data/enemy_data.json"
const items_data = "res://data/items_data.json"
var enemy_dict : Dictionary
var items_dict : Dictionary
var drop_type : int
var items_array : Array

@onready var root_scene = owner.get_parent()
@onready var item_container = root_scene.get_parent().get_node("ItemsContainer")
@onready var enemy : String = owner.enemy_name

func _ready(): # Needed for random results
	randomize()
	
	assert(FileAccess.file_exists(enemy_data))
	assert(FileAccess.file_exists(items_data))
	
	var load_enemy_data = FileAccess.open(enemy_data, FileAccess.READ)
	enemy_dict = JSON.parse_string(load_enemy_data.get_as_text())
	assert(enemy_dict is Dictionary)
	
	var load_items_data = FileAccess.open(items_data, FileAccess.READ)
	items_dict = JSON.parse_string(load_items_data.get_as_text())
	assert(items_dict is Dictionary)


func _on_enemy_died():
	var enemy_has_drops = enemy_dict[enemy]["contain_items"]
	drop_type = enemy_dict[enemy]["drops"]["type"]
	if enemy_has_drops:
		match drop_type:
			0: # Drops
				var drop = gamble_drop(enemy_dict[enemy]["drops"]["items"], enemy_dict[enemy]["drops"]["chances"], enemy_dict[enemy]["drops"]["range"])
				if drop:
					item_dropped.emit(drop)
			1: # Items
				var quantity = enemy_dict[enemy]["drops"]["quantity"]
				if quantity > 1:
					var sucessful_tries : int
					while sucessful_tries != quantity:
						var drop = gamble_drop(enemy_dict[enemy]["drops"]["items"], enemy_dict[enemy]["drops"]["chances"], enemy_dict[enemy]["drops"]["range"])
						if !enemy_dict[enemy]["drops"]["repeat"] and items_array.has(drop):
							pass
						else:
							sucessful_tries += 1
							items_array.append(drop)
					print(items_array)
					item_dropped.emit(items_array)
				else:
					var drop = gamble_drop(enemy_dict[enemy]["drops"]["items"], enemy_dict[enemy]["drops"]["chances"], enemy_dict[enemy]["drops"]["range"])
					item_dropped.emit(drop)
	else: 
		push_warning('Drop requested, but enemy has container_items turned off. Check the data file for the missing info')

func gamble_drop(items, chances, max_range):
	var drop_value = randi_range(1,max_range)
	for i in items.size():
		var next_item_chance : int
		clamp(next_item_chance,0,chances.size())
		next_item_chance = chances[i + 1]
		
		if debug: print('ITEM INDEX: {2} | VALUE ROLLED: {0} | NEXT_ITEM_CHANCE: {1}'.format({0:drop_value, 1:next_item_chance, 2:i}))
		
		if next_item_chance > drop_value: 
			if debug: print('ITEM GAMBLED: %s' % str(items[i]))
			return items[i] # If next_value is bigger than random number chance, drop current item in loop
		else:
			pass

func _on_item_dropped(drop):
	var drop_is_array : bool = false
	var item_scene
	
	if debug: print('ITEM DROPPED')
	if drop is Array: 
		drop_is_array = true
	
	if drop_is_array:
		item_scene = load(item_template_scene)
	else:
		item_scene = load(items_dict["drops"][drop]["scene"])
	drop = item_scene.instantiate()
	
	if drop_is_array:
		drop.set_items(items_array)
		drop.set_type(0)
	
	drop.global_position = owner.global_position
	item_container.call_deferred("add_child", drop)
