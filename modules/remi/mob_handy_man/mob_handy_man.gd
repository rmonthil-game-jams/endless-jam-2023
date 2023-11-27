extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty

# MOB SUB PARAMETERS
## WAITING
var HAND_MOVE_DURATION : float
var HAND_MOVE_RADIUS : float
const WAITING_LOOP_NUMBER : int = 4
const MAX_NB_OF_HITS_PER_HAND : int = 4
## ATTACKING
var HAND_ATTACK_DURATION_FACTOR : float 
var HAND_DAMAGE_PER_ATTACK : float 
var HAND_ATTACK_INTERVAL : float 
const KISS_DURATION : float = 2.0
## TODO: NUMBER OF HANDS DEPENDANT OF DIFFICULTY ?

func _set_difficulty(value : float):
	DIFFICULTY = value
	HAND_MOVE_DURATION = 2.0 / (1.0 + log(1.0 + DIFFICULTY))
	HAND_MOVE_RADIUS = min(500.0, 100.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY)))
	HAND_ATTACK_DURATION_FACTOR = 2.0 / (1.0 + log(1.0 + DIFFICULTY))
	HAND_DAMAGE_PER_ATTACK = 1.0 * (1.0 + 0.8*log(1.0 + DIFFICULTY))
	HAND_ATTACK_INTERVAL = 2.0 / (1.0 + 0.8*log(1.0 + DIFFICULTY))
	life_points = 18 + (5 * (1.0 + DIFFICULTY))

# MOB HP BAR
@onready var mob_hp_progress_bar : TextureProgressBar = $MobHPBar/HBoxContainer/MobHpBar

# MOB STATE
var life_points : float = 40.0
var state : String # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var hands : Array[Node] = []
var hands_state : Dictionary = {}
var character : Node = null

## called when the node enters the scene tree for the first time.
func _ready():
	# set difficulty
	_set_difficulty(DIFFICULTY) # REMI: THIS WAS MY BAD, I SHOULD HAVE DONE THAT BEFORE
	# other
	hands = $Hands.get_children()
	for hand in hands:
		# setup state
		hands_state[hand] = {
			"initial_position":hand.position,
			"number_of_hits":0,
			"state":"closed",
			"attack_tween":null
		} # careful here, position is in local coordinate use global_position for global coordinates
		# setup signals
		hand.get_node("TextureButtonOpen").pressed.connect(_hand_open_pressed.bind(hand))
		hand.get_node("TextureButtonClosed").pressed.connect(_hand_closed_pressed.bind(hand))
		hand.get_node("TextureButtonAttacking").pressed.connect(_hand_attacking_pressed.bind(hand))
	character = get_tree().get_nodes_in_group("character").front()
	mob_hp_progress_bar.max_value = life_points
	_set_hp_bar(life_points)
	# avoid using await in the _ready function
	_play_appearing_animation.call_deferred()

func _play_appearing_sound(hand):
	var sound_res = preload("res://modules/remi/assets/audio/used/handy_man/kiss_2.wav")
	var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
	sound_fx.res = sound_res
	hand.add_child(sound_fx)

