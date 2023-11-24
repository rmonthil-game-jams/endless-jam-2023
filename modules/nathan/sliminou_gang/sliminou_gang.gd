extends Node2D

signal just_died

# MOB PARAMETERS
var DIFFICULTY : float = 0.0

# MOB SUB PARAMETERS
## HANDS
var HAND_MOVE_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var HAND_MOVE_RADIUS : float = 100.0
## IDLE
const IDLE_LOOP_NUMBER : int = 3
var DUPLICATE_LOOP_NUMBER : int = round(6.0 - DIFFICULTY)
var DANCE_MOVE_DURATION : float = 2.0 / (1.0 + log(1.0 + DIFFICULTY/4)) # INVERSE OF MOVEMENT SPEED
var DANCE_MOVE_RADIUS : float = 100.0
## JUMPING
var JUMP_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
var JUMP_HEIGHT : float = min(800.0, 100.0 * (1.0 + 0.1 * log(1.0 + DIFFICULTY)))
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

var speaches : Array[String]

const speaches_template : Array[String] = [
		"Tu es unique et exceptionnel",
		"Ton sourire illumine chaque jour",
		"Ta gentillesse est inoubliable",
		"Ton intelligence est inspirante",
		"Chaque jour, tu grandis en sagesse",
		"Tes rêves sont aussi vastes que l'univers",
		"Ta créativité est une source d'admiration",
		"Tu as un charme irrésistible",
		"Ton optimisme est contagieux",
		"Tu es un rayon de soleil dans ma vie",
		"Ta détermination est impressionnante",
		"Ton courage est une force inébranlable",
		"La beauté de ton esprit est captivante",
		"Ta bienveillance réchauffe les cœurs",
		"Tu es une source infinie d'inspiration",
		"Ton humilité te rend encore plus grand",
		"Chacune de tes actions compte",
		"Tu es un joyau rare et précieux",
		"Ton énergie est revitalisante",
		"Tu fais briller les étoiles avec ta présence",
		"Tes accomplissements sont extraordinaires",
		"La façon dont tu traites les autres est admirable",
		"Ton style est toujours élégant",
		"Tu es une étoile qui brille dans l\'obscurité",
		"Ton charisme est magnétique",
		"Ta bonté fait du bien au monde",
		"Ton esprit est une fontaine de sagesse",
		"Tu es un artiste de la vie",
		"Tes idées sont brillantes et novatrices",
		"Ton humour éclaire les journées",
		"Ta passion est une flamme inextinguible",
		"Ton empathie touche profondément",
		"Ton amour-propre est mérité",
		"Tu es la définition du succès",
		"Ton amour pour la vie est contagieux",
		"Ton authenticité est rafraîchissante",
		"Tes qualités sont infinies",
		"Ton esprit libre est inspirant",
		"Tu es une étoile montante",
		"Ta persévérance est exemplaire",
		"Ta présence est un cadeau",
		"Ton optimisme est une bouffée d\'air frais",
		"Tes idées sont une source d\'émerveillement",
		"Ta force intérieure est impressionnante",
		"Tes choix révèlent ta sagesse",
		"Ton charme est inoubliable",
		"Ta gentillesse fait du bien au cœur",
		"Tu es un phare dans la tempête",
		"Ton potentiel est illimité",
		"Tu as une imagination digne de Rémi"
	]

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
	
	speaches = speaches_template.duplicate()
	speaches.shuffle()
	print("fini")
	_clean_attack.call_deferred($Speach/SpeachBubble)
	

	
func _play_waiting_animation(loop_num : int):
	state = STATE.idle
	print("idling")
	tween = create_tween()
	for loop_index in range(loop_num):
		# generation of random vector whithin a disk of radius HAND_MOVE_RADIUS, the "sqrt" ensures uniform distribution.
		var random_vector : Vector2 = Vector2(1.0, 0.0) * (randf_range(-1.0, 1.0)) * DANCE_MOVE_RADIUS
		var target_position : Vector2 = random_vector
		tween.tween_property($Body, "position", target_position, DANCE_MOVE_DURATION).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Body, "position", Vector2(0.0, 0.0), DANCE_MOVE_DURATION/1.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	_play_attacking_animation.call_deferred()

func _play_attacking_animation():
	
	#Preping the speach
	$Speach/SpeachBubble/SpeachText.text=speaches.pop_back()
	if speaches.size()== 0 :
		speaches = speaches_template.duplicate()
		speaches.shuffle()
	
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

func _clean_attack(bubble : Node2D):
	bubble.get_node("SpeachText").visible_ratio = 0.0
	bubble.get_node("SpeachButton").hide()
	bubble.rotation = 0.0
	_play_waiting_animation.call_deferred(IDLE_LOOP_NUMBER)

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
		just_died.emit()



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
