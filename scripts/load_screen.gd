extends Control

var progress = []
var scene_load_status = 0

func _ready():
	ResourceLoader.load_threaded_request(Globals.next_scene)

func _process(_delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(Globals.next_scene, progress)
	$ProgressBar.set_value(progress[0]*100)
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(Globals.next_scene)
		get_tree().change_scene_to_packed(new_scene)