func _play_appearing_animation():
	# init
	state = "appearing"
	modulate.a = 0.0
	for hand in hands:
		hand.modulate.a = 0.0
	# animation
	main_tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property(self, "scale:y", 1.1, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property(self, "scale:y", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property(self, "scale:x", 1.1, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property(self, "scale:x", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	for hand in hands:
		main_tween.tween_property(hand, "modulate:a", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property(hand, "scale", Vector2(1.1, 1.1), 0.125).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_callback(_play_appearing_sound.bind(hand))
		main_tween.tween_property(hand, "scale", Vector2(1.0, 1.0), 0.125).set_trans(Tween.TRANS_ELASTIC)
	main_tween.tween_property($Body/SpriteRoot, "modulate", Color(0.5, 0.5, 0.5), 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	# open back all hands
	for hand in hands:
		_attempt_to_open_hand(hand)
	# play waiting animation
	_play_waiting_animation.call_deferred()

@onready var sprite_2d_normal : Sprite2D = $Body/SpriteRoot/Sprite2DNormal
@onready var sprite_2d_attacking : Sprite2D = $Body/SpriteRoot/Sprite2DAttacking

func _play_waiting_animation():
	state = "waiting"
	sprite_2d_normal.show()
	sprite_2d_attacking.hide()
	for loop_index in range(WAITING_LOOP_NUMBER):
		main_tween = create_tween()
		if ($Body.rotation <= 0.0):
			main_tween.tween_property($Body, "rotation",  0.125, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
		else:
			main_tween.tween_property($Body, "rotation", -0.125, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
		for hand in hands:
			# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
			var random_vector : Vector2 = Vector2(1.0, 0.0).rotated(randf_range(-PI, PI)) * sqrt(randf_range(0.0, 1.0)) * HAND_MOVE_RADIUS
			var target_position : Vector2 = hands_state[hand]["initial_position"] + random_vector
			main_tween.parallel().tween_property(hand, "position", target_position, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
			main_tween.parallel().tween_property(hand, "rotation", randf_range(-PI, PI), HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
	main_tween = create_tween()
	main_tween.tween_property($Body, "rotation", 0.0, 0.125 * HAND_MOVE_DURATION)
	await main_tween.finished
	_play_attacking_animation.call_deferred()

func _play_attack_hand_sound(hand):
	var sound_res = preload("res://modules/remi/assets/audio/used/handy_man/splash_2.wav")
	var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
	sound_fx.res = sound_res
	hand.add_child(sound_fx)

func _play_attacking_animation():
	state = "attacking"
	main_tween = create_tween()
	main_tween.tween_property($Body, "scale:y", 1.1, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body, "scale:y", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body, "scale:x", 1.1, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body, "scale:x", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	sprite_2d_normal.hide()
	sprite_2d_attacking.show()
	# shuffle randomly the list of hands
	var copy_of_hands : Array[Node] = hands.duplicate()
	copy_of_hands.shuffle()
	# close all rands
	for hand in copy_of_hands:
		_attempt_to_close_hand(hand)
	# attack with hands
	for hand in copy_of_hands:
		$Hands.move_child(hand, hands.size() - 1)
		if hands_state[hand]["attack_tween"]:
			hands_state[hand]["attack_tween"].kill()
		hands_state[hand]["attack_tween"] = create_tween()
		hands_state[hand]["attack_tween"].tween_property(hand, "scale", Vector2(0.8, 0.8), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		hands_state[hand]["attack_tween"].tween_callback(_attempt_to_attack.bind(hand))
		hands_state[hand]["attack_tween"].parallel().tween_callback(_play_attack_hand_sound.bind(hand))
		hands_state[hand]["attack_tween"].tween_property(hand, "scale", Vector2(2.0, 2.0), 0.75 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		hands_state[hand]["attack_tween"].tween_callback(_attempt_damaging_character.bind(hand))
		hands_state[hand]["attack_tween"].tween_callback(_attempt_to_close_hand.bind(hand))
		hands_state[hand]["attack_tween"].tween_property(hand, "scale", Vector2(1.0, 1.0), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
		await get_tree().create_timer(HAND_ATTACK_INTERVAL).timeout
	# open back all hands
	for hand in copy_of_hands:
		_attempt_to_open_hand(hand)
	# change state
	_play_waiting_animation.call_deferred()

func _attempt_to_open_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "open":
		hands_state[hand]["state"] = "open"
		hands_state[hand]["number_of_hits"] = 0
		hand.get_node("TextureButtonOpen").show()
		hand.get_node("TextureButtonClosed").hide()
		hand.get_node("TextureButtonAttacking").hide()
		# add target fx
		var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
		target_fx.w = 273.0
		target_fx.h = 227.0
		target_fx.position = hand.position # carefull these are local coordinates
		add_child(target_fx)

func _attempt_to_close_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "close":
		hands_state[hand]["state"] = "closed"
		hand.get_node("TextureButtonOpen").hide()
		hand.get_node("TextureButtonClosed").show()
		hand.get_node("TextureButtonAttacking").hide()

func _attempt_to_attack(hand : Node2D):
	if not hands_state[hand]["state"] == "attack":
		hands_state[hand]["state"] = "attacking"
		hand.get_node("TextureButtonOpen").hide()
		hand.get_node("TextureButtonClosed").hide()
		hand.get_node("TextureButtonAttacking").show()

func _attempt_damaging_character(hand : Node2D):
	if hands_state[hand]["state"] == "attacking":
		character.hit(HAND_DAMAGE_PER_ATTACK)
		_spawn_kiss.call_deferred(hand)

func _play_close_hand_sound(hand : Node2D):
	var sound_res = preload("res://modules/remi/assets/audio/used/handy_man/cling_3.wav")
	var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
	sound_fx.res = sound_res
	hand.add_child(sound_fx)

func _hand_open_pressed(hand : Node2D):
	_hit(character.damage_per_attack)
	# check number of hits
	hands_state[hand]["number_of_hits"] += 1
	if hands_state[hand]["number_of_hits"] >= MAX_NB_OF_HITS_PER_HAND:
		_play_close_hand_sound(hand)
		_attempt_to_close_hand(hand)

func _hit(damage_points : float):
	life_points -= damage_points
	_set_hp_bar(max(life_points,0))
	_attempt_to_play_hit_animation()
	# TODO: DEATH ANIMATION
	if life_points <= 0.0:
		_attempt_to_play_death_animation()

var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)

var hit_tween : Tween

func _attempt_to_play_hit_animation():
	if not hit_tween or not hit_tween.is_running():
		$Body/SpriteRoot/Sprite2DNormal.hide()
		$Body/SpriteRoot/Sprite2DBeingHit.show()
		hit_tween = create_tween()
		hit_tween.tween_callback($Body/SpriteRoot/Sprite2DNormal.hide)
		hit_tween.tween_callback($Body/SpriteRoot/Sprite2DBeingHit.show)
		hit_tween.tween_property($Body, "modulate", Color(1.0, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
		#hit_tween.parallel().tween_property($Body, "scale", Vector2(1.1, 1.1), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_property($Body, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_callback($Body/SpriteRoot/Sprite2DNormal.show)
		hit_tween.tween_callback($Body/SpriteRoot/Sprite2DBeingHit.hide)

func _play_death_sound():
	var sound_res = preload("res://modules/remi/assets/audio/used/handy_man/waf_3.wav")
	var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
	sound_fx.res = sound_res
	$Body.add_child(sound_fx)

func _attempt_to_play_death_animation():
	if state != "dying":
		state = "dying"
		if main_tween:
			main_tween.kill()
		if hit_tween:
			hit_tween.kill()
			hit_tween = create_tween()
			hit_tween.tween_property($Body, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)
			await hit_tween.finished
		main_tween = create_tween()
		main_tween.tween_callback($Body/SpriteRoot/Sprite2DNormal.hide)
		main_tween.tween_callback($Body/SpriteRoot/Sprite2DBeingHit.show)
		for hand in hands:
			main_tween.tween_property(hand, "position:y", 800.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		main_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_callback(_play_death_sound)
		await main_tween.finished
		just_died.emit()

func _hand_closed_pressed(hand : Node2D):
	pass # TODO: MAYBE DO SOMETHING HERE

func _hand_attacking_pressed(hand : Node2D):
	# add blocked fx
	var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
	blocked_fx.position = hand.position # carefull these are local coordinates
	add_child(blocked_fx)
	# deal with hand anim
	hands_state[hand]["attack_tween"].kill()
	_attempt_to_close_hand(hand)
	hands_state[hand]["attack_tween"] = create_tween()
	hands_state[hand]["attack_tween"].tween_property(hand, "scale", Vector2(1.0, 1.0), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	hands_state[hand]["attack_tween"].tween_callback(_attempt_to_close_hand.bind(hand))

func _spawn_kiss(hand : Node2D):
	var new_kiss : Node2D = preload("res://modules/remi/mob_handy_man/kiss.tscn").instantiate()
	new_kiss.transform = hand.transform
	$Kisses.add_child(new_kiss)
	
	# kiss sound
	var sound_res = preload("res://modules/remi/assets/audio/used/handy_man/kiss_0.wav")
	var sound_fx = preload("res://modules/odilon/fx/one_shot_sound.tscn").instantiate()
	sound_fx.res = sound_res
	new_kiss.add_child(sound_fx)
	
	# tween
	var kiss_tween : Tween = create_tween()
	kiss_tween.tween_property(new_kiss, "modulate:a", 0.0, KISS_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	kiss_tween.tween_callback(new_kiss.queue_free)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
