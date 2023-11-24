extends Node2D

# MOB PARAMETERS
var DIFFICULTY : float = 0.0

# MOB SUB PARAMETERS
## IDLE
var HAND_MOVE_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var HAND_MOVE_RADIUS : float = min(400.0, 50.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY)))
const IDLE_LOOP_NUMBER : int = 4
## ATTACK
var HAND_ATTACK_DURATION_FACTOR : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF ATTACK SPEED
var HAND_DAMAGE_PER_ATTACK : float = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
## TODO: NUMBER OF HANDS DEPENDANT OF DIFFICULTY ?

# MOB STATE
var life_points : float = 5.0
var state : String # useles at the moment but who knows in the future ?

# private

## initialization is unecessary because they are already initialized to these values
var tween : Tween = null
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
	character = get_tree().get_nodes_in_group("character").front()
	# avoid using await in the _ready function
	_play_idle_animation.call_deferred()

func _play_idle_animation():
	state = "idle"
	for loop_index in range(IDLE_LOOP_NUMBER):
		tween = get_tree().create_tween()
		for hand in hands:
			# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
			var random_vector : Vector2 = Vector2(1.0, 0.0).rotated(randf_range(-PI, PI)) * sqrt(randf_range(0.0, 1.0)) * HAND_MOVE_RADIUS
			var target_position : Vector2 = hands_state[hand]["initial_position"] + random_vector
			tween.parallel().tween_property(hand, "position", target_position, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
	_play_attack_animation.call_deferred()

func _play_attack_animation():
	state = "attack"
	var copy_of_hands : Array[Node] = hands.duplicate()
	copy_of_hands.shuffle()
	for hand in copy_of_hands:
		tween = get_tree().create_tween()
		tween.tween_callback(_attempt_to_close_hand.bind(hand))
		tween.tween_property(hand, "scale", Vector2(0.25, 0.25), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(_attempt_to_close_hand.bind(hand))
		tween.tween_property(hand, "scale", Vector2(2.0, 2.0), 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_callback(_attempt_damaging_character.bind(hand))
		tween.tween_property(hand, "scale", Vector2(1.0, 1.0), 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(_attempt_to_open_hand.bind(hand))
		await tween.finished
	_play_idle_animation.call_deferred()

func _attempt_to_close_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "close":
		hands_state[hand]["state"] = "closed"

func _attempt_to_open_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "open":
		hands_state[hand]["state"] = "open"

func _attempt_damaging_character(hand : Node2D):
	if hands_state[hand]["state"] == "closed":
		character.hit(HAND_DAMAGE_PER_ATTACK)

func _hand_open_pressed(hand : Node2D):
	pass
	# hit(character.damage_per_attack)

func _hand_closed_pressed(hand : Node2D):
	pass
	# hit(character.damage_per_attack)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
