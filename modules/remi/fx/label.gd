extends Node2D

# USAGE:

#var label_fx = preload("res://modules/remi/fx/label.tscn").instantiate()
#label_fx.position = Vector2(get_viewport_rect().size.x/2.0, get_viewport_rect().size.y - 20.0) # carefull these are local coordinates
#label_fx.COLOR = Color(1.0, 0.6, 0.6)
#label_fx.TEXT = "- " + str(snapped(damge_points, 0.1))
#$CanvasLayerOverlay.add_child(label_fx)

# parameters
var TEXT : String
var COLOR : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	# set parameters
	$Label.text = TEXT
	$Label.add_theme_color_override("font_color", COLOR)
	modulate.a = 0.0
	# play animation
	_play_animation.call_deferred()

func _play_animation():
	# animation
	var tween_modulate : Tween = create_tween()
	tween_modulate.tween_property(self, "modulate:a", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	tween_modulate.tween_property(self, "modulate:a", 0.0, 0.375).set_trans(Tween.TRANS_CUBIC)
	var tween_position : Tween = create_tween()
	tween_position.parallel().tween_property(self, "position:y", position.y - 100.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween_position.finished
	queue_free()
