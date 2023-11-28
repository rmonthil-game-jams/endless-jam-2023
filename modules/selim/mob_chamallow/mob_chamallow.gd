extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty

# MOB SUB PARAMETERS
## ATTACKING

var HAND_ATTACK_DURATION_FACTOR : float
var DAMAGE_PER_ATTACK_P1 : float
var DAMAGE_PER_ATTACK_P2 : float
var TIME_BETWEEN_ATTACKS_P1 : float
var TIME_BETWEEN_ATTACKS_P2 : float
var ATTACK_WINDOW_OFFSET : Vector2 = Vector2(0.0, -200.0)
var X_MARGIN : int = 450
var Y_MARGIN : int = 450
var ATTACK_WINDOW_RANGE_INTER_MARGING : float = 200.0
var ATTACK_WINDOW_RANGE : Vector2
var ATTACK_SCALE : Vector2 = Vector2(1.0, 1.0) # REMI: TRY TO AVOID RESCALING IMAGES PERMANENTLY
var DAMAGE_MULTIPLIER : int = 0
var TRAN : bool = false
var DEAD : bool = false

func _set_difficulty(value : float): # REMI: THIS WAS MY BAD, I SHOULD HAVE DONE THAT BEFORE
	DIFFICULTY = value
	HAND_ATTACK_DURATION_FACTOR = 2.0 / (1.0 + 0.8*log(1.0 + DIFFICULTY))
	DAMAGE_PER_ATTACK_P1 = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	DAMAGE_PER_ATTACK_P2 = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	TIME_BETWEEN_ATTACKS_P1 = 2.5 / (1.0 + 1.3 * log(1.0 + DIFFICULTY))
	TIME_BETWEEN_ATTACKS_P2 = 4.5 / (1.0 + log(1.0 + DIFFICULTY))
	life_points = 18 + ( 4 * (1.0 + DIFFICULTY))
	full_mob_hp = life_points

# MOB STATE
var full_mob_hp : float
var life_points
var state : String # useles at the moment but who knows in the future?

# private

# REMI: MOB HP BAR
@onready var mob_hp_progress_bar : TextureProgressBar = $MobHPBar/HBoxContainer/MobHpBar

## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var bodies : Array[Node] = []
var attacks : Array[Node] = []
var attacks2 : Array[Node] = []
var hands_state : Dictionary = {}
var character : Node = null
var rng = RandomNumberGenerator.new()
var blocked_tween_p2 : Tween = null

## called when the node enters the scene tree for the first time.
func _ready():
	# set difficulty
	_set_difficulty(DIFFICULTY) # REMI: THIS WAS MY BAD, I SHOULD HAVE DONE THAT BEFORE
	
	character = get_tree().get_nodes_in_group("character").front() 
	# other
	ATTACK_WINDOW_RANGE = (2*get_viewport_rect().size - 2*Vector2(X_MARGIN,Y_MARGIN))/2
	$Body.get_node("TextureButtonP1").pressed.connect(_body_attacks.bind(character.damage_per_attack))
	$Body.get_node("TextureButtonP2").pressed.connect(_body_attacks.bind(character.damage_per_attack))
	$AttackP1.get_node("TextureButtonAttackP1").pressed.connect(_block_attack.bind())
	bodies = $Body.get_children()
	for body in bodies:
		body.hide()
	attacks = $AttackP1.get_children()
	for attack in attacks:
		attack.hide()

	attacks2 = $AttacksP2.get_children()
	for attack in attacks2:
		attack.get_node("TextureButtonAttackP2").pressed.connect(_block_attack_2.bind(attack))

	# REMI: hp bar
	mob_hp_progress_bar.max_value = life_points
	_set_hp_bar(life_points)
	_play_appearing_animation.call_deferred()
	

#
func _play_appearing_animation():
	# init
	$Body/Sprite2DPhase1.show()
	state = "appearing"
	modulate.a = 0.0
	# animation
	main_tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	_phase_1()
	
