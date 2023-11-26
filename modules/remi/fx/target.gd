extends Node2D

# USAGE:

# var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
# target_fx.position = fx_position # carefull these are local coordinates
# target_fx.w = fx_w
# target_fx.h = fx_h
# add_child(target_fx)

const INITIAL_DISTANCE : float = 200.0

var w : float
var h : float

var play_sound : bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	_play_animation.call_deferred()

func _play_animation():
	# init
	$UpLeft.modulate.a = 0.0
	$UpLeft.position = Vector2(-0.5*w, -0.5*h) + Vector2(-0.5*w, -0.5*h).normalized() * INITIAL_DISTANCE
	$UpRight.position = Vector2(0.5*w, -0.5*h) + Vector2(0.5*w, -0.5*h).normalized() * INITIAL_DISTANCE
	$DownLeft.position = Vector2(-0.5*w, 0.5*h) + Vector2(-0.5*w, 0.5*h).normalized() * INITIAL_DISTANCE
	$DownRight.position = Vector2(0.5*w, 0.5*h) + Vector2(0.5*w, 0.5*h).normalized() * INITIAL_DISTANCE
	
	# Play sound at that moment for now
	_play_sound()
	
	# animation
	var tween_up_left : Tween = create_tween()
	tween_up_left.tween_property($UpLeft, "position", Vector2(-0.5*w, -0.5*h), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween_up_left.parallel().tween_property($UpLeft, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_up_left.tween_property($UpLeft, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	# animation
	var tween_up_right : Tween = create_tween()
	tween_up_right.tween_property($UpRight, "position", Vector2(0.5*w, -0.5*h), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween_up_right.parallel().tween_property($UpRight, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_up_right.tween_property($UpRight, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	# animation
	var tween_down_left : Tween = create_tween()
	tween_down_left.tween_property($DownLeft, "position", Vector2(-0.5*w, 0.5*h), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween_down_left.parallel().tween_property($DownLeft, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_down_left.tween_property($DownLeft, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	# animation
	var tween_down_right : Tween = create_tween()
	tween_down_right.tween_property($DownRight, "position", Vector2(0.5*w, 0.5*h), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween_down_right.parallel().tween_property($DownRight, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_down_right.tween_property($DownRight, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	# free
	await tween_up_left.finished
	queue_free()

func _play_sound():
	# If we want to launch another custom sound, specify to not play sound
	if play_sound:
		$DefaultAudioStreamPlayer2D.play()
