extends Node

signal progress_changed(progress)
signal load_completed

const _loading_scene_path : String = "res://scenes/loading_scene.tscn"
var _loading_scene = load(_loading_scene_path)
var _loaded_resource : PackedScene
var _scene_path : String
var _progress : Array = []

var use_sub_threads : bool = false

func _ready():
	set_process(false)

func load_scene(next_scene):
	_scene_path = next_scene
	
	## Control game components
	UI.set_pause(false)
	UI.UIOverlay.bars.reset_bars()
	
	## Load scene start
	var loading_screen = _loading_scene.instantiate()
	get_tree().get_root().call_deferred("add_child", loading_screen)
	self.progress_changed.connect(loading_screen._update_progress_bar)
	self.load_completed.connect(loading_screen._start_outro_animation)
	
	await Signal(loading_screen, "loading_screen_has_full_coverage")
	start_load()

func reload_scene(): load_scene(_scene_path)

func start_load():
	var state = ResourceLoader.load_threaded_request(_scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)

func _process(_delta):
	var load_status = ResourceLoader.load_threaded_get_status(_scene_path, _progress)
	
	match load_status:
		0, 2: #? THREAD_LOAD_INVALID_RESOURCE, THREAD_LOAD_FAILED
			set_process(false)
			printerr("ERROR LOADING SCENE | Scene path may be wrong or invalid")
			return
		1: #? THREAD_LOAD_IN_PROGRESS
			emit_signal("progress_changed", _progress[0])
		3: #? THREAD_LOAD_LOADED
			_loaded_resource = ResourceLoader.load_threaded_get(_scene_path)
			emit_signal("progress_changed", 1.0)
			emit_signal("load_completed")
			get_tree().change_scene_to_packed(_loaded_resource)
			
			set_process(false)