func _phase_1():
	state = "phase_1"
	$Body/TextureButtonP1.show()
	$Body/Sprite2DPhase1.hide()
	
	# add target fx
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 394.0
	target_fx.h = 359.0
	target_fx.position = $Body.position # carefull these are local coordinates
	add_child(target_fx)
	
	await get_tree().create_timer(TIME_BETWEEN_ATTACKS_P1).timeout
	if TRAN:
		pass
	else:
		_phase_1_attack()
	

func _phase_1_attack():
	$Body/Sprite2DAtttackingP1.show()
	$Body/TextureButtonP1.hide()
	$AttackP1/TextureButtonAttackP1.show()
	
	$AttackP1/TextureButtonAttackP1.disabled = true
	
	# prepare anim
	$AttackP1.modulate.a = 0.0
	$AttackP1.scale = Vector2(0.125, 0.125)
	$AttackP1.position = Vector2.UP * 300.0
	var target_position : Vector2 = ATTACK_WINDOW_OFFSET + Vector2(rng.randf_range(-ATTACK_WINDOW_RANGE[0], ATTACK_WINDOW_RANGE[0]), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
	
	# appear
	main_tween = create_tween()
	main_tween.tween_property($AttackP1, "modulate:a", 1.0, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttackP1, "scale", ATTACK_SCALE, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttackP1, "position", target_position, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	# attack
	await  main_tween.finished
	# enable button
	$AttackP1/TextureButtonAttackP1.disabled = false
	# target fx
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 421.0
	target_fx.h = 348.0
	target_fx.position = $AttackP1.position # carefull these are local coordinates
	add_child(target_fx)
	# loop
	main_tween = create_tween()
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.set_loops(2)
	await  main_tween.finished
	# attack
	main_tween = create_tween()
	main_tween.tween_property($AttackP1/TextureButtonAttackP1, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_callback(_end_phase_1_attack)

func _end_phase_1_attack():
	$AttackP1/TextureButtonAttackP1.hide()
	$AttackP1/TextureButtonAttackP1.scale = ATTACK_SCALE
	character.hit(DAMAGE_PER_ATTACK_P1)
	if TRAN:
		pass
	else:
		_phase_1()


func _phase_2_attack():
	state = "phase_2"
	$Body/Sprite2DPhase2.show()
	$Body/TextureButtonP2.hide()
	for i in range(2): # REMI: I REDUCED THIS NUMBER
		# prepare anim
		$AttacksP2/AttackP21.modulate.a = 0.0
		$AttacksP2/AttackP21.scale = Vector2(0.125, 0.125)
		$AttacksP2/AttackP21.position = Vector2.UP * 300.0
		var target_position_1 : Vector2 = ATTACK_WINDOW_OFFSET + Vector2(rng.randf_range(-ATTACK_WINDOW_RANGE[0], -ATTACK_WINDOW_RANGE_INTER_MARGING), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
		$AttacksP2/AttackP22.modulate.a = 0.0
		$AttacksP2/AttackP22.scale = Vector2(0.125, 0.125)
		$AttacksP2/AttackP22.position = Vector2.UP * 300.0
		var target_position_2 : Vector2 = ATTACK_WINDOW_OFFSET + Vector2(rng.randf_range(ATTACK_WINDOW_RANGE_INTER_MARGING, ATTACK_WINDOW_RANGE[0]), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
		
		$AttacksP2/AttackP21/TextureButtonAttackP2.show()
		$AttacksP2/AttackP22/TextureButtonAttackP2.show()
		
		$AttacksP2/AttackP21/TextureButtonAttackP2.disabled = true
		$AttacksP2/AttackP22/TextureButtonAttackP2.disabled = true
		
		# appear
		main_tween = create_tween()
		main_tween.tween_property($AttacksP2/AttackP21, "modulate:a", 1.0, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP22, "modulate:a", 1.0, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.tween_property($AttacksP2/AttackP21, "scale", ATTACK_SCALE, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP21, "position", target_position_1, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP22, "scale", ATTACK_SCALE, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP22, "position", target_position_2, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		await  main_tween.finished
		# attack
		$AttacksP2/AttackP21/TextureButtonAttackP2.disabled = false
		$AttacksP2/AttackP22/TextureButtonAttackP2.disabled = false
		# target fx
		var target_fx1 = preload("res://modules/remi/fx/target.tscn").instantiate()
		var target_fx2 = preload("res://modules/remi/fx/target.tscn").instantiate()
		target_fx1.w = 421.0
		target_fx1.h = 348.0
		target_fx2.w = 421.0
		target_fx2.h = 348.0
		target_fx1.position = $AttacksP2/AttackP21.position # carefull these are local coordinates
		target_fx2.position = $AttacksP2/AttackP22.position # carefull these are local coordinates
		add_child(target_fx1)
		add_child(target_fx2)
		# anim
		main_tween = create_tween()
		main_tween.tween_property($AttacksP2/AttackP21/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP22/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.tween_property($AttacksP2/AttackP21/TextureButtonAttackP2, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP22/TextureButtonAttackP2, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.set_loops(2)
		await  main_tween.finished
		# attack
		main_tween = create_tween()
		main_tween.tween_property($AttacksP2/AttackP21/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.parallel().tween_property($AttacksP2/AttackP22/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
		main_tween.tween_callback(_end_phase_2_attack_1)
		await main_tween.finished
		
	# prepare anim
	$AttacksP2/AttackP21.modulate.a = 0.0
	$AttacksP2/AttackP21.scale = Vector2(0.125, 0.125)
	$AttacksP2/AttackP21.position = Vector2.UP * 300.0
	var target_position_1 : Vector2 = ATTACK_WINDOW_OFFSET + Vector2(rng.randf_range(-ATTACK_WINDOW_RANGE[0], -0.5 * ATTACK_WINDOW_RANGE[0]/3.0 - ATTACK_WINDOW_RANGE_INTER_MARGING), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
	$AttacksP2/AttackP22.modulate.a = 0.0
	$AttacksP2/AttackP22.scale = Vector2(0.125, 0.125)
	$AttacksP2/AttackP22.position = Vector2.UP * 300.0
	var target_position_2 : Vector2 = ATTACK_WINDOW_OFFSET + Vector2(rng.randf_range(-0.5 * ATTACK_WINDOW_RANGE[0]/3.0 + ATTACK_WINDOW_RANGE_INTER_MARGING, 0.5 * ATTACK_WINDOW_RANGE[0]/3.0 - ATTACK_WINDOW_RANGE_INTER_MARGING), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
	$AttacksP2/AttackP23.modulate.a = 0.0
	$AttacksP2/AttackP23.scale = Vector2(0.125, 0.125)
	$AttacksP2/AttackP23.position = Vector2.UP * 300.0
	var target_position_3 : Vector2 = ATTACK_WINDOW_OFFSET + Vector2(rng.randf_range(0.5 * ATTACK_WINDOW_RANGE[0]/3.0 + ATTACK_WINDOW_RANGE_INTER_MARGING, ATTACK_WINDOW_RANGE[0]), rng.randf_range(-ATTACK_WINDOW_RANGE[1], ATTACK_WINDOW_RANGE[1]))
	
	$AttacksP2/AttackP21/TextureButtonAttackP2.show()
	$AttacksP2/AttackP22/TextureButtonAttackP2.show()
	$AttacksP2/AttackP23/TextureButtonAttackP2.show()
	$AttacksP2/AttackP21/TextureButtonAttackP2.disabled = true
	$AttacksP2/AttackP22/TextureButtonAttackP2.disabled = true
	$AttacksP2/AttackP23/TextureButtonAttackP2.disabled = true
	
	# appear
	main_tween = create_tween()
	main_tween.tween_property($AttacksP2/AttackP21, "modulate:a", 1.0, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP22, "modulate:a", 1.0, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP23, "modulate:a", 1.0, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttacksP2/AttackP21, "scale", ATTACK_SCALE, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP21, "position", target_position_1, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP22, "scale", ATTACK_SCALE, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP22, "position", target_position_2, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP23, "scale", ATTACK_SCALE, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP23, "position", target_position_3, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	await  main_tween.finished
	
	$AttacksP2/AttackP21/TextureButtonAttackP2.disabled = false
	$AttacksP2/AttackP22/TextureButtonAttackP2.disabled = false
	$AttacksP2/AttackP23/TextureButtonAttackP2.disabled = false
	
	var target_fx1 = preload("res://modules/remi/fx/target.tscn").instantiate()
	var target_fx2 = preload("res://modules/remi/fx/target.tscn").instantiate()
	var target_fx3 = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx1.w = 421.0
	target_fx1.h = 348.0
	target_fx2.w = 421.0
	target_fx2.h = 348.0
	target_fx3.w = 421.0
	target_fx3.h = 348.0
	target_fx1.position = $AttacksP2/AttackP21.position
	target_fx2.position = $AttacksP2/AttackP22.position
	target_fx3.position = $AttacksP2/AttackP22.position
	add_child(target_fx1)
	add_child(target_fx2)
	add_child(target_fx3)
	
	main_tween = create_tween()
	main_tween.tween_property($AttacksP2/AttackP21/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP22/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP23/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.1, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($AttacksP2/AttackP21/TextureButtonAttackP2, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP22/TextureButtonAttackP2, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP23/TextureButtonAttackP2, "scale", ATTACK_SCALE, 0.5 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.set_loops(2)
	await  main_tween.finished
	
	main_tween = create_tween()
	main_tween.tween_property($AttacksP2/AttackP21/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP22/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($AttacksP2/AttackP23/TextureButtonAttackP2, "scale", ATTACK_SCALE * 1.5, 0.125 * HAND_ATTACK_DURATION_FACTOR).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_callback(_end_phase_2_attack_1)
	await main_tween.finished
	
	_phase_2()
	
func _phase_2():
	state = "phase_2"
	for body in bodies:
		body.hide()
	$Body/TextureButtonP2.show()
	
	# add target fx
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 394.0
	target_fx.h = 359.0
	target_fx.position = $Body.position # carefull these are local coordinates
	add_child(target_fx)
	
	await get_tree().create_timer(TIME_BETWEEN_ATTACKS_P2).timeout
	if DEAD:
		pass
	else:
		_phase_2_attack()
		
	
func _end_phase_2_attack_1():
	for attack2 in attacks2:
		if attack2.get_node("TextureButtonAttackP2").visible:
			attack2.get_node("TextureButtonAttackP2").hide()
			DAMAGE_MULTIPLIER += 1
		attack2.get_node("TextureButtonAttackP2").scale = ATTACK_SCALE	
	
	if DAMAGE_MULTIPLIER != 0:
		character.hit(DAMAGE_PER_ATTACK_P2*DAMAGE_MULTIPLIER)
		
	DAMAGE_MULTIPLIER = 0


func _body_attacks(damage : float):
	life_points -= damage
	_set_hp_bar(max(life_points,0))
	if life_points <= 0.0:
		DEAD = true
		_death_animation()
	elif life_points <= full_mob_hp/2 && state == "phase_1":
		TRAN = true
		_transition_to_phase_2()
	elif state == "phase_2":
		$Body/TextureButtonP2.modulate += Color(0.01, -0.01, -0.01, 0.0)
		$Body/Sprite2DPhase2.modulate += Color(0.01, -0.01, -0.01, 0.0)
		$Body/Sprite2DAttacked.modulate += Color(0.01, -0.01, -0.01, 0.0)
		
		
func _transition_to_phase_2():
	state = "transitioning_phase_2"
	for body in bodies:
		body.hide()
	$Body/Sprite2DTrans.show()
	# REMI: first it gets bigger
	main_tween = create_tween()
	main_tween.tween_property($Body/Sprite2DTrans, "scale", Vector2(1.6, 1.6), 0.25).set_trans(Tween.TRANS_ELASTIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "modulate", Color(0.5, 0.0, 0.0), 0.25).set_trans(Tween.TRANS_ELASTIC)
	await main_tween.finished
	# REMI: then loop animation
	main_tween = create_tween()
	main_tween.tween_property($Body/Sprite2DTrans, "modulate", Color(0.5, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "scale", Vector2(1.65, 1.65), 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "rotation", -0.0625, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DTrans, "modulate", Color(0.5, 0.0, 0.0), 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "scale", Vector2(1.55, 1.55), 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "rotation", 0.0625, 0.125).set_trans(Tween.TRANS_CUBIC)
	main_tween.set_loops(4)
	await main_tween.finished
	# REMI: then go back to previous size
	main_tween = create_tween()
	main_tween.tween_property($Body/Sprite2DTrans, "modulate", Color(0.5, 0.5, 0.5), 0.25).set_trans(Tween.TRANS_ELASTIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_ELASTIC)
	main_tween.parallel().tween_property($Body/Sprite2DTrans, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC)
	main_tween.tween_callback($Body/Sprite2DTrans.hide)
	await main_tween.finished
	
	$Body/Sprite2DPhase2.show()
	_phase_2_attack.call_deferred()
	

func _block_attack():
	$Body/Sprite2DAtttackingP1.hide()
	$AttackP1/TextureButtonAttackP1.hide()
	$AttackP1/TextureButtonAttackP1.scale = ATTACK_SCALE
	main_tween.kill()
	$AttackP1/Sprite2DAttackedP1.show()
	
	var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
	blocked_fx.TARGET_SCALE = Vector2.ONE * 3.0
	blocked_fx.position = $AttackP1.position # carefull these are local coordinates
	add_child(blocked_fx)
	
	main_tween = create_tween()
	main_tween.tween_property($AttackP1/Sprite2DAttackedP1, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_callback($AttackP1/Sprite2DAttackedP1.hide)
	main_tween.tween_callback(_end_animation.bind($AttackP1/Sprite2DAttackedP1))
	
	_phase_1()

func _block_attack_2(attack : Node2D):
	attack.get_node("TextureButtonAttackP2").hide()
	attack.scale = ATTACK_SCALE
	attack.get_node("Sprite2DAttackedP2").show()
	
	var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
	blocked_fx.TARGET_SCALE = Vector2.ONE * 3.0
	blocked_fx.position = attack.position # carefull these are local coordinates
	add_child(blocked_fx)
	
	blocked_tween_p2 = create_tween()
	blocked_tween_p2.tween_property(attack.get_node("Sprite2DAttackedP2"), "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	blocked_tween_p2.tween_callback(attack.get_node("Sprite2DAttackedP2").hide)
	blocked_tween_p2.tween_callback(_end_animation.bind(attack.get_node("Sprite2DAttackedP2")))
	
	
func _is_false(val):
	return val==false
	
func _end_animation(attack_sprite):
	attack_sprite.modulate.a = 1.0
	
	
func _death_animation():
	main_tween.kill()
	for body in bodies:
		body.hide()
	$Body/Sprite2DAttacked.show()
	
	# hide hp bar first
	main_tween = create_tween()
	main_tween.tween_property($MobHPBar, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	
	main_tween = create_tween()
	main_tween.tween_property($Body/Sprite2DAttacked, "modulate", $Body/Sprite2DAttacked2.modulate, 1.0).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body/Sprite2DAttacked, "position", Vector2(0.0, -100), 1.0).set_trans(Tween.TRANS_CUBIC)
	main_tween.parallel().tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -100), 1.0).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished	
	$Body/Sprite2DDefeat.show()
	$Body/Sprite2DAttacked.hide()
	main_tween = create_tween()	
	main_tween.tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -150), 0.2).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -100), 0.25).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -150), 0.25).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -100), 0.25).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -150), 0.25).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DDefeat, "position", Vector2(0.0, -100), 0.25).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Body/Sprite2DDefeat, "scale", Vector2(0.0, 0.0), 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
		
	just_died.emit()
	
# REMI: HP BAR

var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
#	print(life_points)
	pass
