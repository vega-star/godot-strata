extends Control

func set_focus():
	$ReturnToMainMenu.grab_focus()

func _on_return_to_main_menu_pressed():
	owner.set_page_position(0, false)
