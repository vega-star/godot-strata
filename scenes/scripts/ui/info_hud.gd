extends CanvasLayer

@onready var message_player = $MessageLayer/MessagePlayer
@onready var danger_player = $MessageLayer/DangerPlayer

func display_title(title, title_description, title_timer : float = 3):
	$TitleDisplay.visible = true
	$TitleDisplay.text = '[center][b]- {0} -[/b]\n\n{1}[/center]'.format({0:title, 1:title_description})
	
	await get_tree().create_timer(title_timer).timeout
	$TitleDisplay.visible = false
	$TitleDisplay.text = ''

func _on_message_displayed():
	print('Message successfully displayed')
