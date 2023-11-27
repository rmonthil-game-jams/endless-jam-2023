extends Node2D

signal just_died

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty # REMI: _set_difficulty

# REMI: _set_difficulty
func _set_difficulty(value : float):
	DIFFICULTY = value
	$SliminouHolder/Sliminou.DIFFICULTY = DIFFICULTY

var gang_size : int
var duplication_number : int = 0

var speaches : Array[String]

# REMI: WE HAVE AN INTERNATIONAL PUBLIC, TODO: TRANSLATE EVERYTHING IN ENGLISH
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
	
const speaches_template_EN : Array[String] = [
		"You are unique and exceptional",
		"Your smile brightens every day",
		"Your kindness is unforgettable",
		"Your intelligence is inspiring",
		"Every day you grow in wisdom",
		"Your dreams are as wide as the universe",
		"Your creativity is a source of admiration",
		"You have an irresistible charm",
		"Your optimism is contagious",
		"You're a ray of sunshine in my life",
		"Your determination is impressive",
		"Your courage is an unshakeable strength",
		"The beauty of your mind is captivating",
		"Your kindness warms hearts",
		"You're an endless source of inspiration",
		"Your humility makes you even greater",
		"Every one of your actions counts",
		"You are a rare and precious jewel",
		"Your energy is revitalizing",
		"You make the stars shine with your presence",
		"Your achievements are extraordinary",
		"The way you treat others is admirable.",
		"Your style is always elegant",
		"You're a star shining in the darkness",
		"Your charisma is magnetic",
		"Your kindness does the world good",
		"Your spirit is a fountain of wisdom",
		"You are an artist of life",
		"Your ideas are brilliant and innovative",
		"Your humor brightens the day",
		"Your passion is an inextinguishable flame",
		"Your empathy is deeply touching",
		"Your self-esteem is deserved",
		"You are the definition of success",
		"Your love of life is contagious",
		"Your authenticity is refreshing",
		"Your qualities are infinite",
		"Your free spirit is inspiring",
		"You're a rising star",
		"Your perseverance is exemplary",
		"Your presence is a gift",
		"Your optimism is a breath of fresh air",
		"Your ideas are a source of wonder",
		"Your inner strength is impressive",
		"Your choices reveal your wisdom",
		"Your charm is unforgettable",
		"Your kindness is good for the heart",
		"You're a lighthouse in a storm",
		"Your potential is unlimited",
		"You have an imagination worthy of a Rémi"
	]
# MOB STATE
#var life_points : float = 5.0
#enum STATE {loading_attack, attacking, canceled, idle, loading_jump, jumping, doubling}
#var state : STATE # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
#var tween : Tween = null
#var hands : Array[Node] = []
#var hands_state : Dictionary = {}
#var character : Node = null

## called when the node enters the scene tree for the first time.
func _ready():
	_set_difficulty(DIFFICULTY) # REMI: _set_difficulty
	gang_size = 1
	speaches = speaches_template_EN.duplicate()
	speaches.shuffle()
	
	
func _get_a_speach():
	if speaches.size()== 0 :
		speaches = speaches_template_EN.duplicate()
		speaches.shuffle()
	return speaches.pop_back()

func _register_spawning(n : int):
	
	gang_size += n
	
	if n > 0 :
		duplication_number += n
	elif gang_size <= 0 :
			#print("DIED")
			just_died.emit()
	#print(gang_size)
	

#	var new_sliminou : Node2D = preload("res://modules/nathan/sliminou_gang/sliminou.tscn").instantiate()
#	new_kiss.transform = hand.transform
#	$.add_child(new_kiss)
#	# tween
#	var kiss_tween : Tween = create_tween()
#	kiss_tween.tween_property(new_kiss, "modulate:a", 0.0, KISS_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
#	kiss_tween.tween_callback(new_kiss.queue_free)
	
#	$Speach/Mouth/TextureButton.pressed.connect(_mouth_attacking_pressed.bind($Speach/Mouth))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
