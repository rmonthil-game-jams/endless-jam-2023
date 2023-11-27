extends Node2D

# REMI: SCENE TWEAK: ADDED NODE2D FOR TONGUE (LETS YOU ANCHOR THE BUTTON WHERE YOU WANT)
# REMI: SCENE TWEAK: ADDED SPRITES FOR THE TONGUE BUTTON + HEAD SPRITE + HEAD SPRITES IN HEAD SCENE
# REMI: TODO MAYBE: REDUCE PROBABILITY OF ATTACK THE MORE YOU ATTACK (AND INVERSELY)?
# REMI: TODO MAYBE: ANIMATE SPECIFICALLY Tongue/Head SPRITE WHEN LICKED DAMAGED?

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = set_difficulty

var RANDOM_WAF_PITCH_MODIFIER : float = randf_range(-0.4, 0.4)

# MOB SUB PARAMETERS
## Animation probabilities (integer easier to manipulate : in %)
var WAIT_PROBABILITY : int #= 20
var ATTACK_PROBABILITY : float# = 30
var JUMP_PROBABILITY : float = 50

## ATTACKING
var SLURP_LATENCY : float = 0.2

# MOB STATE
var life_points : float = 30.0
var state : String # useles at the moment but who knows in the future?

# private
var MAX_LIFE_POINTS : float = 30.0
var MAX_IDLE_DURATION : float
var MAX_JUMP_DURATION : float
var SLURP_TIME : float
var SLURP_LIFE : float
var MAX_SLURP_DAMAGE_PER_ATTACK : float

## THIS IS THE PER-DOG DIFFICULTY. SEE "FIGHT" TO MODULATE THIS WITH THE GLOBAL DIFFICULTY !
func set_difficulty(d : float):
	DIFFICULTY = d
	MAX_IDLE_DURATION = 0.7 / (1.0 + log(1.0 + DIFFICULTY)) # The more difficult, shorter it will be
	MAX_JUMP_DURATION = 1.1 / (1.0 + log(1.0 + DIFFICULTY)) # The more difficult, shorter it will be
	SLURP_TIME = 3.0 / (1.0 + log(1.0 + 2*DIFFICULTY)) # INVERSE OF ATTACK SPEED
	SLURP_LIFE = 3.0 #* (1.0 + log(1.0 + DIFFICULTY))
	SLURP_LATENCY = 0.2 / (1.0 + 1*log(1.0 + DIFFICULTY))
	MAX_SLURP_DAMAGE_PER_ATTACK = 2.0 * (1 + log(1.0 + DIFFICULTY))
	MAX_LIFE_POINTS = 10 + 2 * (1 + DIFFICULTY)
	life_points = MAX_LIFE_POINTS
	ATTACK_PROBABILITY = 10 + 3*log(1 + DIFFICULTY)
	


## initialization is unecessary because they are already initialized to these values
var clickable_tween : Tween
@onready var character = get_tree().get_nodes_in_group("character").front()

# MOB HP BAR
@onready var mob_hp_progress_bar : TextureProgressBar = $AnimatedBody/MobHPBar/HBoxContainer/MobHpBar

## called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedBody/RotatingAnchor/Head/TextureButtonOpen.pressed.connect(_head_open_pressed)
	$AnimatedBody/RotatingAnchor/Head/TextureButtonAttacking.pressed.connect(_head_attacking_pressed)
	# Small variations if many
	var speed_variation = randf_range(-0.1, 0.1)
	$AnimatedBody/RotatingAnchor/Head/AnimationPlayer.speed_scale += speed_variation
	$AnimatedBody/RotatingAnchor/Tail/TailAnim.speed_scale += speed_variation
	
	$AnimatedBody/RotatingAnchor/Head/AnimationPlayer.play("move")
	$AnimatedBody/RotatingAnchor/Tail/TailAnim.play("Move")
	
	var anim_delta = randf()
	$AnimatedBody/RotatingAnchor/Head/AnimationPlayer.advance.call_deferred(anim_delta)
	$AnimatedBody/RotatingAnchor/Tail/TailAnim.advance.call_deferred(anim_delta)
	
	$AnimatedBody/Waf.pitch_scale += RANDOM_WAF_PITCH_MODIFIER
	
	# Force difficulty update if you only launch this scene
	set_difficulty(DIFFICULTY)

	mob_hp_progress_bar.max_value=MAX_LIFE_POINTS
	_set_hp_bar(MAX_LIFE_POINTS)

	# avoid using await in the _ready function
	_play_appearing_animation.call_deferred()



