extends Node2D

#func _ready():
#	play_flying()
#	await get_tree().create_timer(1.0).timeout
#	stop_flying()

func play_flying():
	_play_flame()
	_play_rotation()
	_play_translation()

func stop_flying():
	tween_flame.kill()
	tween_rotation.kill()
	tween_translation.kill()
	# tween
	var tween : Tween
	# back to normal state
	tween = create_tween()
	tween.tween_property($AnchorCenter/AnchorFront/Flame, "scale", Vector2(0.0, 1.5), 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($AnchorCenter, "rotation", 0.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($AnchorCenter, "position", Vector2.ZERO, 0.125).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	# play animation
	tween = create_tween()
	tween.tween_property($AnchorCenter/AnchorFront, "scale", Vector2(0.5, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($AnchorCenter/AnchorFront, "rotation", 0.25 * PI, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($AnchorCenter/AnchorFront, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property($AnchorCenter/AnchorFront, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tween.finished

var tween_flame : Tween
func _play_flame():
	tween_flame = create_tween()
	tween_flame.tween_property($AnchorCenter/AnchorFront/Flame, "scale", Vector2(1.25, 0.75 * 1.5), 0.125).set_trans(Tween.TRANS_ELASTIC)
	tween_flame.tween_property($AnchorCenter/AnchorFront/Flame, "scale", Vector2(1.0, 1.0 * 1.5), 0.125).set_trans(Tween.TRANS_CUBIC)
	await tween_flame.finished
	_play_flame.call_deferred()

var tween_rotation : Tween
func _play_rotation():
	tween_rotation = create_tween()
	tween_rotation.tween_property($AnchorCenter, "rotation", -0.0625, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_rotation.tween_property($AnchorCenter, "rotation", 0.0625, 0.25).set_trans(Tween.TRANS_CUBIC)
	await tween_rotation.finished
	_play_rotation.call_deferred()

var tween_translation : Tween
func _play_translation():
	tween_translation = create_tween()
	tween_translation.tween_property($AnchorCenter, "position", Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween_translation.tween_property($AnchorCenter, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween_translation.finished
	_play_translation.call_deferred()
