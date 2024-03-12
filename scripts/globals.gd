extends Node

var roll_anim_enabled := true
var mouse_sensitivity := 0.24
var controller_sensitivity := 250

var next_scene

var intro = "intro"
var main = "main"
var Scenes : Dictionary = {intro : "res://scenes/Levels/intro_level.tscn",
							main : "res://scenes/Levels/main_level.tscn" }


#func goto_scene(scene_name):
#	next_scene = Scenes[scene_name]
#	var load_screen = load("res://scenes/UI/load_screen.tscn")
#	get_tree().change_scene_to_packed.call_deferred(load_screen)


var current_scene = null

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)


func goto_scene(name):
	next_scene = Scenes[name]
	call_deferred("_deferred_goto_scene")

func _process(delta):
	current_scene = get_tree().current_scene


func _deferred_goto_scene():
	# It is now safe to remove the current scene.
	current_scene.free()
	# Load the new scene.
	var s
	if next_scene == Scenes[intro]:
		s = ResourceLoader.load(next_scene)
	else:
		s = ResourceLoader.load("res://scenes/UI/load_screen.tscn")

	# Instance the new scene.
	current_scene = s.instantiate()
	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)
	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene


