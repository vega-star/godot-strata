class_name DropComponent extends Node

signal drop_selected
signal item_dropped(drop)

const item_container_group = 'items_container'
const item_template_scene = "res://entities/items/item_component.tscn"
const enemy_data = "res://data/enemy_data.json"
const items_data = "res://data/items_data.json"

## Main variables
@export var stage_dropper : bool = false
@export var debug : bool = false
@onready var root_scene = owner.get_parent()

## Data variables
var item_container
var enemy : String = "UNSET"
var enemy_dict : Dictionary
var items_dict : Dictionary
var items_array : Array

## Processing variables
# For each enemy in game that has drops, the drop list has two related arrays: one with the items and the other with the weights. 
# The higher the weight respective to the item, the higher the odds for it to drop. Simple as that.
var drop_type : int
var drop_chances : Array
var drops_array : Array
var drop_position : Vector2
var drops_range : int
var drop_repeat : bool
var drops_quantity : int

func _ready(): # Needed for random results
	randomize()
	
	assert(FileAccess.file_exists(enemy_data))
	assert(FileAccess.file_exists(items_data))
	
	if stage_dropper:
		item_container = $"../ItemsContainer"
	else:
		item_container = get_tree().get_first_node_in_group(item_container_group)
	
	var load_enemy_data = FileAccess.open(enemy_data, FileAccess.READ)
	enemy_dict = JSON.parse_string(load_enemy_data.get_as_text())
	assert(enemy_dict is Dictionary)
	
	var load_items_data = FileAccess.open(items_data, FileAccess.READ)
	items_dict = JSON.parse_string(load_items_data.get_as_text())
	assert(items_dict is Dictionary)

func _on_enemy_died():
	var enemy = owner.enemy_name
	var enemy_has_drops = enemy_dict[enemy]["contain_items"]
	
	if enemy_has_drops:
		drop_position = owner.global_position
		
		var type : int = enemy_dict[enemy]["drops"]["type"]
		var quantity : int
		
		match type:
			0: # Single consumable drop with no choice involved, but still gambles the chances
				quantity = 1
			1: # Choice menu popups for items
				quantity = enemy_dict[enemy]["drops"]["quantity"]
			2: # Spawn exactly the same drop always without gambling whatsoever. Faster process for guaranteed drops
				## TODO: PREVENT CONFIG_DROP FROM COMING BEFORE THIS MATCH
				var drop = enemy_dict[enemy]["drops"]["items"]
				if drop is String:
					item_dropped.emit(drop)
				elif drop is Array:
					for item in drop:
						item_dropped.emit(item)
				return
			_: # Unset or invalid type, will still try to configure drop
				quantity = 1
		
		await config_drop(
			type, # Type
			enemy_dict[enemy]["drops"]["items"], # Items
			enemy_dict[enemy]["drops"]["chances"], # Chances
			enemy_dict[enemy]["drops"]["range"], # Range
			quantity # Quantity
		)
		request_drop()
	else: 
		push_warning('Drop requested, but enemy has container_items turned off. Check the data file for the missing info')

func config_drop(type, items, chances, range, quantity : int = 1, repeat : bool = false, position = null):
	drop_type = type
	drops_array = items
	drop_chances = chances
	drops_range = range
	drops_quantity = quantity
	drop_repeat = repeat
	
	if position: drop_position = position

func request_drop(override_drop = null):
	if !override_drop:
		match drop_type:
			0: # Consumable drops
				var drop = gamble_drop(drops_array, drop_chances, drops_range)
				if drop:
					item_dropped.emit(drop)
			1: # Items to select
				var quantity = drops_quantity
				if quantity > 1:
					var sucessful_tries : int
					while sucessful_tries != quantity: # Loops until item array is the ideal size
						var drop = gamble_drop(drops_array, drop_chances, drops_range)
						if !drop_repeat and items_array.has(drop):
							pass
						else:
							sucessful_tries += 1
							items_array.append(drop)
					if debug: print(items_array)
					item_dropped.emit(items_array)
				else:
					var drop = gamble_drop(drops_array, drop_chances, drops_range)
					item_dropped.emit(drop)
	else:
		item_dropped.emit(override_drop)

func gamble_drop(items, chances, max_range):
	var drop_value = randi_range(1,max_range)
	var gamble_amount = items.size()
	chances.append(drops_range + 1)
	for i in gamble_amount:
		var next_item_chance : int
		next_item_chance = chances[i + 1]
		
		if debug: print('ITEM INDEX: {2} | VALUE ROLLED: {0} | NEXT_ITEM_CHANCE: {1}'.format({0:drop_value, 1:next_item_chance, 2:i}))
		
		if drop_type == 0 and items[i]:
			match items_dict["drops"][str(items[i])]["item_function"]:
				0: # Health
					if Profile.current_run_data.get_value("INVENTORY", "CURRENT_HEALTH") == Profile.current_run_data.get_value("INVENTORY", "MAX_HEALTH"):
						return
				1: # Ammo
					if Profile.current_run_data.get_value("INVENTORY", "CURRENT_AMMO") == Profile.current_run_data.get_value("INVENTORY", "MAX_AMMO"):
						return
				2: # Damage boost
					pass
				_:
					print('UNSUPPORTED DROP ITEM')
		
		if next_item_chance > drop_value: 
			if debug: print('ITEM GAMBLED: %s' % str(items[i]))
			return items[i] # If next_value is bigger than random number chance, drop current item in loop

func _on_item_dropped(drop, position : Vector2 = drop_position):
	drop_item(drop, position)

func drop_item(drop, position : Vector2 = drop_position):
	var drop_is_array : bool = false
	var item_scene
	var item
	
	if debug: print('ITEM DROPPED')
	if drop is Array: 
		if debug: print('ITEM IS ARRAY')
		drop_is_array = true
	
	if drop_is_array:
		item_scene = load(item_template_scene)
	else:
		item_scene = load(items_dict["drops"][drop]["scene"])
	
	item = item_scene.instantiate()
	if debug: print(item)
	
	if drop_is_array:
		item.set_type(0)
		if items_array: item.set_items(items_array)
		else: item.set_items(drop)
	
	item.global_position = position
	item_container.call_deferred("add_child", item)
