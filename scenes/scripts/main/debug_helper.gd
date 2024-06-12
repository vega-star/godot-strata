extends Node

## Debug Helper
# This singleton is here just to execute debug code and real-time data manipulation via signals and functions, or to print values more easily
# It is basically a sandbox. Use it if absolutely necessary, although most of the time I will not.

func _ready():
	get_viewport().connect("gui_focus_changed", _on_focus_changed)

func _on_focus_changed(control : Control):
	if control: print(control.name)
