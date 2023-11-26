extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty

# MOB SUB PARAMETERS
## WAITING
"""
var HAND_MOVE_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var HAND_MOVE_RADIUS : float = min(400.0, 50.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY)))
const IDLE_LOOP_NUMBER : int = 4
"""
## ATTACKING

var HAND_ATTACK_DURATION_FACTOR : float
var DAMAGE_PER_ATTACK_P1 : float
var DAMAGE_PER_ATTACK_P2 : float
var TIME_BETWEEN_ATTACKS_P1 : float
var X_MARGIN : int = 50
var Y_MARGIN : int = 50
var ATTACK_WINDOW_RANGE : Vector2
var ATTACK_SCALE : Vector2 = Vector2(1.0, 1.0) # REMI: TRY TO AVOID RESCALING IMAGES PERMANENTLY

func _set_difficulty(value : float): # REMI: THIS WAS MY BAD, I SHOULD HAVE DONE THAT BEFORE
	DIFFICULTY = value
	HAND_ATTACK_DURATION_FACTOR = 1.0 / (1.0 + log(1.0 + DIFFICULTY))
	DAMAGE_PER_ATTACK_P1 = 1.0 / (1.0 + log(1.0 + DIFFICULTY))
	DAMAGE_PER_ATTACK_P2 = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	TIME_BETWEEN_ATTACKS_P1 = 2.0 * (1.0 + log(1.0 + DIFFICULTY))
	life_points = 10 + (10 * log(1.0 + DIFFICULTY))

# MOB STATE
var life_points : float = 20.0
var state : String # useles at the moment but who knows in the future?

# private

# REMI: MOB HP BAR
@onready var mob_hp_progress_bar : TextureProgressBar = $MobHPBar/HBoxContainer/MobHpBar

## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var bodies : Array[Node] = []
var attacks : Array[Node] = []
var hands_state : Dictionary = {}
var character : Node = null
var rng = RandomNumberGenerator.new()

## called when the node enters the scene tree for the first time.
func _ready():
	# set difficulty
	_set_difficulty(DIFFICULTY) # REMI: THIS WAS MY BAD, I SHOULD HAVE DONE THAT BEFORE
	
	character = get_tree().get_nodes_in_group("character").front()
	# other
	ATTACK_WINDOW_RANGE = (get_viewport_rect().size - 2*Vector2(X_MARGIN,Y_MARGIN))/2
	$Body.get_node("TextureButtonP1").pressed.connect(_body_attacks.bind(DAMAGE_PER_ATTACK_P1))
	$AttackP1.get_node("TextureButtonAttackP1").pressed.connect(_block_attack.bind())
	bodies = $Body.get_children()
	for body in bodies:
		body.hide()
	attacks = $AttackP1.get_children()
	for attack in attacks:
		attack.hide()
	# REMI: hp bar
	mob_hp_progress_bar.max_value = life_points
	_set_hp_bar(life_points)
#	hands = $Hands.get_children()
#	for hand in hands:
#		# setup state
#		hands_state[hand] = {
#			"initial_position":hand.position,
#			"state":"open",
#		} # careful here, position is in local coordinate use global_position for global coordinates
#		# setup signals
#		hand.get_node("TextureButtonOpen").pressed.connect(_hand_open_pressed.bind(hand))
#		hand.get_node("TextureButtonClosed").pressed.connect(_hand_closed_pressed.bind(hand))
#		hand.get_node("TextureButtonAttacking").pressed.connect(_hand_attacking_pressed.bind(hand))
#	character = get_tree().get_nodes_in_group("character").front()
	# avoid using await in the _ready function
	_play_appearing_animation.call_deferred()
	

#
func _play_appearing_animation():
	# init
	$Body/Sprite2DPhase1.show()
	state = "appearing"
	modulate.a = 0.0
	# animation
	main_tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	_phase_1()
	
func _phase_1():
	state = "phase_1"
	$Body/TextureButtonP1.show()
	$Body/Sprite2DPhase1.hide()
	
	# add target fx
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 394.0
	target_fx.h = 359.0
	target_fx.position = $Body.position # carefull these are local coordinates
	add_child(target_fx)
	
	await get_tree().create_timer(TIME_BETWEEN_ATTACKS_P1).timeout
	_phase_1_attack()
	

