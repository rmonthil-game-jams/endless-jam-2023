extends Node2D # REMI: REMOVED STRANGE INHERITANC, MAYBE WE CAN DISCUSS ABOUT IT

signal just_died_individual
signal just_spawned

#CONST
const STANDARD_PLAYER_DAMAGE : float = 2.1

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty # REMI: _set_difficulty

# MOB SUB PARAMETERS
## DUPLICATE
var DUPLICATE_LOOP_NUMBER : int
const SCREEN_WIDTH : float = 1000.0
const DUPLICATE_DISTANCE_X = 400.0
const DUPLICATE_DISTANCE_Y = 100.0
const DISTANCE_SIZE_RATIO : float = 1e-3
## IDLE
const IDLE_LOOP_NUMBER : int = 1
var DANCE_MOVE_DURATION : float
const DANCE_MOVE_RADIUS : float = 400.0

## JUMPING
var JUMP_DURATION : float
var FALL_DURATION : float
var JUMP_HEIGHT : float
## ATTACKING
var SPEACH_ATTACK_DURATION_FACTOR : float
var SPEACH_DAMAGE_PER_ATTACK : float
var LIFE : float
## TODO: NUMBER OF HANDS DEPENDANT OF DIFFICULTY ?

# REMI: _set_difficulty
func _set_difficulty(value : float):
	DIFFICULTY = value
	
	DUPLICATE_LOOP_NUMBER = max(round(8.0 - DIFFICULTY/2.0),2.0) #NUMBER OF IDLE PHASES BEFORE DUPLICATION
	#ATTENTION : DUPLICATE_LOOP_NUMBER / 2 > LIFE / STANDARD_PLAYER_DAMAGE  (sinon pas le temps de tuer avant la duplication)
	
	
	DANCE_MOVE_DURATION = 1.0 / (1.0 + log(1.0 + DIFFICULTY/4.0)) #THE SMALLER, THE QUICKER THE IDLE PHASE : MOB LOOKS ANGRIER AND ATTACK/VULNERABILITY PHASE COMES MORE OFTEN
	JUMP_DURATION = 2.0 / (1.0 + log(1.0 + DIFFICULTY)) #THE SMALLER THE QUICKER IT GETS AND THE HARDER IT GETS (VULNERABILITY PHASE)
	FALL_DURATION = 2.0*JUMP_DURATION/3.0
	JUMP_HEIGHT = 400.0 #min(1500.0, 500.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY))) #THE HIGHER THE EASIER (VULNERABILITY PHASE)
	SPEACH_ATTACK_DURATION_FACTOR = 2.0 / (1.0 + log(1.0 + DIFFICULTY)) #THE SHORTER, THE HARDER TO COUNTER THE ATTACK
	SPEACH_DAMAGE_PER_ATTACK = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	LIFE = 4.0 + log(0.5 + DIFFICULTY)


	

# MOB STATE
var life_points : float = 5.0
enum STATE {loading_attack, attacking, canceled, idle, loading_jump, jumping, doubling}
var state : STATE # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var tween : Tween = null
var tween_bis : Tween = null
var hands : Array[Node] = []
# var hands_state : Dictionary = {}
var character : Node = null
var duplicate_countdown : int 

## called when the node enters the scene tree for the first time.
func _ready():
	# set difficulty
	_set_difficulty(DIFFICULTY)
	duplicate_countdown = DUPLICATE_LOOP_NUMBER
	life_points = LIFE

	$Body/WeakSpot/AnimationPlayer.play("HeartBeat")
	
#	# other
	character = get_tree().get_nodes_in_group("character").front()
	# avoid using await in the _ready function
	$Body/Mouth/MouthButton.pressed.connect(_mouth_attacking_pressed.bind($Body/Mouth))
	$Body/WeakSpot/WeakSpotButton.pressed.connect(_hit.bind(STANDARD_PLAYER_DAMAGE))
	$Speach/SpeachBubble.get_node("SpeachText").visible_ratio = 0.0
	_play_waiting_animation.call_deferred(0,false)

