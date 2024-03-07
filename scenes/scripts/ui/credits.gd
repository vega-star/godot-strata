extends Control

@export var text : RichTextLabel
@export var container : VBoxContainer

func _on_return_to_main_menu_pressed():
	owner.set_page_position(0, false)
