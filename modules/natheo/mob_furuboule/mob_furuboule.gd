extends Node2D

signal just_died


# MOB PARAMETERS
var DIFFICULTY : float = 3.0

# MOB SUB PARAMETERS

## SUNS GEOMETRY
const SUNS_REL_DISTANCE = 300.0
const SUNS_POSSIBLE_ANGLES : Array[float] = [PI, -3.0*PI/4.0, -PI/2.0, -PI/4.0, 0.0]
const GATHER_POSITION = Vector2(0.0, 200.0)

## WAITING
var WAITING_ROTATION_DURATION : float = 5.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
const WAITING_LOOP_NUMBER : int = 2

## SHAKING
const SUN_SHAKING_N : int = 5
var SUN_SHAKING_DURATION : float = 5.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF MOVEMENT SPEED
const SUN_SHAKING_DISTANCE : float = 5.0

## REDUCING
const SUN_REDUCING_SCALE : float = 0.05

## ABSORBING
const SUN_ABSORBING_DURATION : float = 0.3
const SUN_ABSORBED_DURATION : float = 0.3

## LAUNCHING
const SUNBEAM_LAUNCHING_POSITION = Vector2(0.0, 110.0)
var SUNBEAM_LAUNCHING_DURATION : float = 5.0 / (1.0 + log(1.0 + DIFFICULTY)) # INVERSE OF ATTACK SPEED

# MOB PROPERTIES
var SUNBEAM_DMG : float = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
@onready var mob_hp_progress_bar : TextureProgressBar = $MobHPBar/HBoxContainer/MobHpBar

# MOB STATE
var life_points : float = 40.0
var state : String # useles at the moment but who knows in the future?

# private

## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var suns : Array[Node] = []
var suns_state : Dictionary = {}
var sunbeam_state : Dictionary = {}
var character : Node = null

## called when the node enters the scene tree for the first time.
func _ready():
	
	# setup suns
	suns = $Furuboule/Suns.get_children()
	for sun in suns:
		sun.hide()
		# setup signals
		sun.get_node("TextureButtonHitting").pressed.connect(_sun_hitting_pressed.bind(sun))
		sun.get_node("TextureButtonBlocking").pressed.connect(_sun_blocking_pressed.bind(sun))
		sun.get_node("TextureButtonShaking").pressed.connect(_sun_shaking_pressed.bind(sun))

	# setup signals for beam
	$SunBeam.hide()
	$SunBeam.get_node("TextureButtonBlocking").pressed.connect(_sunbeam_blocking_pressed.bind())
	$SunBeam.get_node("TextureButtonShaking").pressed.connect(_sunbeam_shaking_pressed.bind())
	
	character = get_tree().get_nodes_in_group("character").front()
	# avoid using await in the _ready function
	mob_hp_progress_bar.max_value = life_points
	
	_play_appearing_animation.call_deferred()


func _init_suns():

	# Initialize the suns
	var suns_posible_angles_left : Array[float] = SUNS_POSSIBLE_ANGLES.duplicate()
	for sun in suns:
		
		# setup state and randomize position
		var random_sun_angle_id : int =  randi() % len(suns_posible_angles_left)
		suns_state[sun] = {
			"angle":suns_posible_angles_left[random_sun_angle_id],
			"rel_energy": 1.0,
			"state":"creating"
		}
		suns_posible_angles_left.pop_at(random_sun_angle_id)
		
		# setup sun geometry
		sun.position = Vector2(
			SUNS_REL_DISTANCE*cos(suns_state[sun]["angle"]),
			SUNS_REL_DISTANCE*sin(suns_state[sun]["angle"])
		)
		sun.scale = Vector2(0.0, 0.0)
		
		# Set as hitting
		_attempt_to_hit_sun(sun)
		
		# Show the suns
		sun.show()


func _init_sunbeam():
	# Initialize sunbeam at no energy
	$SunBeam.scale = Vector2(0.0, 0.0)
	$SunBeam.position = GATHER_POSITION
	sunbeam_state = {
			"rel_energy": 0.0,
			"state":"creating"
		}
	$SunBeam.hide()
	$SunBeam.get_node("TextureButtonBlocking").show()
	$SunBeam.get_node("TextureButtonShaking").hide()


func _play_appearing_animation():
	# init
	state = "appearing"
	
#	# animation
	modulate.a = 0.0
	main_tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	
	_play_waiting_animation.call_deferred()


