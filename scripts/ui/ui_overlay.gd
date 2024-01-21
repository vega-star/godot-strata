extends Control

var cell_size : int = 26

#@onready var hp = $UILayer/HUD/HP: # Old method to text
#	set(value):
#		hp.text = "HP: {0}".format({0:value})

@onready var hp = $UILayer/HUD/HP_Container:
	set(value):
		hp.size.x = value * cell_size

@onready var stage_progress = $UILayer/HUD/StageProgressBar:
	set(value):
		stage_progress.value = value