func _phase_1_attack():
	$Body/Sprite2DAtttackingP1.show()
	$Body/TextureButtonP1.hide()
	$AttackP1.position = Vector2(rng.randf_range(-ATTACK_WINDOW_RANGE[0], ATTACK_WINDOW_RANGE[0]), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
	$AttackP1/TextureButtonAttackP1.show()
	
	# REMI: target fx
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 421.0
	target_fx.h = 348.0
	target_fx.position = $AttackP1.position # carefull these are local coordinates
	add_child(target_fx)
	
	# REMI: change values to make it more dynamic
	main_tween = create_tween()
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	# REMI: MODIFIED THE FOLLOWING
	main_tween.tween_callback(_end_phase_1_attack)

func _end_phase_1_attack():
	$AttackP1/TextureButtonAttackP1.hide()
	$AttackP1/TextureButtonAttackP1.scale = ATTACK_SCALE
	character.hit(DAMAGE_PER_ATTACK_P1)
	_phase_1()

#
#func _play_waiting_animation():
#	state = "waiting"
#	$Body/Sprite2DNormal.show()
#	$Body/Sprite2DAttacking.hide()
#	for loop_index in range(IDLE_LOOP_NUMBER):
#		main_tween = create_tween()
#		for hand in hands:
#			# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
#			var random_vector : Vector2 = Vector2(1.0, 0.0).rotated(randf_range(-PI, PI)) * sqrt(randf_range(0.0, 1.0)) * HAND_MOVE_RADIUS
#			var target_position : Vector2 = hands_state[hand]["initial_position"] + random_vector
#			main_tween.parallel().tween_property(hand, "position", target_position, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
#		await main_tween.finished
#	_play_attacking_animation.call_deferred()
#
#func _play_attacking_animation():
#	state = "attacking"
#	$Body/Sprite2DNormal.hide()
#	$Body/Sprite2DAttacking.show()
#	# shuffle randomly the list of hands
#	var copy_of_hands : Array[Node] = hands.duplicate()
#	copy_of_hands.shuffle()
#	# close all rands
#	for hand in copy_of_hands:
#		_attempt_to_close_hand(hand)
#	# attack with hands
#	for hand in copy_of_hands:
#		main_tween = create_tween()
#		main_tween.tween_property(hand, "scale", Vector2(0.8, 0.8), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
#		main_tween.tween_callback(_attempt_to_attack.bind(hand))
#		main_tween.tween_property(hand, "scale", Vector2(2.0, 2.0), 1.0 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
#		main_tween.tween_callback(_attempt_damaging_character.bind(hand))
#		main_tween.tween_property(hand, "scale", Vector2(1.0, 1.0), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
#		main_tween.tween_callback(_attempt_to_close_hand.bind(hand))
#		await main_tween.finished
#	# close all rands
#	for hand in copy_of_hands:
#		_attempt_to_open_hand(hand)
#	# change state
#	_play_waiting_animation.call_deferred()
#
#func _attempt_to_open_hand(hand : Node2D):
#	if not hands_state[hand]["state"] == "open":
#		hands_state[hand]["state"] = "open"
#		hand.get_node("TextureButtonOpen").show()
#		hand.get_node("TextureButtonClosed").hide()
#		hand.get_node("TextureButtonAttacking").hide()
#
#func _attempt_to_close_hand(hand : Node2D):
#	if not hands_state[hand]["state"] == "close":
#		hands_state[hand]["state"] = "closed"
#		hand.get_node("TextureButtonOpen").hide()
#		hand.get_node("TextureButtonClosed").show()
#		hand.get_node("TextureButtonAttacking").hide()
#
#func _attempt_to_attack(hand : Node2D):
#	if not hands_state[hand]["state"] == "attack":
#		hands_state[hand]["state"] = "attacking"
#		hand.get_node("TextureButtonOpen").hide()
#		hand.get_node("TextureButtonClosed").hide()
#		hand.get_node("TextureButtonAttacking").show()
#
#func _attempt_damaging_character(hand : Node2D):
#	if hands_state[hand]["state"] == "attacking":
#		character.hit(HAND_DAMAGE_PER_ATTACK)
#
#func _hand_open_pressed(hand : Node2D):
#	_hit(character.damage_per_attack)
#
#func _hit(damage_points : float):
#	life_points -= damage_points
#	_attempt_to_play_hit_animation()
#	# TODO: DEATH ANIMATION
#	if life_points <= 0.0:
#		_attempt_to_play_death_animation()
#
#var hit_tween : Tween
#
#func _attempt_to_play_hit_animation():
#	if not hit_tween or not hit_tween.is_running():
#		hit_tween = create_tween()
#		hit_tween.tween_property($Body, "modulate", Color(1.0, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
#		hit_tween.tween_property($Body, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)
#
#func _attempt_to_play_death_animation():
#	if state != "dying":
#		state = "dying"
#		if main_tween:
#			main_tween.kill()
#		main_tween = create_tween()
#		main_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
#		await main_tween.finished
#		just_died.emit()
#
#func _hand_closed_pressed(hand : Node2D):
#	pass # TODO: MAYBE DO SOMETHING HERE
#
#func _hand_attacking_pressed(hand : Node2D):
#	# TODO: ANIMATION
#	_attempt_to_close_hand(hand)

func _body_attacks(damage : float):
	life_points -= damage
	_set_hp_bar(max(life_points,0))
	if life_points <= 0.0:
		_death_animation()
#	elif life_points <= 20 && state == "phase_1":
#		_transition_to_phase_2()
		
func _transition_to_phase_2():
	state = "transitioning_phase_2"
	for body in bodies:
		body.hide()
	$AttackP1/Sprite2DAttacked.show()
		
func _block_attack():
	$Body/Sprite2DAtttackingP1.hide()
	$AttackP1/TextureButtonAttackP1.hide()
	$AttackP1/TextureButtonAttackP1.scale = ATTACK_SCALE
	main_tween.kill()
	$AttackP1/Sprite2DAttackedP1.show()
	
	var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
	blocked_fx.TARGET_SCALE = Vector2.ONE
	blocked_fx.position = $AttackP1.position # carefull these are local coordinates
	add_child(blocked_fx)
	
	main_tween = create_tween()
	main_tween.tween_property($AttackP1/Sprite2DAttackedP1, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_callback($AttackP1/Sprite2DAttackedP1.hide)
	main_tween.tween_callback(_end_animation)
	
	_phase_1()
		
func _end_animation():
	$AttackP1/Sprite2DAttackedP1.modulate.a = 1.0
	
func _death_animation():
	main_tween.kill()
	for body in bodies:
		body.hide()
		
	just_died.emit()
	
# REMI: HP BAR

var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
#	print(life_points)
	pass
