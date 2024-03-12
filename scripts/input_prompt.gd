class_name InputPrompt3D extends Node3D

@export var keyboard_sprite : Texture
@export var xbox_sprite : Texture
@export var ps_sprite : Texture
@export var switch_sprite : Texture

func _ready() -> void:
	var guessed_device_name = InputHelper.guess_device_name()
	set_sprite(guessed_device_name)
	InputHelper.device_changed.connect(_on_input_device_changed)

func _on_input_device_changed(device: String, _device_index: int) -> void:
	set_sprite(device)

func set_sprite(device: String):
	if device == InputHelper.DEVICE_KEYBOARD:
		$Sprite3D.set_texture(keyboard_sprite)
	elif device == InputHelper.DEVICE_PLAYSTATION_CONTROLLER:
		$Sprite3D.set_texture(ps_sprite)
	elif device == InputHelper.DEVICE_SWITCH_CONTROLLER:
		$Sprite3D.set_texture(switch_sprite)
	else:
		$Sprite3D.set_texture(xbox_sprite)
