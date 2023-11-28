extends Node2D

@export var MOB_SCENES : Array[PackedScene]
@export var BOSS_SCENES : Array[PackedScene]

@onready var available_mob_indexs : Array = range(MOB_SCENES.size())
@onready var available_boss_indexs : Array = range(BOSS_SCENES.size())

# Called when the node enters the scene tree for the first time.
func _ready():
	# set random state
	randomize()
	available_mob_indexs.shuffle()
	available_boss_indexs.shuffle()
	$Character.finished_upgrade.connect(_advance)
	# instance a random mob scene
	_advance()

@export var BOSS_ROOM_PERIOD : int
func _advance():
	room += 1
	
	# switch depending of room
	if room % BOSS_ROOM_PERIOD:
		$Background/Sprite2D2.show()
		$Background/Sprite2D2.modulate.a = 0.0
	else:
		$Background/Sprite2D2Boss0.show()
		$Background/Sprite2D2Boss0.modulate.a = 0.0
	
	# animation
	var tween : Tween = create_tween()
	tween.tween_property(
		$Background, 
		"scale",
		Vector2(1.0/$Background/Sprite2D2.scale.x, 1.0/$Background/Sprite2D2.scale.y),
		1.0
	).set_trans(Tween.TRANS_CUBIC)
	if room % BOSS_ROOM_PERIOD:
		tween.parallel().tween_property(
			$Background/Sprite2D2, 
			"modulate:a", 
			1.0,
			1.0
		).set_trans(Tween.TRANS_CUBIC)
	else:
		tween.parallel().tween_property(
			$Background/Sprite2D2Boss0, 
			"modulate:a", 
			1.0,
			1.0
		).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_callback($ChangeRoomSound.play)
	await tween.finished
	$Background.position = Vector2.ZERO
	$Background.scale = Vector2.ONE
	if room % BOSS_ROOM_PERIOD:
		$Background/Sprite2D.show()
		$Background/Sprite2DBoss0.hide()
		$Background/Sprite2D2.hide()
	else:
		$Background/Sprite2DBoss0.show()
		$Background/Sprite2D.hide()
		$Background/Sprite2D2Boss0.hide()

	# then instance mob
	var new_mob : Node2D
	if room % BOSS_ROOM_PERIOD:
		var mob_index : int = available_mob_indexs.pop_back()
		new_mob = MOB_SCENES[mob_index].instantiate()
		new_mob.DIFFICULTY = _new_mob_difficulty()
		if available_mob_indexs.size() < 1:
			available_mob_indexs = range(MOB_SCENES.size())
			if MOB_SCENES.size()>1:
				available_mob_indexs.pop_at(mob_index) # avoid getting the same mob twice in a row
			available_mob_indexs.shuffle()
	else:
		var mob_index : int = available_boss_indexs.pop_back()
		new_mob = BOSS_SCENES[mob_index].instantiate()
		new_mob.DIFFICULTY = _new_mob_difficulty() * KBOSSDIFF
		if available_boss_indexs.size() < 1:
			available_boss_indexs = range(BOSS_SCENES.size())
			if BOSS_SCENES.size()>1:
				available_boss_indexs.pop_at(mob_index) # avoid getting the same mob twice in a row
			available_boss_indexs.shuffle()
	
	var CLIC_CLIC_DELAY : float = 0.1
	if "SOUND_SPAWN_DELAY" in new_mob:
		CLIC_CLIC_DELAY += new_mob.SOUND_SPAWN_DELAY
		print("Added delay: ", new_mob.SOUND_SPAWN_DELAY)
	BackgroundMusic.play_combat(CLIC_CLIC_DELAY)

	$RoomContent.add_child(new_mob)
	new_mob.just_died.connect(_on_current_mob_just_died)


@export var KDIFF : float
@export var KEXPDIFF : float
@export var KSTARTDIFF : float
@export var KBOSSDIFF : float
@export var BOSS_LOOT_BUFF : float

var difficulty : int = 1
var room : int = 0

func _new_mob_difficulty():
	return KDIFF*pow(KSTARTDIFF*difficulty+room,1.0+KEXPDIFF*difficulty)


func _on_current_mob_just_died():
	BackgroundMusic.play_upgrade_menu()
		# clean
	for child in $RoomContent.get_children():
		child.queue_free()
	var lootbuff
	if room % BOSS_ROOM_PERIOD:
		lootbuff = 0
	else:
		lootbuff = BOSS_LOOT_BUFF
	$Character._loot(lootbuff, room)
	

signal _game_over
func _on_character_just_died():
	_game_over.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