func _play_appear_fx():
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 400
	target_fx.h = 350
	target_fx.position = Vector2.UP * 50 # carefull these are local coordinates
	target_fx.play_sound = false
	$AnimatedBody/Waf.play()
	$AnimatedBody/RotatingAnchor/Head.add_child(target_fx)



func _play_appearing_animation():
	state = "appearing"
	modulate.a = 0.0

	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	_play_appear_fx()

	# Always first start with a random idle duration
	_play_waiting_animation.call_deferred()

func _sum_2d_array(array):
	var sum : float = 0.0
	for element in array:
		sum += element[0]
	return sum


func _choose_animation():
	var prev_state = state
	
	# print(prev_state)
	var possible_next_states
	if (prev_state == "comeback"): # Avoid attacks after appearing or attack
		possible_next_states = [[JUMP_PROBABILITY, _play_jumping_animation]]
	elif (prev_state == "appearing"):
		# Avoid attacks after appearing or attack
		possible_next_states = [[WAIT_PROBABILITY, _play_waiting_animation], [JUMP_PROBABILITY, _play_jumping_animation]]
	else:
		possible_next_states = [[WAIT_PROBABILITY, _play_waiting_animation], [JUMP_PROBABILITY, _play_jumping_animation], [ATTACK_PROBABILITY, _play_attacking_animation]]
	
	state = "thinking"
	# Randomly chose something to do (prefers jumps)
	var prob_sum = _sum_2d_array(possible_next_states)
	var rd = randi_range(0, prob_sum-1)
	
	var curr_prob : float = 0
	for next_state in possible_next_states:
		curr_prob += next_state[0]
		if (rd < curr_prob):
			# print(rd, " ", curr_prob, " ", next_state[0], " ", next_state[1])
			next_state[1].call_deferred()
			return
	
	# If error in the loop, call something
	possible_next_states[0][1].call_deferred()


func _play_waiting_animation():
	state = "waiting"
	$AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.show()
	$AnimatedBody/RotatingAnchor/Body/Sprite2DAttacking.hide()

	var idle_duration = randf_range(MAX_IDLE_DURATION / 2, MAX_IDLE_DURATION)

	clickable_tween = create_tween()
	await clickable_tween.tween_interval(idle_duration).finished

	_choose_animation()

func _get_hud_min_offset():
	return Vector2(300, 200) # 160, 60 # REMI: INCREASED MARGING TO ADAPT THE FACT THAT I REMOVED THE SIZE EVERYWHERE
	
func _get_hud_max_offset():
	return Vector2(300, 200) # 160, 60 # REMI: INCREASED MARGING TO ADAPT THE FACT THAT I REMOVED THE SIZE EVERYWHERE

# Scale factor induced by camera
func get_viewport_size():
	return get_viewport().get_visible_rect().size * 2

var turn_around_tween : Tween

var current_jump_strength : Vector2
var pos_before_jump : Vector2
var current_jump_duration : float
func _play_jumping_animation():
	state = "jumping"

	$UnitJumpPath/PathFollow2D.progress = 0
	current_jump_strength = Vector2(randf_range(-1, 1), randf_range(0.5, 1))

	# Adjust jump target st. it stays in bounds of the screen
	# Note: Use global_position to make sure we refer to the screen
	var screen_size = get_viewport_size().x
	var pmin = -screen_size / 2 + _get_hud_min_offset().x + 200
	var pmax = screen_size / 2 - _get_hud_max_offset().x - 300
	
	
	# Body was outside of screen already, go back inside
	if $AnimatedBody.global_position.x <= pmin:
		current_jump_strength.x = abs(current_jump_strength.x)
	elif $AnimatedBody.global_position.x >= pmax:
		current_jump_strength.x = -abs(current_jump_strength.x)
	else:
		# If body want's to go outside, try the opposite direction
		var target_x = $AnimatedBody.global_position.x + ($UnitJumpPath.curve.get_point_position(2).x - $UnitJumpPath.curve.get_point_position(0).x) * current_jump_strength.x
		# print(target_x, " ", pmin, " ", pmax, " ", $AnimatedBody.global_position.x)
		if (target_x <= pmin) or (target_x >= pmax):
			current_jump_strength.x = -current_jump_strength.x

	pos_before_jump = $AnimatedBody.position
	current_jump_duration = randf_range(MAX_JUMP_DURATION/2, MAX_JUMP_DURATION)
	
	# Start jump by turning in the right direction if needed (note that the sprite is facing left for scale>0)
	if signf(current_jump_strength.x) == signf($AnimatedBody.scale.x):
		if turn_around_tween != null and turn_around_tween.is_running():
			turn_around_tween.kill() # Should not happen, but who knows
		turn_around_tween = create_tween()
		
		turn_around_tween.tween_property($AnimatedBody/RotatingAnchor, "scale:x", -signf(current_jump_strength.x), min(0.1, current_jump_duration / 2)).set_trans(Tween.TRANS_CUBIC)
		#await turn_around_tween.finished
	
	# Script will continue in "_process"


