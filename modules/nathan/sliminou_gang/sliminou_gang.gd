extends Node2D

signal just_died

# MOB PARAMETERS
var DIFFICULTY : float = 0.0



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
	speaches = speaches_template.duplicate()
	speaches.shuffle()
	
func _get_a_speach():
	if speaches.size()== 0 :
		speaches = speaches_template.duplicate()
		speaches.shuffle()
	return speaches.pop_back()
	

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
