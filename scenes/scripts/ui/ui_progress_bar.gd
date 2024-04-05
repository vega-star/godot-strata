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

## Properties
var bar_size
var boss_health_component : HealthComponent

## Icons
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

func _ready():
	bar_size = bar_start.position.distance_to(bar_end.position)

func set_boss_bar(boss_node):
	ui_animation_player.play("toggle_boss_bar")
	boss_health_component = boss_node.health_component
	
	boss_bar.set_max_value(boss_health_component.max_health)
	boss_bar.set_value(boss_health_component.max_health)
	
	boss_health_component.health_change.connect(_update_boss_bar)

func _update_boss_bar(_previous_value : int, new_value : int, _type : bool):
	if !is_instance_valid(boss_health_component): return
	var lives = boss_health_component.lives
	
	print(lives) ## TODO: UPDATE BOSS STAGES
	
	if new_value <= 0:
		boss_bar.set_value(0)
		
		await get_tree().create_timer(bar_fadeout_time).timeout
		ui_animation_player.play_backwards("toggle_boss_bar")
	else:
		boss_bar.set_value(new_value)

func display_event(event_data):
	var event = Sprite2D.new()
	var icon_id : String = event_data["icon_id"]
	var timestamp : float = event_data["timestamp"]
	var z_level : int = event_data["z_level"]
	var stage_size = owner.stage_size
	
	event.set_texture(event_icons[icon_id])
	event.set_z_index(z_level)
	event.position.x += bar_size * (timestamp / stage_size)
	
	print('EVENT: {2} | TIME: {0} | MAX: {1}'.format({0:timestamp, 1:stage_size, 2:event_data["event_name"]}))
	
	event_container.call_deferred("add_child", event)

func _physics_process(_delta):
	event_cursor.position.x = bar_start.position.x + bar_size * ((progress_bar.get_max() - progress_bar.get_value()) * 6 / bar_size)
