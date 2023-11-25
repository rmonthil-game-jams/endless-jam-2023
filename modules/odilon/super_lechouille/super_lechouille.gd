extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = set_difficulty

# MOB SUB PARAMETERS
## Animation probabilities (integer easier to manipulate : in %)
var WAIT_PROBABILITY : int = 20
var ATTACK_PROBABILITY : float = 30
var JUMP_PROBABILITY : float = 50

## ATTACKING

var SLURP_OVERLAP_FACTOR : float = 0.1
var SLURP_LATENCY : float = 0.2
var NB_SLUPRS : int = 2

# MOB STATE
var max_life_points : float = 30.0
var life_points : float = 30.0
var state : String # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var clickable_tween : Tween
@onready var character = get_tree().get_nodes_in_group("character").front()

# MOB HP BAR
@onready var mob_hp_progress_bar : TextureProgressBar = $AnimatedBody/MobHPBar/HBoxContainer/MobHpBar

## called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedBody/Head/RotationCenter/TextureButtonOpen.pressed.connect(_head_open_pressed)
	$AnimatedBody/Head/RotationCenter/TextureButtonAttacking.pressed.connect(_head_attacking_pressed)
	# Small variations if many
	var speed_variation = randf_range(-0.1, 0.1)
	$AnimatedBody/Head/RotationCenter/AnimationPlayer.speed_scale += speed_variation
	$AnimatedBody/Tail/TailAnim.speed_scale += speed_variation
	
	$AnimatedBody/Head/RotationCenter/AnimationPlayer.play("move")
	$AnimatedBody/Tail/TailAnim.play("Move")
	
	var anim_delta = randf()
	$AnimatedBody/Head/RotationCenter/AnimationPlayer.advance.call_deferred(anim_delta)
	$AnimatedBody/Tail/TailAnim.advance.call_deferred(anim_delta)
	
	# Force difficulty update if you only launch this scene
	set_difficulty(DIFFICULTY)

	mob_hp_progress_bar.max_value=max_life_points

	# avoid using await in the _ready function
	_play_appearing_animation.call_deferred()


var MAX_IDLE_DURATION : float
var MAX_JUMP_DURATION : float
var SLURP_TIME : float
var SLURP_LIFE : float
var MAX_SLURP_DAMAGE_PER_ATTACK : float


func set_difficulty(d : float):
	DIFFICULTY = d
	MAX_IDLE_DURATION = 0.5 / (1.0 + log(1.0 + DIFFICULTY)) # The more difficult, shorter it will be
	MAX_JUMP_DURATION = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # The more difficult, shorter it will be
	SLURP_TIME = 1.5 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF ATTACK SPEED
	SLURP_LIFE = 3.0 * (1.0 + log(1.0 + DIFFICULTY))
	MAX_SLURP_DAMAGE_PER_ATTACK = 3.0 * (1+ log(1.0 + DIFFICULTY))


func _play_appearing_animation():
	state = "appearing"
	modulate.a = 0.0

	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	# Always first start with a random idle duration
	_play_waiting_animation.call_deferred()


func _choose_animation():
	state = "thinking"
	# Randomly chose something to do (prefer jumps)
	var prob_sum = WAIT_PROBABILITY + JUMP_PROBABILITY + ATTACK_PROBABILITY
	var rd = randi_range(0, prob_sum)
	if rd >= 0 && rd < WAIT_PROBABILITY:
		_play_waiting_animation.call_deferred()
	elif rd >= WAIT_PROBABILITY && rd < (WAIT_PROBABILITY + JUMP_PROBABILITY):
		_play_jumping_animation.call_deferred()
	else:
		_play_attacking_animation.call_deferred()


func _play_waiting_animation():
	state = "waiting"
	$AnimatedBody/Sprite2DNormal.show()
	$AnimatedBody/Sprite2DAttacking.hide()

	var idle_duration = randf_range(MAX_IDLE_DURATION / 2, MAX_IDLE_DURATION)

	clickable_tween = create_tween()
	await clickable_tween.tween_interval(idle_duration).finished

	_choose_animation()

func _get_hud_min_offset():
	return Vector2(80, 30)
	
func _get_hud_max_offset():
	return Vector2(40, 30)

var current_jump_strength : Vector2
var pos_before_jump : Vector2
var current_jump_duration : float
func _play_jumping_animation():
	state = "jumping"

	$AnimatedBody/UnitJumpPath/PathFollow2D.progress = 0
	current_jump_strength = Vector2(randf_range(-1, 1), randf_range(0.5, 1))

	# Adjust jump target st. it stays in bounds of the screen
	var target_x = position.x + ($AnimatedBody/UnitJumpPath.curve.get_point_position(2).x - $AnimatedBody/UnitJumpPath.curve.get_point_position(0).x) * current_jump_strength.x
	
	var screen_size = get_viewport().get_visible_rect().size.x
	var pmin = -screen_size / 2 + _get_hud_min_offset().x + 50
	var pmax = screen_size / 2 - _get_hud_max_offset().x - 100
	
	if target_x <= pmin || target_x >= pmax: 
		current_jump_strength.x = -current_jump_strength.x

	pos_before_jump = position
	current_jump_duration = randf_range(MAX_JUMP_DURATION/2, MAX_JUMP_DURATION)
	# Script will continue in "_process"


