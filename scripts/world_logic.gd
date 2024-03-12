extends Node

#@export var spawn_points: Array[Node]

var possible_spawn_points: Array[Node]
var entered_spawn_points: Array[Node]

func _ready():
	possible_spawn_points = $SpawnPoints.get_children()
	for point in possible_spawn_points:
		point.spawn_point_entered.connect(increment_entered_spawn_point)
	
	$UI/PauseMenu/Respawn.pressed.connect(respawn_player_at_closest_spawn_point)#.bind(find_closest_spawn_point()))
	$UI/PauseMenu/Respawn.pressed.connect($UI.unpause)


func pause():
	if !get_tree().paused:
		get_tree().paused = true
		$UI/PauseMenu.show()
		$UI/PauseMenu/Continue.grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_pressed("pause"):
		pause()
	
	if Input.is_action_pressed("respawn"):
		#%Player.respawn()
		%Player.respawn_at(find_closest_spawn_point())


func _on_kill_plane_body_entered(_body):
	#%Player.respawn()
	%Player.respawn_at(find_closest_spawn_point())

func find_closest_spawn_point() -> Vector3:
	var nearest_point : Vector3 = Vector3.ZERO
	var shortest_distance = %Player.get_global_position().distance_to(nearest_point)
	
	if !entered_spawn_points.is_empty():
		for point in entered_spawn_points:
			var d = %Player.get_global_position().distance_to(point.get_global_position())
			if d < shortest_distance:
				shortest_distance = d
				nearest_point = point.get_global_position()
	
	return nearest_point

func increment_entered_spawn_point(point : Node):
	entered_spawn_points.push_back(point)

func respawn_player_at_closest_spawn_point():
	%Player.respawn_at(find_closest_spawn_point())
