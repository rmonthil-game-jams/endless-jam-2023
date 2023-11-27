extends Node2D

# USAGE:
# Usually if you want to make a sound follow a node, do:
#  var sound_res = preload("res://modules/remi/assets/audio/used/sound.wav")
#  var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
#  sound_fx.res = sound_res
#  # sound_fx.position = Vector2.ZERO # carefull these are local coordinates
#  $my_node.add_child(sound_fx)
#
# The more general synthax is:
#  var sound_res = preload("res://modules/remi/assets/audio/used/sound.wav")
#  var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
#  sound_fx.res = sound_res
#  sound_fx.position = fx_position # carefull these are local coordinates
#  add_child(sound_fx)

@export var res : Resource

func _ready():
	_play_animation.call_deferred()


func _play_animation():
	if res == null:
		printerr("Sound resource is null. Make sure you called sound_fx.res = ...")
	$NormalizedSound.stream = res
	$NormalizedSound.play()
	await $NormalizedSound.finished
	queue_free()
