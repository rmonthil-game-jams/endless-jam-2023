extends Node2D

# USAGE:

# var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
# blocked_fx.TARGET_SCALE = Vector2.ONE
# blocked_fx.position = fx_position # carefull these are local coordinates
# add_child(blocked_fx)

var TARGET_SCALE : Vector2 = Vector2.ONE

# Called when the node enters the scene tree for the first time.
func _ready():
	_play_animation.call_deferred()

func _play_animation():
	# Launch sound at spawn time
	var sound_res = preload("res://modules/remi/assets/audio/aok_4.wav") # Find a better sound for this ? (not reserved for now)
	var sound_fx = preload("res://modules/odilon/fx/sound.tscn").instantiate()
	sound_fx.res = sound_res
	add_child(sound_fx)
	
	# init
	$Sprite2D.scale = Vector2.ZERO
	$Sprite2D.modulate.a = 1.0
	# animation
	var tween : Tween = create_tween()
	tween.tween_property($Sprite2D, "scale", TARGET_SCALE, 0.125).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.175).set_trans(Tween.TRANS_CUBIC)
	# free
	await tween.finished
	queue_free()
