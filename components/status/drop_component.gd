class_name DropComponent extends Node

signal item_dropped

@export var debug : bool = false

# For each enemy in game, the drop list has two related arrays, one with the items and the other with the weights. The higher the weight respective to the item, the higher the odds for it to drop.
var enemy_drops_list = {
	"enemy": {"items": [false,"secondary_ammo","health_capsule"], "chances": [0,80,90,20001], "range": 100},
	"striker_1": {"items": [false,"secondary_ammo","health_capsule"], "chances": [0,80,90,20001], "range": 100}
}

var item_list = {
	"health_capsule": {"scene": "res://entities/items/health_capsule.tscn", "accumulate": true},
	"secondary_ammo": {"scene": "res://entities/items/secondary_ammo.tscn", "accumulate": true},
	"damage_boost": {"scene": "", "accumulate": false}
}

@onready var root_scene = owner.get_parent()
@onready var item_container = root_scene.get_parent().get_node("ItemsContainer")
@onready var enemy : String = owner.enemy_name

func _ready(): # Needed for random results
	randomize()

func _on_enemy_died():
	var drop = gamble_drop(enemy_drops_list[enemy]["items"],enemy_drops_list[enemy]["chances"], enemy_drops_list[enemy]["range"])
	if drop: 
		spawn_item(item_list[drop])
	else: pass
	item_dropped.emit(drop)

func gamble_drop(items,chances, range):
	var drop_value = randi_range(1,range)
	print(drop_value)
	for i in items.size():
		var next_item_chance : int
		clamp(next_item_chance,0,chances.size())
		next_item_chance = chances[i + 1]
		
		if debug: print('ITEM INDEX: {2} | VALUE ROLLED: {0} | NEXT_ITEM_CHANCE: {1}'.format({0:drop_value, 1:next_item_chance, 2:i}))
		
		if next_item_chance > drop_value: 
			if debug: print('ITEM GAMBLED: %s' % str(items[i]))
			return items[i] # If next_value is bigger than random number chance, drop current item in loop
		else: pass

func spawn_item(item):
	var item_scene = load(item["scene"])
	item = item_scene.instantiate()
	item.global_position = owner.global_position
	item_container.add_child(item)
