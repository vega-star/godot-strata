extends Control

func _on_return_to_main_menu_pressed():
	owner.set_page_position(0)

func _on_name_prompt_text_submitted(new_text):
	print(new_text)
	
	$NewProfileTab.visible = false
	$NewProfileTab/NamePrompt.text = ''
