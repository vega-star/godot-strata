extends CanvasLayer

@onready var info_layer = $InfoLayer
@onready var info_container = $InfoLayer/InfoContainer
@onready var message_player = $InfoLayer/MessagePlayer
@onready var danger_player = $InfoLayer/DangerPlayer

func display_title(title, title_description, title_timer : float = 3):
	$TitleDisplay.visible = true
	$TitleDisplay.text = '[center][b]- {0} -[/b]\n\n{1}[/center]'.format({0:title, 1:title_description})
	
	await get_tree().create_timer(title_timer, false).timeout
	$TitleDisplay.visible = false
	$TitleDisplay.text = ''

func display_danger(direction : bool, horizontal : bool = true, timeout : float = 4, modulate_color : Color = Color.WHITE):
	danger_player.display_danger(direction, horizontal, timeout, modulate_color)

func _on_message_displayed():
	var visibility : bool = true
	if !self.visible or !info_layer.visible: visibility = false
	
	if !visibility: 
		visible = true
		info_layer.visible 

func toggle_message_layer(toggle):
	info_layer.visible = toggle
