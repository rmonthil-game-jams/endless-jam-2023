extends Node2D

# USAGE:

# var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
# blocked_fx.position = fx_position # carefull these are local coordinates
# add_child(blocked_fx)

# Called when the node enters the scene tree for the first time.
func _ready():
	_play_animation.call_deferred()

func _play_animation():
	# init
	$Sprite2D.scale = Vector2.ZERO
	$Sprite2D.modulate.a = 1.0
	# animation
	var tween : Tween = create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2.ONE, 0.125).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	# free
	await tween.finished
	queue_free()
