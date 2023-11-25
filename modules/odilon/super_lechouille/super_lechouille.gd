extends Node2D

signal just_died

# TODO: SPAWN KISS WHEN KISSED

# MOB PARAMETERS
var DIFFICULTY : float = 0.0

# MOB SUB PARAMETERS
## Animation probabilities (integer easier to manipulate later : in %)
var WAIT_PROBABILITY : int = 20
var ATTACK_PROBABILITY : float = 40
var JUMP_PROBABILITY : float = 40

## WAITING
var IDLE_DURATION : float = 0.5 / (1.0 + log(1.0 + DIFFICULTY)) # The more difficult, shorter it will be

## JUMPING
var JUMP_DURATION : float = 1.0 / (1.0 + log(1.0 + DIFFICULTY)) # The more difficult, shorter it will be
var MAX_JUMPS : int = 3
var MAX_JUMP_DIST : float = 200

## ATTACKING
var SLURP_TIME : float = 1.5 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF ATTACK SPEED
var SLURP_OVERLAP_FACTOR : float = 0.1
var SLURP_LATENCY_FACTOR : float = 1
var NB_SLUPRS : int = 2

var SLURP_LIFE : float = 4.0 * (1.0 + log(1.0 + DIFFICULTY))
var MAX_SLURP_DAMAGE_PER_ATTACK : float = 3.0 * (1+ log(1.0 + DIFFICULTY))
## TODO: NUMBER OF DOGS DEPENDANT OF DIFFICULTY ?

# MOB STATE
var max_life_points : float = 40.0
var life_points : float = 40.0
var state : String # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var clickable_tween : Tween
var initial_pos : Vector2
@onready var character = get_tree().get_nodes_in_group("character").front()

## called when the node enters the scene tree for the first time.
func _ready():
	position = _chose_starting_spot()
	initial_pos = position
	$AnimatedBody/Head/RotationCenter/TextureButtonOpen.pressed.connect(_head_open_pressed)
	$AnimatedBody/Head/RotationCenter/TextureButtonAttacking.pressed.connect(_head_attacking_pressed)
	$AnimatedBody/Head/RotationCenter/AnimationPlayer.play("move")
	$AnimatedBody/Tail/TailAnim.speed_scale = 2
	$AnimatedBody/Tail/TailAnim.play("Move")
	
	$MobHPBar.max_value=max_life_points
	# avoid using await in the _ready function
	_play_appearing_animation.call_deferred()

func _chose_starting_spot():
	return Vector2(randf_range(-200, 200), randf_range(-200, 200))

func _play_appearing_animation():
	state = "appearing"
	modulate.a = 0.0
	
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	_chose_animation()

func _chose_animation():
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
	
# TODO: Move those animations in "AnimatedBody" & "Tongue" : Easier to have several dogs at once
func _play_waiting_animation():
	state = "waiting"
	$AnimatedBody/Sprite2DNormal.show()
	$AnimatedBody/Sprite2DAttacking.hide()
	
	clickable_tween = create_tween()
	await clickable_tween.tween_interval(IDLE_DURATION).finished
	
	_chose_animation()


func _play_jumping_animation():
	state = "jumping"
	# TODO: We have to put it in process, or launch a proper animation (idk if tweens can do proper parabolic animations)
	for jump_index in range(randi_range(1, MAX_JUMPS)):
		var random_jump_horiz_dist = randf_range(-MAX_JUMP_DIST, MAX_JUMP_DIST)
		var random_jump_vert_dist = randf_range(MAX_JUMP_DIST / 2, MAX_JUMP_DIST)
		clickable_tween = create_tween()
		clickable_tween.parallel().tween_property(self, "position:x", initial_pos.x + random_jump_horiz_dist/2, JUMP_DURATION/2).set_trans(Tween.TRANS_CUBIC)
		clickable_tween.parallel().tween_property(self, "position:y", initial_pos.y - random_jump_vert_dist, JUMP_DURATION/2).set_trans(Tween.TRANS_CUBIC)
		clickable_tween.chain().tween_property(self, "position:y", initial_pos.y, JUMP_DURATION).set_trans(Tween.TRANS_CUBIC)
		await clickable_tween.finished
		
	_chose_animation()

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
	tween.tween_property($AnimatedBody, "global_position", Vector2(start_pos.x, screen_size.y+200),  0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($AnimatedBody, "scale", Vector2(CLOSE_SCALE, CLOSE_SCALE), 0.5).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	await _play_licking_animation()
	
	# Come back to previous pos
	var t2 : Tween = create_tween()
	t2.tween_property($AnimatedBody, "global_position", start_pos,  0.5).set_trans(Tween.TRANS_CUBIC)
	t2.parallel().tween_property($AnimatedBody, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_CUBIC)
	await t2.finished

	# change state
	_chose_animation()


func _play_licking_animation():
	var lick_direction = Vector2.RIGHT
	var screen_begin = $CanvasLayer.get_viewport().get_visible_rect().position
	var screen_end = $CanvasLayer.get_viewport().get_visible_rect().end
	var screen_size = $CanvasLayer.get_viewport().get_visible_rect().size
	var random_screen_pos = Vector2(randf_range(-screen_size.x/2, screen_size.x/2), randf_range(-screen_size.y/2, screen_size.y/2))
	
	var ATTK_DIST : float = 200
	
	# Play pre-slurp animation
	
	# Play slurp attack
	$CanvasLayer/Tongue.modulate = Color(1, 1, 1, 0) # Also resets color if needed
	$CanvasLayer/Tongue.position = random_screen_pos
	$CanvasLayer/Tongue.show()
	var tt : Tween = create_tween();
	tt.tween_property($CanvasLayer/Tongue, "modulate:a", 1,  SLURP_LATENCY_FACTOR * 0.3).set_trans(Tween.TRANS_CUBIC)
	tt.tween_property($CanvasLayer/Tongue, "position", random_screen_pos+lick_direction*ATTK_DIST, SLURP_TIME).set_trans(Tween.TRANS_CUBIC)
	tt.tween_property($CanvasLayer/Tongue, "modulate:a", 0,  SLURP_LATENCY_FACTOR * 0.3).set_trans(Tween.TRANS_CUBIC)
	await tt.finished

	_attempt_damaging_character($CanvasLayer/Tongue.clicks)
	
	$CanvasLayer/Tongue.hide()
	


func _attempt_damaging_character(nb_tongue_clicks : int):
	if state == "attacking":
		var slurp_hp_ratio : float = max(SLURP_LIFE - nb_tongue_clicks, 0) / SLURP_LIFE
		if slurp_hp_ratio >= 1:
			character.hit(slurp_hp_ratio * MAX_SLURP_DAMAGE_PER_ATTACK)


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


@export var healthTransTime : float
var hp_bar_tween : Tween
func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property($MobHPBar,"value",life_points,healthTransTime)


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
	var tongue_hit_tween : Tween = create_tween()
	
	if $CanvasLayer/Tongue.clicks > SLURP_LIFE:
		$CanvasLayer/Tongue.modulate = Color(1.0, 0.4, 0.9)
	else:
		tongue_hit_tween.tween_property($CanvasLayer/Tongue, "modulate", Color(1.0, 0.5, 0.5), 0.1).set_trans(Tween.TRANS_CUBIC)
		tongue_hit_tween.tween_property($CanvasLayer/Tongue, "modulate", Color(1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass



	
