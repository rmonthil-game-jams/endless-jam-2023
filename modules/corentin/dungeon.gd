extends Node2D

@export var MOB_SCENES : Array[PackedScene]
# Called when the node enters the scene tree for the first time.
func _ready():
	# set random state
	randomize()
	$Character.finished_upgrade.connect(_advance)
	# instance a random mob scene
	_advance()

func _advance():
	room += 1
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

	# then instance mob
	var new_mob : Node2D = MOB_SCENES[randi_range(0, MOB_SCENES.size() - 1)].instantiate()
	new_mob.DIFFICULTY = _new_mob_difficulty()
	$RoomContent.add_child(new_mob)
	new_mob.just_died.connect(_on_current_mob_just_died)


@export var KDIFF : float = 1.0
@export var KEXPDIFF : float = 0.1
@export var KSTARTDIFF : float = 1.0

var difficulty : int = 1
var room : int = 0

func _new_mob_difficulty():
	return KDIFF*pow(difficulty+room,1+KEXPDIFF*difficulty)


func _on_current_mob_just_died():
		# clean
	for child in $RoomContent.get_children():
		child.queue_free()
	$Character._loot(room)
	

signal _game_over
func _on_character_just_died():
	_game_over.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
