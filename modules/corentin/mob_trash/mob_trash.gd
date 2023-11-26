extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty

# MOB SUB PARAMETERS
## ATTACKING
var HAND_ATTACK_DURATION : float 
var HAND_DAMAGE_PER_ATTACK : float 
var HAND_ATTACK_INTERVAL : float 
## TODO: NUMBER OF HANDS DEPENDANT OF DIFFICULTY ?

func _set_difficulty(value : float):
	DIFFICULTY = value
	HAND_ATTACK_DURATION = 5.0 / (1.0 + log(1.0 + DIFFICULTY))
	HAND_DAMAGE_PER_ATTACK = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	HAND_ATTACK_INTERVAL = 5.0 / (1.0 + log(1.0 + DIFFICULTY))

# MOB HP BAR
@onready var mob_hp_progress_bar : TextureProgressBar = $MobHPBar/HBoxContainer/MobHpBar

# MOB STATE
var life_points : float = 20.0
var state : String # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var hands : Array[Node] = []
var character : Node = null

## called when the node enters the scene tree for the first time.
func _ready():
	# set difficulty
	_set_difficulty(DIFFICULTY) # REMI: THIS WAS MY BAD, I SHOULD HAVE DONE THAT BEFORE
	
	character = get_tree().get_nodes_in_group("character").front()
	
	$Body/SpriteRoot/Sprite2DNormal.pressed.connect(_try_get_hit)
	$Body/SpriteRoot/Sprite2DBeingHit.pressed.connect(_try_get_hit)
	
	$Body/SpriteRoot/Sprite2DNormal.show()
	$Body/SpriteRoot/Sprite2DBeingHit.hide()
	$Body/SpriteRoot/Sprite2DAttacking.hide()
	$Body/SpriteRoot/Sprite2DBeingBlocked.hide()
	mob_hp_progress_bar.max_value = life_points
	_set_hp_bar(life_points)
	
	# other
	hands = $Hands.get_children()
	for hand in hands:
		hand.get_node("TextureButtonAttacking").pressed.connect(_try_get_hit_hand)
	
	_phase_idle()

func _phase_idle():
	state = "idle"
	$Body/SpriteRoot/Sprite2DNormal.show()
	$Body/SpriteRoot/Sprite2DBeingHit.hide()
	$Body/SpriteRoot/Sprite2DAttacking.hide()
	$Body/SpriteRoot/Sprite2DBeingBlocked.hide()
	$Hands.hide()
	await get_tree().create_timer(HAND_ATTACK_INTERVAL).timeout
	_phase_attack()
	
func _phase_attack():
	state = "attacking"
	$Hands.show()
	$Body/SpriteRoot/Sprite2DNormal.hide()
	$Body/SpriteRoot/Sprite2DBeingHit.hide()
	$Body/SpriteRoot/Sprite2DAttacking.show()
	$Body/SpriteRoot/Sprite2DBeingBlocked.hide()
	await get_tree().create_timer(HAND_ATTACK_DURATION).timeout
	if state == "attacking":
		character.hit(HAND_DAMAGE_PER_ATTACK)
	_phase_idle()

func _try_get_hit_hand():
	if state == "attacking":
		state = "blocked"
		$Body/SpriteRoot/Sprite2DAttacking.hide()
		$Body/SpriteRoot/Sprite2DBeingBlocked.show()
		$Hands.hide()

var hit_timer : Timer
func _try_get_hit():
	if state == "idle":
		$Body/SpriteRoot/Sprite2DBeingHit.show()
		$Body/SpriteRoot/Sprite2DNormal.hide()
		_hit(character.damage_per_attack)
#		await get_tree().create_timer(1.0).timeout
#		$Body/SpriteRoot/Sprite2DBeingHit.show()
#		$Body/SpriteRoot/Sprite2DNormal.hide()
		
func _hit(damage_points : float):
	life_points -= damage_points
	_set_hp_bar(max(life_points,0))
	if life_points <= 0.0:
		just_died.emit()

var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)
