extends Control

@onready var MASTER_BUS_ID = AudioServer.get_bus_index("Master")
@onready var SFX_BUS_ID = AudioServer.get_bus_index("SFX")
@onready var MUSIC_BUS_ID = AudioServer.get_bus_index("Music")

var Resolutions: Dictionary = {"3840x2160": Vector2i(3840,2160),
								"2560x1440": Vector2i(2560,1440),
								"1920x1080": Vector2i(1920,1080),
								"1600x900": Vector2i(1600,900),
								"1280x720": Vector2i(1280,720),
								"800x600": Vector2i(800,600),
								"640x360": Vector2i(640,360) }

var fullscreen = false
var fullscreen_changed = false
var vsync = false
var vsync_changed = false
var resolutionID
var resolution_changed = false

func _input(event):
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			%ScrollContainer.scroll_vertical -= 1.0
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			%ScrollContainer.scroll_vertical += 1.0


# Called when the node enters the scene tree for the first time.
func _ready():
	%BackButton.grab_focus()
	add_resolutions()


func _process(_delta):
	var look_dir_x = Input.get_axis("look_up", "look_down")
	%ScrollContainer.scroll_vertical += look_dir_x*2


func add_resolutions():
	for r in Resolutions:
		%ResolutionOptionButton.add_item(r)

func centre_window():
	var centre_screen = DisplayServer.screen_get_position()+DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().position = centre_screen-window_size/2

func _on_music_slider_value_changed(value):
	AudioServer.set_bus_volume_db(MUSIC_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MUSIC_BUS_ID, value < .05)

func _on_sfx_slider_value_changed(value):
	AudioServer.set_bus_volume_db(SFX_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(SFX_BUS_ID, value < .05)

func _on_master_slider_value_changed(value):
	AudioServer.set_bus_volume_db(MASTER_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MASTER_BUS_ID, value < .05)

func _on_fullscreen_check_box_toggled(toggled_on):
	fullscreen_changed = true
	if toggled_on:
		fullscreen = true
	else:
		fullscreen = false

func _on_vsync_check_box_toggled(toggled_on):
	vsync_changed = true
	if toggled_on:
		vsync = true
	else:
		vsync = false

func _on_resolution_item_selected(index):
	var ID = %ResolutionOptionButton.get_item_text(index)
	resolutionID = Resolutions[ID]
	resolution_changed = true

func _on_roll_anim_check_box_toggled(toggled_on):
	Globals.roll_anim_enabled = toggled_on

func _on_controller_sensitivity_slider_value_changed(value):
	Globals.controller_sensitivity = value

func _on_mouse_sensitivity_slider_value_changed(value):
	Globals.mouse_sensitivity = value

func _on_default_button_pressed():
	%ControllerSensitivitySlider.value = 250
	Globals.controller_sensitivity = 250
	%MouseSensitivitySlider.value = 0.24
	Globals.mouse_sensitivity = 0.24
	
	%MusicSlider.value = 1.0
	%SFXSlider.value = 1.0
	%MasterSlider.value = 1.0
	AudioServer.set_bus_volume_db(MUSIC_BUS_ID, linear_to_db(1.0))
	AudioServer.set_bus_volume_db(SFX_BUS_ID, linear_to_db(1.0))
	AudioServer.set_bus_volume_db(MASTER_BUS_ID, linear_to_db(1.0))
	
	get_window().size = Resolutions["1280x720"]
	%FullscreenCheckBox.button_pressed = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	%ResolutionOptionButton.disabled = true
	
	%VSyncCheckBox.button_pressed = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	
	vsync_changed = false
	fullscreen_changed = false
	resolution_changed = false

func _on_apply_button_pressed():
	if vsync_changed:
		if vsync:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if resolution_changed:
		get_window().size = resolutionID
		centre_window()
	
	if fullscreen_changed:
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			%ResolutionOptionButton.disabled = true
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			%ResolutionOptionButton.disabled = false
			centre_window()
	
	vsync_changed = false
	fullscreen_changed = false
	resolution_changed = false


