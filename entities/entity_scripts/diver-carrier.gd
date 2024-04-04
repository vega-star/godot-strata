extends "res://entities/entity_scripts/enemy.gd"

@onready var top_slots_node = $TopSlots
@onready var bottom_slots_node = $BottomSlots
@onready var temporary_container = $TemporaryContainer

@export var spawn_top : bool = true
@export var spawn_bottom : bool = true
@export var release_timeout : float = 2

const entity_id = 'diver'
const threat_generator_group = 'threat_generator'

var threat_generator
var scene_enemy_container
var top_slots : Array = []
var bottom_slots : Array = []
var top_divers : Array
var bottom_divers : Array
var release_order : int = 0
var locked_release : bool = true

## Diver Carrier
func _ready():
	## Locating generator and scene container
	threat_generator = get_tree().get_first_node_in_group(threat_generator_group)
	scene_enemy_container = threat_generator.enemies_container
	
	## Slots loading
	for s in top_slots_node.get_child_count():
		var slot = top_slots_node.get_child(s)
		top_slots.append(slot)
	
	for s in bottom_slots_node.get_child_count():
		var slot = bottom_slots_node.get_child(s)
		bottom_slots.append(slot)
	
	## Request spawn for each slot
	if spawn_top:
		for slot in top_slots:
			var rule_override : Dictionary = {
				"spawn_override": slot.position,
				"container_override": temporary_container,
				"property_override": {
					"wait_for_activation": true,
					"timeout_for_flee": 3
				},
				"rotated": -90
			}
			
			top_divers.append( #? Both requests the enemy spawn AND appends the enemy object to top_divers array for further control and release
				threat_generator.generate_threat(entity_id, rule_override)
			)
	
	if spawn_bottom:
		for slot in bottom_slots:
			var rule_override : Dictionary = {
				"spawn_override": slot.position,
				"container_override": temporary_container,
				"property_override": {
					"wait_for_activation": true,
					"timeout_for_flee": 3
				},
				"rotated": 90
			}
			
			bottom_divers.append( #? Both requests the enemy spawn AND appends the enemy object to bottom_divers array for further control and release
				threat_generator.generate_threat(entity_id, rule_override)
			)
	
	## Ready for deployment
	await get_tree().create_timer(release_timeout).timeout
	locked_release = false

func release_attachment(source):
	if is_instance_valid(source):
		source.reparent(scene_enemy_container)
		source.activate()

func _physics_process(delta):
	if drifting:
		global_position.x -= speed * delta
	
	if !locked_release:
		locked_release = true
		var order_size : int
		if spawn_top:
			order_size = top_divers.size()
		elif spawn_bottom:
			order_size = bottom_divers.size()
		
		if release_order < order_size:
			if spawn_top: release_attachment(top_divers[release_order])
			if spawn_bottom: release_attachment(bottom_divers[release_order])
			
			release_order += 1
			
			await get_tree().create_timer(release_timeout).timeout
			locked_release = false
		elif release_order == order_size:
			return
