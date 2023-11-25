extends Node2D

@export var MOB_SCENES : Array[PackedScene]
var difficulty : int = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	# set random state
	randomize()
	# instance a random mob scene
	_advance()

func _advance():
	$Background/Sprite2D2.show()
	$Background/Sprite2D2.modulate.a = 0.0
	# animation
	var tween : Tween = create_tween()
	tween.tween_property(
		$Background, 
		"scale",
		Vector2(1.0/$Background/Sprite2D2.scale.x, 1.0/$Background/Sprite2D2.scale.y),
		1.0
	).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(
		$Background/Sprite2D2, 
		"modulate:a", 
		1.0,
		1.0
	).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	$Background.position = Vector2.ZERO
	$Background.scale = Vector2.ONE
	$Background/Sprite2D2.hide()
	# clean
	for child in $RoomContent.get_children():
		child.queue_free()
	# then instance mob
	var new_mob : Node2D = MOB_SCENES[randi_range(0, MOB_SCENES.size() - 1)].instantiate()
	$RoomContent.add_child(new_mob)
	new_mob.just_died.connect(_on_current_mob_just_died)

func _on_current_mob_just_died():
	_advance()
	

signal _game_over
func _on_character_just_died():
	_game_over.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