# REMI: QUITE A FEW TWEAKS
func _play_dedoubling():
	var new_sliminou_holder : Node2D = load("res://modules/nathan/sliminou_gang/sliminou_holder.tscn").instantiate()
	new_sliminou_holder.get_node("Sliminou").DIFFICULTY = DIFFICULTY
	
	var position_target : Vector2
	if get_parent().position.x > 2.0 * DUPLICATE_DISTANCE_X:
		position_target.x = -DUPLICATE_DISTANCE_X
	elif get_parent().position.x < 2.0 * DUPLICATE_DISTANCE_X:
		position_target.x = DUPLICATE_DISTANCE_X
	elif (randf_range(0.0, 1.0) <= 0.5):
		position_target.x = DUPLICATE_DISTANCE_X
	else:
		position_target.x = -DUPLICATE_DISTANCE_X
	if get_parent().position.y > 2.0 * DUPLICATE_DISTANCE_Y:
		position_target.y = -DUPLICATE_DISTANCE_Y
	elif get_parent().position.y < 2.0 * DUPLICATE_DISTANCE_Y:
		position_target.y = DUPLICATE_DISTANCE_Y
	elif (randf_range(0.0, 1.0) <= 0.5):
		position_target.y = DUPLICATE_DISTANCE_Y
	else:
		position_target.y = -DUPLICATE_DISTANCE_Y
	
	position_target += Vector2(randf_range(-20.0, -20.0), randf_range(-10.0, -10.0))
	
	new_sliminou_holder.position = get_parent().transform.basis_xform_inv(position_target) + get_parent().position
	var new_size_ratio = 1.0 + DISTANCE_SIZE_RATIO * new_sliminou_holder.position.y
	new_sliminou_holder.scale = Vector2(new_size_ratio, new_size_ratio)
	
	get_parent().get_parent()._register_spawning(1)

	$Duplicate.scale = Vector2(0.5,0.2)
	
	tween = create_tween()
	tween.tween_callback($Body/Sprite2DDuplication.show)
	tween.tween_callback($Body/Sprite2DNormal.hide)
	tween.tween_property($Body, "rotation", -PI/8, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "rotation", PI/6, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "rotation", -PI/5, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback($Duplicate.show)
	tween.tween_property($Body, "scale", Vector2(1.1,1.1), 0.125).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property($Body, "rotation", 0, 0.25).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($Duplicate, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "scale", Vector2(1,1), 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback($Body/Sprite2DDuplication.hide)
	tween.tween_callback($Body/Sprite2DNormal.show)
	tween.tween_property($Duplicate, "position", position_target, 0.25).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Duplicate, "scale", Vector2(new_size_ratio/get_parent().scale.x, new_size_ratio/get_parent().scale.y),0.25).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback($Duplicate.hide)
	tween.tween_callback(get_parent().get_parent().add_child.bind(new_sliminou_holder))
	
	await tween.finished
	
	$Duplicate.position = Vector2(0.0,0.0)
	_play_waiting_animation.call_deferred(1,false)
	
func _play_waiting_animation(loop_num : int, next_is_jump : bool):
	state = STATE.idle
	duplicate_countdown -= 1 
	var random_vector : Vector2
	var target_position : Vector2
	var random_time_variation : float 
	
	tween = create_tween()
	for loop_index in range(loop_num):
		random_vector = Vector2(1.0, 0.0) * (randf_range(-1.0, 1.0)) * DANCE_MOVE_RADIUS
		target_position = random_vector
		random_time_variation = randf_range(-DANCE_MOVE_DURATION/4.0, DANCE_MOVE_DURATION/4.0)
		tween.tween_property($Body, "position", target_position, DANCE_MOVE_DURATION + random_time_variation).set_trans(Tween.TRANS_CUBIC)
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
	$Speach/SpeachBubble/SpeachText.text=get_parent().get_parent()._get_a_speach()
	
	#animation
	
	tween = create_tween()
	
	tween.tween_callback(_attempt_to_attack.bind($Speach/SpeachBubble))
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(1.0, 1.0), 0.250 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Speach/SpeachBubble/SpeachText,"visible_ratio",1,1.500 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(0.25, 0.25), 0.125 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_callback(_attacking.bind($Speach))

	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(2.5, 2.5), 0.5 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(_attempt_damaging_character.bind())
	tween.tween_property($Speach/SpeachBubble, "scale", Vector2(0.0, 0.0), 0.125 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_clean_attack.bind($Speach/SpeachBubble))

func _play_jump_animation():
	state = STATE.loading_jump
	
	var bouncing_value : float = 0.5
	var offset_value : float = (1- bouncing_value) * $Body/Sprite2DNormal.texture.get_height()

	tween = create_tween()
	
	#LOADING
	tween.tween_property($Body, "position", Vector2(0.0,0.0), JUMP_DURATION/3).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Body, "scale", Vector2(1.0, bouncing_value), JUMP_DURATION/3).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_callback($Body/Hands._on_jump_loading)
	
	#JUMPING
	tween.tween_callback($Body/WeakSpot.show)
	tween.tween_property($Body, "position", Vector2(0.0, -JUMP_HEIGHT), JUMP_DURATION).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Body, "scale", Vector2(1.0,1.0), JUMP_DURATION/2.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "position", Vector2(0.0,0.0), FALL_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback($Body/WeakSpot.hide)
	tween.parallel().tween_callback($Body/Hands._restart_hand_loop)
	await tween.finished
	_play_waiting_animation.call_deferred(IDLE_LOOP_NUMBER, false)

