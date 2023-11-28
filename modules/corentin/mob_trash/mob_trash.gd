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
	HAND_ATTACK_DURATION = 3.0 / (1.0 + log(1.0 + DIFFICULTY))
	HAND_DAMAGE_PER_ATTACK = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	HAND_ATTACK_INTERVAL = 3.0 / (1.0 + log(1.0 + DIFFICULTY))

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
	
	modulate.a = 0
	$Body/SpriteRoot/Sprite2DNormal.show()
	$Body/SpriteRoot/Sprite2DAttacking.hide()
	$Body/SpriteRoot/Sprite2DBeingBlocked.hide()
	$Body/SpriteRoot/Sprite2DNormal.disabled = true
	mob_hp_progress_bar.max_value = life_points
	_set_hp_bar(life_points)
	
	var delay_appear_tween : Tween = create_tween()
	#delay_appear_tween.tween_interval(0.7)
	delay_appear_tween.tween_property(self, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC)
	await delay_appear_tween.finished
	
	# other
	hands = $Hands.get_children()
	for hand in hands:
		hand.get_node("TextureButtonAttacking").pressed.connect(_try_get_hit_hand.bind(hand))
	
	_phase_idle()

func _phase_idle():
	state = "idle"
	_play_target_on_mob()
	$Body/SpriteRoot/Sprite2DNormal.show()
	$Body/SpriteRoot/Sprite2DAttacking.hide()
	$Body/SpriteRoot/Sprite2DBeingBlocked.hide()
	$Hands.hide()
	await get_tree().create_timer(HAND_ATTACK_INTERVAL).timeout
	_phase_attack()

func _phase_attack():
	state = "attacking"
	
	$Body/SpriteRoot/Sprite2DNormal.hide()
	$Body/SpriteRoot/Sprite2DAttacking.show()
	$Body/SpriteRoot/Sprite2DBeingBlocked.hide()
	
	for hand in $Hands.get_children():
		hand.modulate.a = 0
	
	$Hands.show()
	var hand_appear : Tween = create_tween()
	for hand in $Hands.get_children():
		hand_appear.parallel().tween_property(hand, "modulate:a", 1, 0.25).set_trans(Tween.TRANS_CUBIC)
		var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
		target_fx.position = Vector2.ZERO # carefull these are local coordinates
		target_fx.w = 350
		target_fx.h = 300
		hand.add_child(target_fx)
	
	await hand_appear.tween_interval(HAND_ATTACK_DURATION).finished
	
	if state == "attacking":
		character.hit(HAND_DAMAGE_PER_ATTACK)
		_phase_idle()

func _stop_being_shocked():
	_phase_idle()

var BLOCKED_RECOVER_DURATION : float = 0.2
func _try_get_hit_hand(hand : Node2D):
	if state == "attacking":
		state = "blocked"
		$Body/SpriteRoot/Sprite2DNormal.hide()
		$Body/SpriteRoot/Sprite2DAttacking.hide()
		$Body/SpriteRoot/Sprite2DBeingBlocked.show()
		
		var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
		blocked_fx.position = hand.position # carefull these are local coordinates
		add_child(blocked_fx)
		
		var hand_disapear_anim : Tween = create_tween()
		hand_disapear_anim.tween_property(hand, "modulate:a", 0, 0.25).set_trans(Tween.TRANS_CUBIC)
		await hand_disapear_anim.finished
		
		$Hands.hide()
		
		var surprised_tween : Tween = create_tween()
		surprised_tween.tween_interval(BLOCKED_RECOVER_DURATION)
		surprised_tween.tween_callback(_stop_being_shocked)

func _play_target_on_mob():
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.position = Vector2.ZERO # carefull these are local coordinates
	target_fx.w = 450
	target_fx.h = 400
	add_child(target_fx)
	
	# Small mob animation when he gets targetable again
	var scale_tw = create_tween()
	scale_tw.tween_property($Body, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_ELASTIC)
	scale_tw.tween_property($Body, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_ELASTIC)
	
	var rotate_tw : Tween = create_tween()
	rotate_tw.tween_property($Body, "rotation_degrees", 10, 0.1).set_trans(Tween.TRANS_ELASTIC)
	rotate_tw.tween_property($Body, "rotation_degrees", -10, 0.05).set_trans(Tween.TRANS_ELASTIC)
	rotate_tw.tween_property($Body, "rotation_degrees", 10, 0.05).set_trans(Tween.TRANS_ELASTIC)
	rotate_tw.tween_property($Body, "rotation_degrees", 0, 0.05).set_trans(Tween.TRANS_ELASTIC)
	await rotate_tw.tween_interval(target_fx.ANIMATION_TIME - 0.25).finished
	
	# Sound effect appeared, we can start clicking
	$Body/SpriteRoot/Sprite2DNormal.disabled = false

var hit_timer : Timer
func _try_get_hit():
	if state == "idle":
		_hit(character.damage_per_attack)
#		await get_tree().create_timer(1.0).timeout
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