var pos_before_attack
func _play_attacking_animation():
	state = "attacking"
	$AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.hide()
	$AnimatedBody/RotatingAnchor/Head/TextureButtonOpen.hide()
	$AnimatedBody/RotatingAnchor/Body/Sprite2DAttacking.show()
	$AnimatedBody/RotatingAnchor/Head/TextureButtonAttacking.show()

	var CLOSE_SCALE = 2.5

	pos_before_attack = $AnimatedBody.global_position

	# Disapear from screen (get closer to player)
	var tween : Tween = create_tween()
	tween.tween_property($AnimatedBody, "global_position", Vector2(pos_before_attack.x, get_viewport_size().y+500), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($AnimatedBody, "scale", Vector2(CLOSE_SCALE, CLOSE_SCALE), 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_callback($AnimatedBody/AggressiveWaf.play)
	tween.tween_callback($AnimatedBody.hide)
	await tween.finished

	_play_licking_animation.call_deferred()


func _get_random_screen_pos(): # REMI: REMOVED ELEMENT HERE (element : Control)
	var screen_size = get_viewport_size()
	
	var pmin : Vector2 = -screen_size / 2 + _get_hud_min_offset()
	var pmax : Vector2 = screen_size / 2 - _get_hud_max_offset() # REMI: - element.size * 2
	
	return Vector2(randf_range(pmin.x, pmax.x), randf_range(pmin.y, pmax.y))
	
func _get_random_lick_bottom_screen_pos():
	var screen_size = get_viewport_size()
	var random_pos = _get_random_screen_pos() # REMI: REMOVED ARGUMENT
	random_pos.y = screen_size.y / 2 - _get_hud_min_offset().y # SWAPPED TOP TO BOTTOM
	return random_pos


var tongue_clicks : int = 0
func _tongue_remaining_life() -> float:
	return max(int(SLURP_LIFE - tongue_clicks), 0)


func _play_tongue_appear_fx():
	var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
	target_fx.w = 485
	target_fx.h = 625
	target_fx.position = Vector2.ZERO # REMI: MODIFIED THAT
	$Tongue.add_child(target_fx)

var slurp_tween : Tween
var tongue_alive : bool
func _play_licking_animation():
	state = "licking"
	var screen_size = get_viewport_size()
	
	var random_bottom_screen_pos = _get_random_lick_bottom_screen_pos() # REMI: CHANGED TOP TO BOTTOM

	# Play pre-slurp animation

	# Play slurp attack
	$Tongue.modulate = Color(1, 1, 1, 0) # Also resets color if needed
	$Tongue.global_position = random_bottom_screen_pos
	$Tongue.show()
	tongue_alive = true
	slurp_tween = create_tween();
	slurp_tween.tween_property($Tongue, "modulate:a", 1,  SLURP_LATENCY).set_trans(Tween.TRANS_CUBIC)
	slurp_tween.parallel().tween_callback(_play_tongue_appear_fx)
	slurp_tween.chain().tween_property($Tongue, "global_position:y", -screen_size.y/2 + _get_hud_max_offset().y, SLURP_TIME).set_trans(Tween.TRANS_CUBIC) # REMI: REMOVED -$Tongue.size.y
	slurp_tween.tween_property($Tongue, "modulate:a", 0,  SLURP_LATENCY).set_trans(Tween.TRANS_CUBIC)
	await slurp_tween.finished
	tongue_alive = false

	_attempt_damaging_character()

	tongue_clicks = 0
	$Tongue.hide()
	
	_play_comeback_from_attack_animation.call_deferred()


func _play_comeback_from_attack_animation():
	state = "comeback"
	# Come back to previous pos
	$AnimatedBody.show()
	var t2 : Tween = create_tween()
	t2.tween_property($AnimatedBody, "global_position", pos_before_attack, 0.5).set_trans(Tween.TRANS_CUBIC)
	t2.parallel().tween_property($AnimatedBody, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_CUBIC)
	t2.chain().tween_interval(0.2)
	t2.tween_callback($AnimatedBody/Waf.play)
	await t2.finished

	$AnimatedBody/RotatingAnchor/Body/Sprite2DAttacking.hide()
	$AnimatedBody/RotatingAnchor/Head/TextureButtonAttacking.hide()
	$AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.show()
	$AnimatedBody/RotatingAnchor/Head/TextureButtonOpen.show()

	# REMI: PROBLEM HERE (so i commented), YOU WHERE POTENTIALLY PLAYING TWO ANIMATION AT THE SAME TIME
	# REMI: WHICH THEN MESSES UP WITH YOUR WHOLE STATE MACHINE

#	_play_appearing_animation() # REMI: -> this plays waiting after which plays _choose_animation after
#
#	_choose_animation() # REMI: -> this plays jump or lick

	_choose_animation.call_deferred() # REMI: I USE CALL DEFERRED TO AVOID STACKING FUNCTION CALLS


func _attempt_damaging_character():
	if state == "licking": # REMI: replaced "attacking" by "licking"
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

func _set_hp_bar(_hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)

func _play_death_sound():
	$AnimatedBody/DeathSound.play()


func _attempt_to_play_death_animation():
	if state != "dying":
		state = "dying"
		if clickable_tween:
			clickable_tween.kill()
		clickable_tween = create_tween()
		clickable_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		clickable_tween.parallel().tween_callback(_play_death_sound)
		await clickable_tween.finished
		just_died.emit()


func _head_attacking_pressed():
	# TODO: Maybe something (sound, etc.)
	pass


func _on_tongue_blocked():
	var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
	blocked_fx.TARGET_SCALE = Vector2(4.0, 4.0) # REMI: GOING BIG!!!
	blocked_fx.position = Vector2.ZERO # REMI: changed that
	$Tongue.add_child(blocked_fx)
	
	slurp_tween.kill()
	
	$Tongue.modulate = Color(0.5, 0.5, 0.5)
	$Tongue/TongueButton.disabled = true # REMI: AVOID CLICKING ON IT, SPECIFIC SPRITE MAYBE IN THE FUTURE ?
	# REMI: added an animation here
	# animation
	var tween : Tween
	tween = create_tween()
	tween.tween_property($Tongue, "scale", Vector2(0.8, 0.8), 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Tongue, "scale", Vector2(1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.set_loops(2)
	await tween.finished
	tween = create_tween()
	tween.tween_property($Tongue, "rotation", 0.125, 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Tongue, "rotation", -0.125, 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.set_loops(2)
	await tween.finished
	tween = create_tween()
	tween.tween_property($Tongue, "rotation", 0.0, 0.125).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($Tongue, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	# core
	tongue_clicks = 0
	$Tongue.hide()
	$Tongue/TongueButton.disabled = false # REMI: JUST BEING SURE BUTTON WILL BE READY LATER ON
	


func _on_tongue_pressed():
	tongue_clicks += 1
	if (_tongue_remaining_life() <= 0) && tongue_alive:
		tongue_alive = false
		await _on_tongue_blocked()
		if (state == "licking"):
			_play_comeback_from_attack_animation.call_deferred() # We killed a tween, we have to relaunch an animation from here
	else:
		var tongue_hit_tween : Tween = create_tween()
		tongue_hit_tween.tween_property($Tongue, "modulate", Color(1.0, 0.5, 0.5), 0.1).set_trans(Tween.TRANS_CUBIC)
		tongue_hit_tween.tween_property($Tongue, "modulate", Color(1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	if state == "jumping":
		$UnitJumpPath/PathFollow2D.progress_ratio += _delta / current_jump_duration
		var progress : float = $UnitJumpPath/PathFollow2D.progress_ratio
		
		# Use the grouped legs sprite for jump. Note that if I leave a weird bug, that would display both sprites during the animation,
		# we may have a smoother feeling of animation (but let's not do it because it's buggy though)
		if $AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.visible and progress > 0.2 and progress < 0.8:
			$AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.hide()
			$AnimatedBody/RotatingAnchor/Body/Sprite2DJump.show()
		elif $AnimatedBody/RotatingAnchor/Body/Sprite2DJump.visible and progress > 0.8:
			$AnimatedBody/RotatingAnchor/Body/Sprite2DJump.hide()
			$AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.show()
			
		
		var rel_pos = $UnitJumpPath/PathFollow2D.position - $UnitJumpPath.curve.get_point_position(0)
		var corrected_rel_pos = Vector2(rel_pos.x*current_jump_strength.x, rel_pos.y*current_jump_strength.y)
		$AnimatedBody.position = pos_before_jump + corrected_rel_pos
		# During jump, also do a very small rotation (using the normal is quite useful here)
		#$AnimatedBody.rotation = $UnitJumpPath/PathFollow2D.rotation

		if $UnitJumpPath/PathFollow2D.progress_ratio >= 1:
			state = "end_jump"
			$AnimatedBody/RotatingAnchor/Body/Sprite2DJump.hide()
			$AnimatedBody/RotatingAnchor/Body/Sprite2DNormal.show()
			_choose_animation.call_deferred()
