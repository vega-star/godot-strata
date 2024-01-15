extends Control

@onready var hp = $HP:
	set(value):
		hp.text = "HP: {0}".format({0:value})