func _play_waiting_animation():
	state = "waiting"
	$Furuboule/Body/Sprite2DNormal.show()
	$Furuboule/Body/Sprite2DBeam.hide()
	$Furuboule/Body/Sprite2DBlocked.hide()
	
	_init_suns()
	_init_sunbeam()

	for loop_index in range(WAITING_LOOP_NUMBER):
		main_tween = create_tween()
	
		# Furuboule is turning randomly around the same center
		# With the associated suns
		var random_rotation = [-1.0, 1.0][randi() % 2] * randf_range(PI, 2*PI)
		main_tween.tween_property($Furuboule, "rotation", random_rotation, WAITING_ROTATION_DURATION).as_relative().from_current().set_trans(Tween.TRANS_SINE)
		
		# Animation of the suns
		for sun in suns:
			main_tween.parallel().tween_property(sun, "scale", 
				Vector2(1.0/(WAITING_LOOP_NUMBER - loop_index), 1.0/(WAITING_LOOP_NUMBER - loop_index)),
				WAITING_ROTATION_DURATION).set_trans(Tween.TRANS_LINEAR)

		await main_tween.finished
	
	_play_preparing_animation.call_deferred()


func _play_preparing_animation():
	state = "preparing"
	
	# Reinitialize rotation
	for sun in suns:
		_attempt_to_block_sun(sun)
	
#	var n_pi : float = $Furuboule.rotation / 2*PI
#	print(n_pi)
#	var rel_rotation : float = (round(abs(n_pi)) - abs(n_pi)) * sign(n_pi) * 2*PI
#	print(rel_rotation)
	
	main_tween = create_tween()
	main_tween.tween_property($Furuboule, "rotation", 0.0, 0.25 * WAITING_ROTATION_DURATION)
	await main_tween.finished
	
	_play_attacking_suns_animation.call_deferred()
	


func _play_attacking_suns_animation():
	state = "attacking_suns"
	$Furuboule/Body/Sprite2DNormal.hide()
	$Furuboule/Body/Sprite2DAttacking.show()
	
	# shuffle randomly the list of suns
	var copy_of_suns : Array[Node] = suns.duplicate()
	copy_of_suns.shuffle()
	
	# gather suns towards the hands
	$SunBeam.show()
	var first : bool = true
	for sun in copy_of_suns:
		
		main_tween = create_tween()
		
		# Firstly, sun is shaking and player can shrink its energy
		_attempt_to_shake_sun(sun)
		
		main_tween = create_tween()
		var shake_move_time : float = SUN_SHAKING_DURATION / (SUN_SHAKING_N*2) #because return trip
		for i in range(SUN_SHAKING_N):
			# Get random position around
			var random_angle : float = randf_range(0, 2*PI)
			var random_vect_add = Vector2(
				SUN_SHAKING_DISTANCE*cos(random_angle),
				SUN_SHAKING_DISTANCE*sin(random_angle)
			)
			# Go to the position and come back
			var initial_pos = sun.position
#			
			main_tween.tween_property(sun, "position", random_vect_add, shake_move_time).as_relative().from_current().set_trans(Tween.TRANS_LINEAR)
			main_tween.tween_property(sun, "position", initial_pos, shake_move_time).set_trans(Tween.TRANS_LINEAR)
		await main_tween.finished
		
		_attempt_to_block_sun(sun)
		
		# Secondly, sun is coming towards the hands and is absorbed, increasing the final beam
		# Only if the sun has not been totally skrunk
		if (suns_state[sun]["rel_energy"] > 0.0):
			# Sun go to absorbing zone
			main_tween = create_tween()
			main_tween.tween_property(sun, "position", GATHER_POSITION, SUN_ABSORBING_DURATION).set_trans(Tween.TRANS_EXPO)
			await main_tween.finished
			
			# Remove Sun
			sun.hide()
			
			# Increase sunbeam
			sunbeam_state["rel_energy"] += suns_state[sun]["rel_energy"]
			var final_scale = Vector2(suns_state[sun]["rel_energy"], suns_state[sun]["rel_energy"])
			if first:
				$SunBeam.scale = final_scale
				first = false
			else:
				main_tween = create_tween()
				main_tween.tween_property($SunBeam, "scale", final_scale, SUN_ABSORBED_DURATION).as_relative().from_current().set_trans(Tween.TRANS_EXPO)
				await main_tween.finished

	_play_attacking_beam_animation()


func _play_attacking_beam_animation():
	state = "attacking_beam"
	
	# Canalizing energy and we have to try limit dmg
	# Go for launching only if energy has been accumulated
	$Furuboule/Body/Sprite2DAttacking.hide()
	if sunbeam_state["rel_energy"] > SUN_REDUCING_SCALE:
		$Furuboule/Body/Sprite2DBeam.show()
		
		_attempt_to_shake_sunbeam()
		
		# Sunbeam go to final position, player can reduce damage by clicking
		main_tween = create_tween()
		main_tween.tween_property($SunBeam, "position", SUNBEAM_LAUNCHING_POSITION, SUNBEAM_LAUNCHING_DURATION).set_trans(Tween.TRANS_LINEAR)
		await main_tween.finished
		
		_attempt_to_block_sunbeam()
		
		# Launching beam only if it has not been totally shrinked
		if sunbeam_state["rel_energy"] > SUN_REDUCING_SCALE:
			
			# Final sun is launched
			main_tween = create_tween()
			main_tween.tween_property($SunBeam, "scale", Vector2(0.0, 0.0), 0.5).set_trans(Tween.TRANS_ELASTIC)
			main_tween.tween_property($SunBeam, "scale", Vector2(2.0, 2.0), 0.5).set_trans(Tween.TRANS_ELASTIC)
			await main_tween.finished
			
			# Set dmg proportionnaly to the number of gathered suns and the shrinkage from player
			_damage_character()
		else:
			$Furuboule/Body/Sprite2DBeam.hide()
			$Furuboule/Body/Sprite2DBlocked.show()
	else:
		$Furuboule/Body/Sprite2DBlocked.show()

	# Reinit all suns sunbeam
	_init_suns()
	_init_sunbeam()
	
	# Change state
	_play_waiting_animation.call_deferred()


