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
	var music_dir = DirAccess.open(music_dir_path)
	if music_dir:
		music_dir.list_dir_begin()
		var file_name = music_dir.get_next()
		while file_name != "":
			if music_dir.current_is_dir():
				if debug: print("Found directory: " + file_name)
			elif file_name.ends_with(".import"):
				if debug: print("Found, but ignoring file: " + file_name)
			else:
				if debug: print("Found file: " + file_name)
				var file_path = str(music_dir_path + file_name)
				music_list[file_name.left(-4)] = load(file_path)
			
			file_name = music_dir.get_next()
	else:
		print("An error occurred when trying to access the constant path. Have you moved the folder? Check AudioManager.music_dir_path")
	
	var effects_dir = DirAccess.open(effects_dir_path)
	if effects_dir:
		effects_dir.list_dir_begin()
		var file_name = effects_dir.get_next()
		while file_name != "":
			if effects_dir.current_is_dir():
				if debug: print("Found directory: " + file_name)
			elif file_name.ends_with(".import"):
				if debug: print("Ignoring file: " + file_name)
			else:
				if debug: print("Found file: " + file_name)
				var file_path = str(effects_dir_path + file_name)
				effects_list[file_name.left(-4)] = load(file_path)
			
			file_name = effects_dir.get_next()
	else:
		print("An error occurred when trying to access the constant path. Have you moved the folder? Check AudioManager.music_dir_path")


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
