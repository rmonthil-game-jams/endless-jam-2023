extends "res://modules/nathan/sliminou_gang/sliminou_gang.gd"

signal just_died_individual


# MOB SUB PARAMETERS
## HANDS
var HAND_MOVE_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var HAND_MOVE_RADIUS : float = 100.0
## IDLE
const IDLE_LOOP_NUMBER : int = 3
var DUPLICATE_LOOP_NUMBER : int = 2 #round(8.0 - DIFFICULTY) #NUMBER OF IDLE PHASES
var DANCE_MOVE_DURATION : float = 2.0 / (1.0 + log(1.0 + DIFFICULTY/4)) # INVERSE OF MOVEMENT SPEED
var DANCE_MOVE_RADIUS : float = 100.0
## JUMPING
var JUMP_DURATION : float = 3.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var JUMP_HEIGHT : float = min(1000.0, 300.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY)))
## ATTACKING
var SPEACH_ATTACK_DURATION_FACTOR : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF ATTACK SPEED
var SPEACH_DAMAGE_PER_ATTACK : float = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
## TODO: NUMBER OF HANDS DEPENDANT OF DIFFICULTY ?

# MOB STATE
var life_points : float = 5.0
enum STATE {loading_attack, attacking, canceled, idle, loading_jump, jumping, doubling}
var state : STATE # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var tween : Tween = null
var hands : Array[Node] = []
var hands_state : Dictionary = {}
var character : Node = null
var duplicate_countdown : int = DUPLICATE_LOOP_NUMBER


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
		
		
		hand.get_node("TextureButtonOpened").pressed.connect(_hand_open_pressed.bind(hand))
		hand.get_node("TextureButtonClosed").pressed.connect(_hand_closed_pressed.bind(hand))
	character = get_tree().get_nodes_in_group("character").front()
	# avoid using await in the _ready function
	
	$Speach/Mouth/TextureButton.pressed.connect(_mouth_attacking_pressed.bind($Speach/Mouth))
	
	print("fini")
	_clean_attack.call_deferred($Speach/SpeachBubble)
	
func _play_dedoubling():
	var new_sliminou : Node2D = load("res://modules/nathan/sliminou_gang/sliminou.tscn").instantiate()
	
	new_sliminou.position = Vector2(0.0, 400.0)
	
	get_parent().add_child(new_sliminou)
#	kiss_tween.tween_callback(new_kiss.queue_free)
	_play_waiting_animation(1,false)


	
func _play_waiting_animation(loop_num : int, next_is_jump : bool):
	state = STATE.idle
	duplicate_countdown -= 1 
	
	tween = create_tween()
	for loop_index in range(loop_num):
		# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
		var random_vector : Vector2 = Vector2(1.0, 0.0) * (randf_range(-1.0, 1.0)) * DANCE_MOVE_RADIUS
		var target_position : Vector2 = random_vector
		tween.tween_property($Body, "position", target_position, DANCE_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "position", Vector2(0.0, 0.0), DANCE_MOVE_DURATION/1.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	if duplicate_countdown <= 0 :
		duplicate_countdown = DUPLICATE_LOOP_NUMBER
		_play_dedoubling()
	elif next_is_jump :
		_play_jump_animation.call_deferred()
	else :
		_play_attacking_animation.call_deferred()
	

func _play_attacking_animation():
	
	#Preping the speach
	$Speach/SpeachBubble/SpeachText.text=get_parent()._get_a_speach()
	
	#animation
	
	tween = create_tween()
	
	tween.tween_callback(_attempt_to_attack.bind($Speach/SpeachBubble))
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(1.0, 1.0), 0.250 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Speach/SpeachBubble/SpeachText,"visible_ratio",1,1.500 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(0.25, 0.25), 0.125 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_callback(_attacking.bind($Speach))
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(2.0, 2.0), 0.5 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(_attempt_damaging_character.bind())
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(0.0, 0.0), 0.125 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_clean_attack.bind($Speach/SpeachBubble))

func _play_jump_animation():
	state = STATE.loading_jump
	
	var bouncing_value : float = 0.5
	var offset_value : float = (1- bouncing_value) * $Body/Sprite2DNormal.texture.get_height()
	print(offset_value)
	tween = create_tween()
	tween.tween_property($Body, "position", Vector2(0.0,offset_value), JUMP_DURATION/3).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Body, "scale", Vector2(1.0, bouncing_value), JUMP_DURATION/3).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($Body, "position", Vector2(0.0, -JUMP_HEIGHT), JUMP_DURATION).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Body, "scale", Vector2(1.0,1.0), JUMP_DURATION/3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "position", Vector2(0.0,0.0), JUMP_DURATION).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	_play_waiting_animation.call_deferred(IDLE_LOOP_NUMBER, false)

func _clean_attack(bubble : Node2D):
	bubble.get_node("SpeachText").visible_ratio = 0.0
	bubble.get_node("SpeachButton").hide()
	bubble.rotation = 0.0
	_play_waiting_animation.call_deferred(IDLE_LOOP_NUMBER, true)

func _attempt_to_attack(speach : Node2D):
	state = STATE.loading_attack
	speach.get_node("SpeachButton").show()

func _attacking(speach : Node2D):
	if not state == STATE.canceled :
		state = STATE.attacking

func _attempt_damaging_character():
	if state == STATE.attacking : 
		character.hit(SPEACH_DAMAGE_PER_ATTACK)

func _attempt_to_cancel(speach : Node2D):
	if state == STATE.loading_attack : 
		
		
		state = STATE.canceled
		
		tween.kill()
		
		tween = create_tween()
	
		tween.tween_property($Speach/SpeachBubble, "rotation", 2*randf_range(-PI/8, PI/8), 0.250 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_interval(0.125*SPEACH_ATTACK_DURATION_FACTOR)
		tween.tween_property($Speach/SpeachBubble, "scale", Vector2(0.25, 0.25), 0.125 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(_clean_attack.bind($Speach/SpeachBubble))

func _mouth_attacking_pressed(mouth : Node2D):
	# TODO: ANIMATION
	_attempt_to_cancel(mouth.get_parent())	

func _hit(damage_points : float):
	life_points -= damage_points
	# TODO: DEATH ANIMATION
	if life_points <= 0.0:
		just_died_individual.emit()



func _hand_closed_pressed(hand : Node2D):
	pass # TODO: MAYBE DO SOMETHING HERE

func _attempt_to_open_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "close":
		hands_state[hand]["state"] = "closed"
		hand.get_node("TextureButtonOpen").show()
		hand.get_node("TextureButtonClosed").hide()
		hand.get_node("TextureButtonAttacking").hide()

func _attempt_to_close_hand(hand : Node2D):
	if not hands_state[hand]["state"] == "open":
		hands_state[hand]["state"] = "open"
		hand.get_node("TextureButtonOpen").hide()
		hand.get_node("TextureButtonClosed").show()
		hand.get_node("TextureButtonAttacking").hide()

func _hand_open_pressed(hand : Node2D):
	_hit(character.damage_per_attack)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass