extends Control

@onready var hp = $UILayer/HUD/HP:
	set(value):
		hp.text = "HP: {0}".format({0:value})
