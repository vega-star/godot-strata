extends Node2D

var group_quantity : int

func _ready():
	for q in get_children():
		group_quantity += 1
		q.enemy_died.connect(update_group_quantity)

func update_group_quantity():
	for q in get_children():
		group_quantity += 1
	
	if group_quantity == 0:
		print('GROUP DEFEATED')