func _attempt_to_hit_sun(sun : Node2D):
	if not suns_state[sun]["state"] == "hitting":
		suns_state[sun]["state"] = "hitting"
		sun.get_node("TextureButtonHitting").show()
		sun.get_node("TextureButtonBlocking").hide()
		sun.get_node("TextureButtonShaking").hide()

func _attempt_to_shake_sun(sun : Node2D):
	if not suns_state[sun]["state"] == "shaking":
		suns_state[sun]["state"] = "shaking"
		sun.get_node("TextureButtonHitting").hide()
		sun.get_node("TextureButtonBlocking").hide()
		sun.get_node("TextureButtonShaking").show()

func _attempt_to_block_sun(sun : Node2D):
	if not suns_state[sun]["state"] == "blocking":
		suns_state[sun]["state"] = "blocking"
		sun.get_node("TextureButtonHitting").hide()
		sun.get_node("TextureButtonBlocking").show()
		sun.get_node("TextureButtonShaking").hide()


func _attempt_to_shake_sunbeam():
	if not sunbeam_state["state"] == "shaking":
		sunbeam_state["state"] = "shaking"
		$SunBeam.get_node("TextureButtonBlocking").hide()
		$SunBeam.get_node("TextureButtonShaking").show()

func _attempt_to_block_sunbeam():
	if not sunbeam_state["state"] == "blocking":
		sunbeam_state["state"] = "blocking"
		$SunBeam.get_node("TextureButtonBlocking").show()
		$SunBeam.get_node("TextureButtonShaking").hide()

func _attempt_to_attack_sunbeam():
	if not sunbeam_state["state"] == "attacking":
		sunbeam_state["state"] = "attacking"


func _sun_hitting_pressed(sun : Node2D):
	_hit(character.damage_per_attack)

func _sun_shaking_pressed(sun : Node2D):
	_reduce_sun(sun)

func _sunbeam_shaking_pressed():
	_reduce_sunbeam()
	
func _sun_blocking_pressed(sun : Node2D):
	pass # TODO: MAYBE DO SOMETHING HERE

func _sunbeam_blocking_pressed():
	pass # TODO: MAYBE DO SOMETHING HERE

func _hit(damage_points : float):
	life_points -= damage_points
	_set_hp_bar(max(life_points,0))
	_attempt_to_play_hit_animation()
	# TODO: DEATH ANIMATION
	if life_points <= 0.0:
		_attempt_to_play_death_animation()

var hp_bar_tween : Tween

func _set_hp_bar(hp):
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)


func _reduce_sun(sun : Node2D):
	suns_state[sun]["rel_energy"] -= SUN_REDUCING_SCALE
	sun.scale = Vector2(suns_state[sun]["rel_energy"], suns_state[sun]["rel_energy"])	
	
	if suns_state[sun]["rel_energy"] < SUN_REDUCING_SCALE:
		sun.scale = Vector2(0.0, 0.0)
		suns_state[sun]["rel_energy"] = 0.0
		sun.hide()

func _reduce_sunbeam():
	sunbeam_state["rel_energy"] -= SUN_REDUCING_SCALE
	$SunBeam.scale = Vector2(sunbeam_state["rel_energy"], sunbeam_state["rel_energy"])	
	
	if sunbeam_state["rel_energy"] < SUN_REDUCING_SCALE:
		$SunBeam.scale = Vector2(0.0, 0.0)
		sunbeam_state["rel_energy"] = 0.0
		$SunBeam.hide()


func _damage_character():
	character.hit(SUNBEAM_DMG * sunbeam_state["rel_energy"])


var hit_tween : Tween

func _attempt_to_play_hit_animation():
	if not hit_tween or not hit_tween.is_running():
		hit_tween = create_tween()
		hit_tween.tween_property($Furuboule/Body, "modulate", Color(1.0, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_property($Furuboule/Body, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)

func _attempt_to_play_death_animation():
	if state != "dying":
		state = "dying"
		if main_tween:
			main_tween.kill()
		main_tween = create_tween()
		main_tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
		just_died.emit()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	pass
