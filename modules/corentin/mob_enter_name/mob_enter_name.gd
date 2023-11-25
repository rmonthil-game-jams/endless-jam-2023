extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 1

# MOB SUB PARAMETERS
## WAITING
var HAND_MOVE_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var HAND_MOVE_RADIUS : float = min(400.0, 50.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY)))
const IDLE_LOOP_NUMBER : int = 4
## ATTACKING
var HAND_ATTACK_DURATION_FACTOR : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF ATTACK SPEED
var HAND_DAMAGE_PER_ATTACK : float = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
## TODO: NUMBER OF HANDS DEPENDANT OF DIFFICULTY ?

# MOB STATE
var max_life_points : float = 10.0 + 5*DIFFICULTY
var life_points : float = 10.0 + 5*DIFFICULTY
var state : String # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var hands : Array[Node] = []
var hands_state : Dictionary = {}
var character : Node = null

## called when the node enters the scene tree for the first time.
func _ready():
	hands = $Hands.get_children()
	for hand in hands:
		# setup state
		hands_state[hand] = {
			"initial_position":hand.position,
			"state":"open",
		} # careful here, position is in local coordinate use global_position for global coordinates
		# setup signals
		hand.get_node("TextureButtonOpen").pressed.connect(_hand_open_pressed.bind(hand))
		hand.get_node("TextureButtonClosed").pressed.connect(_hand_closed_pressed.bind(hand))
		hand.get_node("TextureButtonAttacking").pressed.connect(_hand_attacking_pressed.bind(hand))
	character = get_tree().get_nodes_in_group("character").front()
	$MobHPBar.max_value = max_life_points
	# avoid using await in the _ready function
	_play_appearing_animation.call_deferred()
	
func _play_appearing_animation():
	# init
	state = "appearing"
	modulate.a = 0.0
	# animation
	main_tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	_play_waiting_animation.call_deferred()

func _play_waiting_animation():
	state = "waiting"
	$Body/Sprite2DNormal.show()
	$Body/Sprite2DAttacking.hide()
	for loop_index in range(IDLE_LOOP_NUMBER):
		main_tween = create_tween()
		for hand in hands:
			# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
			var random_vector : Vector2 = Vector2(1.0, 0.0).rotated(randf_range(-PI, PI)) * sqrt(randf_range(0.0, 1.0)) * HAND_MOVE_RADIUS
			var target_position : Vector2 = hands_state[hand]["initial_position"] + random_vector
			main_tween.parallel().tween_property(hand, "position", target_position, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
	_play_attacking_animation.call_deferred()

func _play_attacking_animation():
	state = "attacking"
	$Body/Sprite2DNormal.hide()
	$Body/Sprite2DAttacking.show()
	# shuffle randomly the list of hands
	var copy_of_hands : Array[Node] = hands.duplicate()
	copy_of_hands.shuffle()
	# close all rands
	for hand in copy_of_hands:
		_attempt_to_close_hand(hand)
	# attack with hands
	for hand in copy_of_hands:
		main_tween = create_tween()
		main_tween.tween_property(hand, "scale", Vector2(0.8, 0.8), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.tween_callback(_attempt_to_attack.bind(hand))
		main_tween.tween_property(hand, "scale", Vector2(2.0, 2.0), 1.0 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
		main_tween.tween_callback(_attempt_damaging_character.bind(hand))
		main_tween.tween_property(hand, "scale", Vector2(1.0, 1.0), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.tween_callback(_attempt_to_close_hand.bind(hand))
		await main_tween.finished
	# close all rands
	for hand in copy_of_hands:
		_attempt_to_open_hand(hand)
	# change state
	_play_waiting_animation.call_deferred()

func _attempt_to_open_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "open":
		hands_state[hand]["state"] = "open"
		hand.get_node("TextureButtonOpen").show()
		hand.get_node("TextureButtonClosed").hide()
		hand.get_node("TextureButtonAttacking").hide()

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

func _hand_open_pressed(hand : Node2D):
	_hit(character.damage_per_attack)

func _hit(damage_points : float):
	life_points -= damage_points
	_set_hp_bar(max(life_points,0))
	_attempt_to_play_hit_animation()
	# TODO: DEATH ANIMATION
	if life_points <= 0.0:
		_attempt_to_play_death_animation()


var hit_tween : Tween

func _attempt_to_play_hit_animation():
	if not hit_tween or not hit_tween.is_running():
		hit_tween = create_tween()
		hit_tween.tween_property($Body, "modulate", Color(1.0, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_property($Body, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)


const HEALTH_TRANS_TIME : float = 0.25
var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property($MobHPBar, "value", life_points, HEALTH_TRANS_TIME)

func _attempt_to_play_death_animation():
	if state != "dying":
		state = "dying"
		if main_tween:
			main_tween.kill()
		main_tween = create_tween()
		main_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
		just_died.emit()

func _hand_closed_pressed(hand : Node2D):
	pass # TODO: MAYBE DO SOMETHING HERE

func _hand_attacking_pressed(hand : Node2D):
	# TODO: ANIMATION
	_attempt_to_close_hand(hand)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
