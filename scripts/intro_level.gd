extends Node


func _on_load_trigger_body_entered(body) -> void:
	if body is Player:
		Globals.goto_scene("main")
