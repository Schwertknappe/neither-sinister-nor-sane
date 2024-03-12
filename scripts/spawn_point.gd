extends Marker3D

var already_entered := false

signal spawn_point_entered(spawn_points)

func _on_body_entered(body):
	if !already_entered:
		spawn_point_entered.emit(self)
		already_entered = true

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
