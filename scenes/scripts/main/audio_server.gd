extends Node

const pitch_bend_delay = 0.5
const effects_dir_path = "res://assets/audio/effects/"
const music_dir_path = "res://assets/audio/music/"

@onready var global_effect_player = $GlobalEffectPlayer
@onready var effect_player = $EffectPlayer
@onready var music_player = $MusicPlayer
@export var loop_music : bool = true
@export var debug : bool = false

var pause_tween : Tween
var effects_list : Dictionary = {}
var music_list : Dictionary = {}

func _ready():
	load_from_dir(music_list, music_dir_path)
	load_from_dir(effects_list, effects_dir_path)

## Loads all files from a directory into an dictionary, with the name of the file as key and a loaded resource object as value.
## Use this function to load sounds and not bother manually adding new sounds to a constant dict.
func load_from_dir(target_dict : Dictionary, dir_path):
	var source_dir = DirAccess.open(dir_path)
	if source_dir:
		source_dir.list_dir_begin()
		var file_name = source_dir.get_next()
		while file_name != "":
			if source_dir.current_is_dir(): pass # Found directory, skip.
			elif file_name.ends_with(".import"): # Found an import file
				var file = file_name.split(".import")
				if target_dict.has(file[0]): pass # File was already loaded, skipping.
				else: # File not detected, thus loaded normally
					var file_path = str(dir_path + file[0] + file[1])
					target_dict[file[0].left(-4)] = load(file_path)
			else: # Found normal file
				pass
			
			file_name = source_dir.get_next() # Pass to next
	else:
		printerr("An error occurred when trying to access the constant path. Have you moved the folder? Check if path %s exists." % dir_path)

func set_pause(value):
	if pause_tween: 
		pause_tween.kill()
	
	pause_tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var target_value : float
	
	if value: 
		target_value = 0.1
	else: 
		target_value = 1.0
	
	pause_tween.tween_property(
		music_player,
		"pitch_scale",
		target_value,
		pitch_bend_delay
	)
	
	await pause_tween.finished
	music_player.stream_paused = value

func set_music(music_id):
	music_player.stream = music_list[music_id]
	music_player.play()

func emit_sound_effect(position, effect_id, request : bool = false, interrupt : bool = false):
	var player
	if position is Vector2: 
		player = effect_player
		player.position = position
	else: 
		player = global_effect_player
	
	if player.playing and request:
		await Signal(player, "finished")
	
	if player.playing and interrupt:
		player.stop()
	
	player.stream = effects_list[effect_id]
	
	player.play()

func _on_music_finished():
	if loop_music: music_player.play()
