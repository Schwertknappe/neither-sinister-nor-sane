extends Node

func play_sound(stream : AudioStream, volume : float):
	var instance = AudioStreamPlayer.new()
	instance.stream = stream
	instance.set_volume_db(volume)
	instance.set_bus("SFX")
	add_child(instance)
	instance.play()
	await instance.finished
	instance.queue_free()