func _clean_attack(bubble : Node2D):
	bubble.get_node("SpeachText").visible_ratio = 0.0
	bubble.hide()
	$Body/Mouth/MouthButton.disabled = true
	$Body/Mouth/AnimationPlayer.stop()
	bubble.rotation = 0.0


	_play_waiting_animation.call_deferred(IDLE_LOOP_NUMBER + round((get_parent().get_parent().gang_size-0.5)/2.0), true)

func _attempt_to_attack(speach : Node2D):
	state = STATE.loading_attack
	$Body/Mouth/AnimationPlayer.play("MouthBabbling")
	$Body/Mouth/MouthButton.disabled = false
	speach.show()

func _attacking(speach : Node2D):
	if not state == STATE.canceled :
		state = STATE.attacking

func _attempt_damaging_character():
	if state == STATE.attacking : 
		character.hit(SPEACH_DAMAGE_PER_ATTACK)

func _attempt_to_cancel(speach : Node2D):
	if state == STATE.loading_attack : 
				
		state = STATE.canceled
		
		var angle : float = 0.0
		while abs(angle) < PI/10 :
			angle = randf_range(-PI/4, PI/4)
		
		tween.kill()
		
		tween = create_tween()
	
		tween.tween_callback($Body/Mouth/AnimationPlayer.stop)
		tween.parallel().tween_callback($Body/Hurt_Sprite.show)
		tween.parallel().tween_callback($Body/Sprite2DNormal.hide)
		tween.tween_property($Speach/SpeachBubble, "rotation", angle, 0.250 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_interval(0.125*SPEACH_ATTACK_DURATION_FACTOR)
		tween.tween_property($Speach/SpeachBubble, "scale", Vector2(0.25, 0.25), 0.125 * SPEACH_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback($Body/Hurt_Sprite.hide)
		tween.parallel().tween_callback($Body/Sprite2DNormal.show)
		tween.tween_callback(_clean_attack.bind($Speach/SpeachBubble))


func _mouth_attacking_pressed(mouth : Node2D):
	# TODO: ANIMATION
	_attempt_to_cancel(mouth.get_parent())	

func _hit(damage_points : float):
	
	var refall_duration : float = (-$Body.position.y/JUMP_HEIGHT)* JUMP_DURATION
	var shaken_angle : float = 0.0
	while abs(shaken_angle) < PI/8 :
		shaken_angle = randf_range(-PI/3, PI/3)
	
	life_points -= damage_points
	
	tween.kill()
	tween = create_tween()
	
	if life_points <= 0.0 :
		tween.parallel().tween_callback($Body/WeakSpot/WeakSpotButton.set_disabled.bind(true))
		$Body/WeakSpot/AnimationPlayer.stop()
		tween.parallel().tween_callback($Body/Hands._on_death.bind(refall_duration))
	
	tween.tween_callback($Body/Sprite2DNormal.hide)
	tween.parallel().tween_callback($Body/Hurt_FullSprite.show)
	tween.tween_property($Body, "scale", Vector2(0.7,0.7),0.125).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($Body, "scale", Vector2(1.0,1.0),0.25).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property($Body, "position", Vector2(0.0,0.0),refall_duration).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property($Body, "position", Vector2(0.0,0.0),refall_duration).set_trans(Tween.TRANS_ELASTIC)
	
	if life_points <= 0.0:
		tween.parallel().tween_property($Body, "rotation", shaken_angle*2,refall_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.5)
		await tween.finished
		get_parent().get_parent()._register_spawning(-1)
		queue_free()
	else :
		tween.parallel().tween_property($Body, "rotation", shaken_angle,refall_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(JUMP_DURATION/2.0)
		tween.parallel().tween_callback($Body/Hands._restart_hand_loop)
		tween.tween_callback($Body/WeakSpot.hide)
		tween.tween_property($Body, "rotation", 0.0,FALL_DURATION).set_trans(Tween.TRANS_QUAD)
		
		tween.tween_callback($Body/Sprite2DNormal.show)
		tween.parallel().tween_callback($Body/Hurt_FullSprite.hide)
		tween.tween_callback(_play_waiting_animation.bind(IDLE_LOOP_NUMBER, false))
