extends Control

func _input(event):
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true
	$Start.grab_focus()