func _play_attacking_animation():
	state = "attacking"
	$AnimatedBody/Sprite2DNormal.hide()
	$AnimatedBody/Sprite2DAttacking.show()

	# Start position + direction
	var screen_size = get_viewport().get_visible_rect().size
	var screen_corner = get_viewport().get_visible_rect().position
	var random_screen_pos = screen_corner + Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))

	var CLOSE_SCALE = 2.5

	var start_pos = global_position

	# Disapear from screen (get closer to player)
	var tween : Tween = create_tween()
	tween.tween_property($AnimatedBody, "global_position", Vector2(start_pos.x, screen_size.y+250),  0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($AnimatedBody, "scale", Vector2(CLOSE_SCALE, CLOSE_SCALE), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback($AnimatedBody.hide)
	await tween.finished

	await _play_licking_animation()

	# Come back to previous pos
	$AnimatedBody.show()
	var t2 : Tween = create_tween()
	t2.tween_property($AnimatedBody, "global_position", start_pos,  0.5).set_trans(Tween.TRANS_CUBIC)
	t2.parallel().tween_property($AnimatedBody, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_CUBIC)
	await t2.finished

	# change state
	_choose_animation()

	
func _get_random_screen_pos(element : Control):
	var screen_size = get_viewport().get_visible_rect().size
	
	var pmin : Vector2 = -screen_size / 2 + _get_hud_min_offset()
	var pmax : Vector2 = screen_size / 2 - _get_hud_max_offset() - element.size
	
	return Vector2(randf_range(pmin.x, pmax.x), randf_range(pmin.y, pmax.y))
	
func _get_random_lick_top_screen_pos():
	var screen_size = get_viewport().get_visible_rect().size
	var random_pos = _get_random_screen_pos($Tongue)
	random_pos.y = -screen_size.y / 2 + _get_hud_min_offset().y
	return random_pos


var tongue_clicks : int = 0
func _tongue_remaining_life() -> float:
	return max(int(SLURP_LIFE - tongue_clicks), 0)


var slurp_tween : Tween
func _play_licking_animation():
	var screen_size = get_viewport().get_visible_rect().size
	
	var random_top_screen_pos = _get_random_lick_top_screen_pos()

	# Play pre-slurp animation

	# Play slurp attack
	$Tongue.modulate = Color(1, 1, 1, 0) # Also resets color if needed
	$Tongue.global_position = random_top_screen_pos
	$Tongue.show()
	slurp_tween = create_tween();
	slurp_tween.tween_property($Tongue, "modulate:a", 1,  SLURP_LATENCY).set_trans(Tween.TRANS_CUBIC)
	slurp_tween.tween_property($Tongue, "global_position:y", screen_size.y/2-_get_hud_max_offset().y-$Tongue.size.y, SLURP_TIME).set_trans(Tween.TRANS_CUBIC)
	await slurp_tween.finished
	if _tongue_remaining_life() > 0:
		var despawn_tween = create_tween()
		despawn_tween.tween_property($Tongue, "modulate:a", 0,  SLURP_LATENCY).set_trans(Tween.TRANS_CUBIC)
		await despawn_tween.finished

	_attempt_damaging_character()

	tongue_clicks = 0
	$Tongue.hide()


func _attempt_damaging_character():
	if state == "attacking":
		var tongue_remain_life : float = _tongue_remaining_life()
		if tongue_remain_life > 0:
			var slurp_dammage : int = (tongue_remain_life / SLURP_LIFE) * MAX_SLURP_DAMAGE_PER_ATTACK
			if (slurp_dammage >= 1):
				character.hit(slurp_dammage)


func _head_open_pressed():
	_hit(character.damage_per_attack)


func _hit(damage_points : float):
	life_points -= damage_points
	_set_hp_bar(max(life_points,0))
	_attempt_to_play_hit_animation()
	# TODO: DEATH ANIMATION
	if life_points <= 0.0:
		_attempt_to_play_death_animation()


var hit_tween : Tween

func _attempt_to_play_hit_animation():
	if not hit_tween or not hit_tween.is_running():
		hit_tween = create_tween()
		hit_tween.tween_property($AnimatedBody, "modulate", Color(1.0, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_property($AnimatedBody, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)


var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)


func _attempt_to_play_death_animation():
	if state != "dying":
		state = "dying"
		if clickable_tween:
			clickable_tween.kill()
		clickable_tween = create_tween()
		clickable_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		await clickable_tween.finished
		just_died.emit()


func _head_attacking_pressed(hand : Node2D):
	# TODO: Maybe something (sound, etc.)
	pass


func _on_tongue_pressed():
	tongue_clicks += 1
	if _tongue_remaining_life() <= 0:
		$Tongue.modulate = Color(0.5, 0.5, 0.5)
		await create_tween().tween_interval(.3).finished
		$Tongue.hide()
	else:
		var tongue_hit_tween : Tween = create_tween()
		tongue_hit_tween.tween_property($Tongue, "modulate", Color(1.0, 0.5, 0.5), 0.1).set_trans(Tween.TRANS_CUBIC)
		tongue_hit_tween.tween_property($Tongue, "modulate", Color(1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	if state == "jumping":
		$AnimatedBody/UnitJumpPath/PathFollow2D.progress_ratio += _delta / current_jump_duration
		
		var rel_pos = $AnimatedBody/UnitJumpPath/PathFollow2D.position - $AnimatedBody/UnitJumpPath.curve.get_point_position(0)
		var corrected_rel_pos = Vector2(rel_pos.x*current_jump_strength.x, rel_pos.y*current_jump_strength.y)
		position = pos_before_jump + corrected_rel_pos

		if $AnimatedBody/UnitJumpPath/PathFollow2D.progress_ratio >= 1:
			state = "end_jump"
			_choose_animation.call_deferred()
