extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	# appear
	modulate.a = 0.0
	var tween : Tween = create_tween()
	tween.tween_property(
		self, 
		"modulate:a",
		1.0,
		1.0
	)
	await  tween.finished
	# progress
	for index in range($Content.get_child_count()):
		$Background/Sprite2D2.show()
		$Background/Sprite2D2.modulate.a = 0.0
		# animation
		tween = create_tween()
		tween.tween_property(
			$Background, 
			"scale",
			Vector2(1.0/$Background/Sprite2D2.scale.x, 1.0/$Background/Sprite2D2.scale.y),
			0.5
		).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_property(
			$Background/Sprite2D2, 
			"modulate:a", 
			1.0,
			0.5
		).set_trans(Tween.TRANS_CUBIC)
		tween.parallel().tween_callback($ChangeRoomSound.play)
		await tween.finished
		# animation
		$Background.position = Vector2.ZERO
		$Background.scale = Vector2.ONE
		$Background/Sprite2D.show()
		$Background/Sprite2D2.hide()
		# sprite init
		var sprite : Node = $Content.get_child(index)
		sprite.modulate.a = 0.0
		sprite.show()
		# appear
		tween = create_tween()
		tween.tween_property(
			sprite,
			"modulate:a", 
			1.0,
			0.25
		).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		# rotate
		tween = create_tween()
		tween.tween_property(
			sprite,
			"scale", 
			1.01 * Vector2.ONE,
			0.125
		).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(
			sprite,
			"scale", 
			0.99 * Vector2.ONE,
			0.125
		).set_trans(Tween.TRANS_CUBIC)
		tween.set_loops(5)
		await tween.finished
		# disappear
		tween = create_tween()
		tween.tween_property(
			sprite,
			"modulate:a", 
			0.0,
			0.25
		).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
	# disappear
	tween = create_tween()
	tween.tween_property(
		self, 
		"modulate:a",
		0.0,
		1.0
	)
	await  tween.finished
	# change scene
	get_tree().change_scene_to_file("res://modules/corentin/menu.tscn")
