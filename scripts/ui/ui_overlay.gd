extends Control

var cell_size : int = 26

#@onready var hp = $UILayer/HUD/HP:
#	set(value):
#		hp.text = "HP: {0}".format({0:value})

@onready var hp = $UILayer/HUD/HP_Container:
	set(value):
		hp.size.x = value * cell_size
