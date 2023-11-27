extends Node2D

var tween : Tween = null
var hands : Array[Node] = []
var hands_state : Dictionary = {}
# Called when the node enters the scene tree for the first time.

var HAND_MOVE_DURATION : float = 1.0
var HAND_MOVE_RADIUS : float = 20.0

const HAND_POSITION : float = 75.0

var JUMP_DURATION : float 

func _ready():
	
	hands = self.get_children()
	
	var side_positivity : int = 0
	
	for hand in hands:
		# setup state
		
		if hand.name == "Right" : 
			hand.position = Vector2(-HAND_POSITION,-HAND_POSITION)
			side_positivity = -1
		elif hand.name == "Left":
			hand.position = Vector2(HAND_POSITION,-HAND_POSITION)
			side_positivity = 1
			
		hands_state[hand] = {
			"initial_position":hand.position,
			"side":hand.name,
			"positivity":side_positivity
		} # careful here, position is in local coordinate use global_position for global coordinates
		# setup signals
	
	JUMP_DURATION = get_parent().get_parent().JUMP_DURATION

	_main_loop()

func _main_loop():
	tween = create_tween()

	for hand in hands:
		# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
		var random_vector : Vector2 = Vector2(1.0, 0.0).rotated(randf_range(-PI, PI)) * sqrt(randf_range(0.0, 1.0)) * HAND_MOVE_RADIUS
		var target_position : Vector2 = hands_state[hand]["initial_position"] + random_vector
		tween.parallel().tween_property(hand, "position", target_position, HAND_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)

	tween.tween_callback(_restart_hand_loop)

func _restart_hand_loop():
	for hand in hands :
		hand.get_node("NormalHand").show()
		
		hand.get_node("OpenHand").hide()
		hand.get_node("GroundHand").hide()
		hand.get_node("FlyHand").hide()
	
	_main_loop()

func _on_jump_loading():
	tween.kill()
	tween = create_tween()
	var side_positivity : int = 1
	
	for hand in hands :
			
		hand.get_node("NormalHand").hide()
		hand.get_node("GroundHand").show()

		tween.parallel().tween_property(hand, "position", Vector2(hands_state[hand]["positivity"] * HAND_POSITION, 10.0), 2.0*JUMP_DURATION/3.0).set_trans(Tween.TRANS_CUBIC)

		

func _on_jumping():
	pass

func _on_death(timing : float):
	tween.kill()
	tween = create_tween()

	var position_variation : float
	
	for hand in hands :
		position_variation = randf_range(-HAND_POSITION/3, HAND_POSITION/3)
		tween.parallel().tween_property(hand, "position", Vector2(hands_state[hand]["positivity"] * HAND_POSITION + position_variation, 0.0), timing).set_trans(Tween.TRANS_CUBIC)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	pass
