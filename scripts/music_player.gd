extends AudioStreamPlayer




func _on_fade_out_trigger_body_entered(body):
	if playing and body is Player:
		$Fades.play("fade_out")


func _on_fade_in_trigger_body_entered(body):
	if !playing and body is Player:
		$Fades.play("fade_in")
