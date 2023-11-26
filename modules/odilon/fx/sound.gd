extends Node2D

# USAGE:
# Usually if you want to make a sound follow a node, do:
#  var sound_res = preload("res://modules/remi/assets/audio/used/sound.wav")
#  var sound_fx = preload("res://modules/odilon/fx/sound.tscn").instantiate()
#  sound_fx.res = sound_res
#  # sound_fx.position = Vector2.ZERO # carefull these are local coordinates
#  $my_node.add_child(sound_fx)
#
# The more general synthax is:
#  var sound_res = preload("res://modules/remi/assets/audio/used/sound.wav")
#  var sound_fx = preload("res://modules/odilon/fx/sound.tscn").instantiate()
#  sound_fx.res = sound_res
#  sound_fx.position = fx_position # carefull these are local coordinates
#  add_child(sound_fx)

@export var res : Resource

func _ready():
	_play_animation.call_deferred()


func _play_animation():
	if res == null:
		printerr("Sound resource is null. Make sure you called sound_fx.res = ...")
	$AudioStreamPlayer2D.stream = res
	# To ensure correct audio, we have to recenter the player in correct screen coordinates
	$AudioStreamPlayer2D.attenuation = 2
	$AudioStreamPlayer2D.play()
	await $AudioStreamPlayer2D.finished
	queue_free()
