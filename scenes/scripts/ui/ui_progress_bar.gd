extends Control

## Constants
const bar_fadeout_time : float = 3

## Nodes
@onready var progress_bar = $StageProgressBar/Bar
@onready var boss_bar = $BossBar/Bar
@onready var progress_bar_frame = $StageProgressBar/ProgressBarFrame
@onready var bar_start = $StageProgressBar/BarStart
@onready var bar_end = $StageProgressBar/BarEnd
@onready var ui_animation_player = $"../UIAnimations"
@onready var event_container = $StageProgressBar/EventContainer
@onready var event_cursor = $StageProgressBar/EventCursor
@export var debug : bool = false

## Properties
var bar_size
var boss_node
var boss_health_component : HealthComponent

## Icons
const module_bar_template = preload("res://components/modules/module_bar_template.tscn")
const event_node_scene = preload("res://scenes/ui/event_template.tscn")
const events_icons_path = "res://assets/textures/icons/events"
var event_icons : Dictionary = {
	"boss": preload("%s/event_icon_boss.png" % events_icons_path),
	"mini_boss": preload("%s/event_icon_miniboss.png" % events_icons_path),
	"item": preload("%s/event_icon_item.png" % events_icons_path),
	"outpost": preload("%s/event_icon_outpost.png" % events_icons_path),
	"message": preload("%s/event_icon_message.png" % events_icons_path),
	"message_yellow": preload("%s/event_icon_message_yellow.png" % events_icons_path),
	"mysterious_blue": preload("%s/event_icon_mysterious_blue.png" % events_icons_path),
	"mysterious_yellow": preload("%s/event_icon_mysterious_yellow.png" % events_icons_path),
	"mysterious_pink": preload("%s/event_icon_mysterious_pink.png" % events_icons_path),
	"mysterious_purple": preload("%s/event_icon_mysterious_purple.png" % events_icons_path),
	"exclamation_mark": preload("%s/event_icon_exclamation_mark.png" % events_icons_path)
}
var modules : Dictionary = {}

func _ready():
	bar_size = bar_start.position.distance_to(bar_end.position)

func set_boss_bar(new_boss_node):
	boss_node = new_boss_node
	await boss_node.ready
	boss_health_component = boss_node.health_component
	
	# Prepare boss bar
	boss_bar.set_max(boss_health_component.max_health)
	boss_bar.set_value(boss_health_component.max_health)
	boss_health_component.health_change.connect(_update_boss_bar)
	boss_node.enemy_defeated.connect(close_boss_bar)
	
	# Show bar
	ui_animation_player.play_backwards("toggle_progress_bar")
	await ui_animation_player.animation_finished
	ui_animation_player.play("toggle_boss_bar")
	
	# Prepare components bar
	for part in boss_node.weapons_dict:
		var module_bar = module_bar_template.instantiate()
		var module = boss_node.weapons_dict[part]["node"]
		var module_label = module_bar.get_child(0)
		
		modules[module.name] = {
			"node": module,
			"bar": module_bar
		}
		
		module_label.set_text(str(module.name).capitalize())
		module_bar.set_max(module.health_component.max_health)
		module_bar.set_value(module.health_component.max_health)
		module.health_component.health_change.connect(_update_module_bar)
		
		$BossBar/ModulesBars.add_child(module_bar)

func _update_boss_bar(_previous_value : int, new_value : int, _type : bool):
	if !is_instance_valid(boss_health_component): return
	var lives = boss_health_component.lives
	
	print(lives) ## TODO: UPDATE BOSS STAGES
	
	if new_value <= 0:
		boss_bar.set_value(0)
		close_boss_bar()
	else:
		boss_bar.set_value(new_value)

func _update_module_bar(_previous_value : int, new_value : int, _type : bool):
	for m in modules:
		var node = modules[m]["node"]
		var bar = modules[m]["bar"]
		if !is_instance_valid(node):
			return
		var module_health = node.health_component.current_health
		bar.set_value(module_health)

func close_boss_bar():
	ui_animation_player.play_backwards("toggle_boss_bar")
	await ui_animation_player.animation_finished
	ui_animation_player.play("toggle_progress_bar")
	await get_tree().create_timer(bar_fadeout_time).timeout
	for m in $BossBar/ModulesBars.get_children():
		m.call("queue_free")

func display_event(event_data):
	var event = event_node_scene.instantiate()
	var icon_id : String = event_data["icon_id"]
	var timestamp : float = event_data["timestamp"]
	var z_level : int = event_data["z_level"]
	var stage_size = owner.stage_size
	
	event.set_event(
		event_data["event_name"],
		event_data["event_type"],
		event_data["timestamp"],
		event_icons[icon_id],
		event_data["event_description"]
	)
	
	event.set_z_index(z_level)
	event.position.x += bar_size * (timestamp / stage_size)
	
	if debug: print('EVENT: {2} | TIME: {0} | MAX: {1}'.format({0:timestamp, 1:stage_size, 2:event_data["event_name"]}))
	
	event_container.call_deferred("add_child", event)

func clear_events():
	for child in event_container.get_children():
		child.call("queue_free")

func _physics_process(_delta):
	## Move/update Event Cursor
	var progress = (progress_bar.get_max() - progress_bar.get_value())
	event_cursor.position.x = bar_start.position.x + bar_size * (progress / owner.stage_size)
