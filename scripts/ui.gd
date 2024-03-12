extends Control

var started = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var startscreen = get_node_or_null("StartMenu")
	if startscreen:
		$StartMenu/Start.grab_focus()
	else:
		$FocusGrabber.grab_focus()

func _on_settings_pressed():
	$PauseMenu.hide()
	$Settings.show()
	$Settings/MarginContainer/VBoxContainer/HBoxContainer/BackButton.grab_focus()


func _on_back_button_pressed():
	$Settings.hide()
	var startscreen = get_node_or_null("StartMenu")
	if startscreen and !started:
		$StartMenu.show()
		$StartMenu/Start.grab_focus()
	else:
		$PauseMenu.show()
		$PauseMenu/Continue.grab_focus()


func _on_startmenu_settings_pressed():
	$StartMenu.hide()
	$Settings.show()
	$Settings/MarginContainer/VBoxContainer/HBoxContainer/BackButton.grab_focus()


func unpause():
	$FocusGrabber.grab_focus()
	get_tree().paused = false
	$PauseMenu.hide()
	var startscreen = get_node_or_null("StartMenu")
	if startscreen:
		if startscreen.visible:
			$StartMenu.hide()
			started = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func quit():
	get_tree().quit()

