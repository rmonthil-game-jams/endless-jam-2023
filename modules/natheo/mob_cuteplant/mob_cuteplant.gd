extends Node2D

signal just_died


# MOB PARAMETERS
var DIFFICULTY : float = 0.0: set = _set_difficulty

# MOB SUB PARAMETERS

## HANDS GEOMETRY
const PLANTS_REL_DISTANCE = 400.0
const PLANTS_POSSIBLE_ANGLES : Array[float] = [PI, -3.0*PI/4.0, -PI/2.0, -PI/4.0, 0.0]
const PLANTS_ROTATIONS : Array[float] = [-PI/4.0, -PI/8.0, 0.0, PI/8.0, PI/4.0]

## CREATING
var WAITING_ROTATION_DURATION : float
const WAITING_MOVE_DISTANCE : float = 500.0

## REDUCING
const SUN_SHAKING_N : int = 10
var SUN_SHAKING_DURATION : float
const SUN_SHAKING_DISTANCE : float = 10.0
var SUN_REDUCING_SCALE : float
const SUN_REDUCING_MINIMUM : float = 0.3

## ABSORBING
const SUN_ABSORBING_DURATION : float = 0.3
const GATHER_POSITION = Vector2(0.0, 140.0)

## DAMAGE
var DMG_MAX_PER_SUN : float

# MOB PROPERTIES
@onready var mob_hp_progress_bar : TextureProgressBar = $MobHPBar/HBoxContainer/MobHpBar

# MOB STATE
var life_points : float = 40.0
var state : String # useles at the moment but who knows in the future?

# private
func _set_difficulty(value : float):
	DIFFICULTY = value
	
	# Time of one rotation during which we can hit the mob
	WAITING_ROTATION_DURATION = 5.0 / (1.0 + log(1.0 + DIFFICULTY))
	
	# Time of sun shaking during which we can hit the sun to reduce its energy
	SUN_SHAKING_DURATION = 6.0 / (1.0 + 1.5*log(1.0 + DIFFICULTY))
	
	# Decrease of sun relative energy (1 is max, and at SUN_REDUCING_MINIMUM, the sun is destroyed)
	SUN_REDUCING_SCALE = 0.1 # NEED TO DEPEND ON ATTACK
	
	# MAXIMUM DMG OF ONE SUN
	# DMG IS COMPUTED AS THE MAXIMUM DMG OF ONE SUN
	# TIMES THE NUMBER OF SUNS UNDESTROYED
	# TIMES THE SUM RELATIVE ENERGY THAT LEFT ON THE UNDESTROYED SUNS
	# Thus, as we reduce the suns energy, it reduces the final dmgs
	DMG_MAX_PER_SUN = 1.0 * (1.0 + log(1.0 + DIFFICULTY))
	
	life_points = 18 + 3*(1.0 + DIFFICULTY) 
	#print(life_points)



## initialization is unecessary because they are already initialized to these values
var main_tween : Tween = null
var plants : Array[Node] = []
var plants_state : Dictionary = {}
var sunbeam_energy_rel : float = 0.0
var sunbeam_n_suns : int = 0
var character : Node = null

## called when the node enters the scene tree for the first time.
func _ready():
	
	# setup suns
	plants = $Cuteplant/Plants.get_children()
	for plant in plants:
		plant.hide()
		# setup signals
		plant.get_node("Body/TextureButtonGrowth").pressed.connect(_plant_growth_pressed.bind(plant))
		plant.get_node("Body/TextureButtonWait").pressed.connect(_plant_wait_pressed.bind(plant))
		plant.get_node("Sun/TextureButtonAbsorb").pressed.connect(_sun_absorb_pressed.bind(plant))
		plant.get_node("Sun/TextureButtonWait").pressed.connect(_sun_wait_pressed.bind(plant))
	
	character = get_tree().get_nodes_in_group("character").front()
	# avoid using await in the _ready function
	mob_hp_progress_bar.max_value = life_points
	_set_hp_bar()
	
	_play_appearing_animation.call_deferred()


func _init_plants():

	# Initialize the suns
	var plants_posible_angles_left : Array[float] = PLANTS_POSSIBLE_ANGLES.duplicate()
	var plants_rotations_left : Array[float] = PLANTS_ROTATIONS.duplicate()
	for plant in plants:
		
		# setup state and randomize position
		var random_plant_angle_id : int =  randi() % len(plants_posible_angles_left)

		plants_state[plant] = {
			"angle": plants_posible_angles_left[random_plant_angle_id],
			"rotation": plants_rotations_left[random_plant_angle_id],
			"rel_energy": 1.0,
			"state":"init"
		}
		plants_posible_angles_left.pop_at(random_plant_angle_id)
		plants_rotations_left.pop_at(random_plant_angle_id)
		
		# setup sun and plant geometry
		plant.position = Vector2(
			PLANTS_REL_DISTANCE*cos(plants_state[plant]["angle"]),
			PLANTS_REL_DISTANCE*sin(plants_state[plant]["angle"])
		)
		plant.get_node("Sun").position = Vector2(0.0, -125.0) # Relative position
		
		plant.rotation = 0.0
		
		plant.scale = Vector2.ZERO
		plant.get_node("Sun").scale = Vector2.ZERO
		
		plant.show()
		plant.get_node("Sun").show()
		
		# Set as can be hit
		_attempt_to_spawn_plant(plant)
		


func _init_sunbeam():
	# Initialize sunbeam at no energy
	$Beam.scale = Vector2.ZERO
	$Beam.position = GATHER_POSITION
	$FlowerDeco.position = GATHER_POSITION
	$Beam.hide()
	sunbeam_energy_rel = 0.0
	sunbeam_n_suns = 0



func _play_appearing_animation():
	# init
	state = "appearing"
	
#	# animation
	modulate.a = 0.0
	main_tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	main_tween.tween_property($Cuteplant/Body, "modulate", Color(0.5, 0.5, 0.5), 0.5).set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished
	
	_play_waiting_animation.call_deferred()


func _play_waiting_animation():
	state = "waiting"
	
	_init_plants()
	_init_sunbeam()

	main_tween = create_tween()
	for plant in plants:
		main_tween.parallel().tween_property(plant, "scale", 
			Vector2.ONE, 2.0).set_trans(Tween.TRANS_EXPO)
	await main_tween.finished
	
	$Cuteplant/Body/Sprite2DNormal.show()
	$Cuteplant/Body/Sprite2DAttack.hide()
	$Cuteplant/Body/Sprite2DBeam.hide()
	$Cuteplant/Body/Sprite2DHit.hide()
	
	main_tween = create_tween()
	for plant in plants:
		main_tween.parallel().tween_property(plant, "rotation", 
			plants_state[plant]["rotation"], 
			0.3).as_relative().from_current().set_trans(Tween.TRANS_CUBIC)
	await main_tween.finished

	# shuffle randomly the list of suns
	var copy_of_plants : Array[Node] = plants.duplicate()
	copy_of_plants.shuffle()

	# gather suns towards the hands
	for plant in copy_of_plants:

		_attempt_to_growth_plant(plant)

		main_tween = create_tween()
		# Turning randomly around the same center
		# With the associated hands
		var random_rotation = [-1.0, 1.0][randi() % 2] * randf_range(PI, 2*PI)
		main_tween.parallel().tween_property($Cuteplant, "rotation", random_rotation, WAITING_ROTATION_DURATION).as_relative().from_current().set_trans(Tween.TRANS_SINE)
		
		# And moving from left to right while body changing size
		if $Cuteplant.position[0] == 0.0:
			var random_position : float = [-1.0, 1.0][randi() % 2]* WAITING_MOVE_DISTANCE * randf_range(0.8, 1.0)
			main_tween.parallel().tween_property($Cuteplant, "position", Vector2(random_position, 0.0), WAITING_ROTATION_DURATION).set_trans(Tween.TRANS_CUBIC)
			main_tween.parallel().tween_property($Cuteplant/Body, "scale", Vector2(0.8, 0.8), WAITING_ROTATION_DURATION).set_trans(Tween.TRANS_CUBIC)
		else:
			main_tween.parallel().tween_property($Cuteplant, "position", Vector2.ZERO, WAITING_ROTATION_DURATION).set_trans(Tween.TRANS_CUBIC)
			main_tween.parallel().tween_property($Cuteplant/Body, "scale", Vector2.ONE, WAITING_ROTATION_DURATION).set_trans(Tween.TRANS_CUBIC)
		
		# Animation of the plant
		main_tween.parallel().tween_property(plant.get_node("Sun"), "scale", 
			Vector2.ONE, WAITING_ROTATION_DURATION).set_trans(Tween.TRANS_LINEAR)

		await main_tween.finished
		
		_attempt_to_invicible_plant(plant)
	
	_play_preparing_animation.call_deferred()


func _play_preparing_animation():
	state = "preparing"
	
	# Reinitialize rotation
	for plant in plants:
		_attempt_to_invicible_plant(plant)

	main_tween = create_tween()
	main_tween.parallel().tween_property($Cuteplant, "rotation", 0.0, 0.25 * WAITING_ROTATION_DURATION)
	main_tween.parallel().tween_property($Cuteplant/Body, "scale", Vector2.ONE, 0.25 * WAITING_ROTATION_DURATION)
	main_tween.parallel().tween_property($Cuteplant, "position", Vector2.ZERO, 0.25 * WAITING_ROTATION_DURATION)
	await main_tween.finished

	_play_gathering_animation.call_deferred()


func _play_gathering_animation():
	state = "gathering"
	$Cuteplant/Body/Sprite2DNormal.hide()
	$Cuteplant/Body/Sprite2DAttack.show()

	# shuffle randomly the list of suns
	var copy_of_plants : Array[Node] = plants.duplicate()
	copy_of_plants.shuffle()

	# gather suns towards the hands
	for plant in copy_of_plants:

		# Firstly, sun is shaking and player can shrink its energy
		_attempt_to_absorb_sun(plant)

		var shake_move_time : float = SUN_SHAKING_DURATION / (SUN_SHAKING_N*2) #because return trip
		for i in range(SUN_SHAKING_N):
			# Get random position around
			var random_angle : float = randf_range(0, 2*PI)
			var random_vect_add = Vector2(
				SUN_SHAKING_DISTANCE*cos(random_angle),
				SUN_SHAKING_DISTANCE*sin(random_angle)
			)
			# Go to the position and come back
			var initial_pos = plant.get_node("Sun").position
#			
			main_tween = create_tween()
			main_tween.tween_property(plant.get_node("Sun"), "position", random_vect_add, shake_move_time).as_relative().from_current().set_trans(Tween.TRANS_LINEAR)
			main_tween.tween_property(plant.get_node("Sun"), "position", initial_pos, shake_move_time).set_trans(Tween.TRANS_LINEAR)
			await main_tween.finished
			if (plants_state[plant]["rel_energy"] < SUN_REDUCING_MINIMUM):
				main_tween = create_tween()
				_attempt_to_destroy_sun(plant)
				main_tween.tween_property(plant, "position:y", 800.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
				await main_tween.finished
				break

		_attempt_to_wait_sun(plant)

		# Secondly, sun is coming towards the mouse and is absorbed, increasing the final beam
		# Only if the sun has not been totally skrunk
		if (plants_state[plant]["rel_energy"] > 0.0):
			# Sun go to absorbing zone
			main_tween = create_tween()
			
			if plants_state[plant]["rotation"] != 0.0 :
				main_tween.tween_property(plant, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_EXPO)
			
			main_tween.tween_property(plant.get_node("Sun"), "position", 
				GATHER_POSITION - plant.position, 
				SUN_ABSORBING_DURATION).set_trans(Tween.TRANS_EXPO)
			await main_tween.finished

			# Remove Sun
			plant.get_node("Sun").hide()
			_attempt_to_invicible_plant(plant)

			# Increase sunbeam
			sunbeam_energy_rel += plants_state[plant]["rel_energy"]
			sunbeam_n_suns += 1


	_play_releasing_animation.call_deferred()


func _play_releasing_animation():
	state = "releasing"

	# Canalizing energy and we have to try limit dmg
	# Go for launching only if energy has been accumulated
	$Cuteplant/Body/Sprite2DAttack.hide()
	if sunbeam_energy_rel > SUN_REDUCING_SCALE:
		$Cuteplant/Body/Sprite2DBeam.show()

		# Final sun is launched
		$Beam.scale = Vector2.ZERO
		$Beam.modulate.a = 0.0
		$Beam.show()
		$FlowerDeco.scale = Vector2.ZERO
		$FlowerDeco.modulate.a = 0.0
		$FlowerDeco.show()
		
		# Sun and lower are arriving
		main_tween = create_tween()
		main_tween.parallel().tween_property($Beam, "modulate:a", 1.0, 1).set_trans(Tween.TRANS_EXPO)
		main_tween.parallel().tween_property($Beam, "scale", Vector2(2.0, 2.0), 1).set_trans(Tween.TRANS_EXPO)
		main_tween.parallel().tween_property($FlowerDeco, "modulate:a", 1.0, 1).set_trans(Tween.TRANS_ELASTIC)
		main_tween.parallel().tween_property($FlowerDeco, "scale", Vector2.ONE, 1).set_trans(Tween.TRANS_ELASTIC)
		await main_tween.finished
		
		# Flower is dancing
		main_tween = create_tween()
		main_tween.tween_property($FlowerDeco, "rotation",  PI/4.0, 0.08).as_relative().from_current().set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
		for i in range(6):
			main_tween = create_tween()
			if ($FlowerDeco.rotation <= 0.0):
				main_tween.tween_property($FlowerDeco, "rotation",  PI/2.0, 0.08).as_relative().from_current().set_trans(Tween.TRANS_CUBIC)
			else:
				main_tween.tween_property($FlowerDeco, "rotation", -PI/2.0, 0.08).as_relative().from_current().set_trans(Tween.TRANS_CUBIC)
			await main_tween.finished
		main_tween = create_tween()
		main_tween.tween_property($FlowerDeco, "rotation",  0.0, 0.08).set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
		
		# Set dmg proportionnaly to the number of gathered suns and the shrinkage from player
		_damage_character()
		
		# Sun and flower are removed
		main_tween = create_tween()
		main_tween.parallel().tween_property($Beam, "modulate:a", 0.0, 1).set_trans(Tween.TRANS_EXPO)
		main_tween.parallel().tween_property($Beam, "scale", Vector2.ZERO, 1).set_trans(Tween.TRANS_EXPO)
		main_tween.parallel().tween_property($FlowerDeco, "modulate:a", 0.0, 1).set_trans(Tween.TRANS_ELASTIC)
		main_tween.parallel().tween_property($FlowerDeco, "scale", Vector2.ZERO, 1).set_trans(Tween.TRANS_ELASTIC)
		await main_tween.finished
		
		$Beam.hide()
		$FlowerDeco.hide()
		$Cuteplant/Body/Sprite2DBeam.hide()
		$Cuteplant/Body/Sprite2DAttack.show()
		
	else:
		$Cuteplant/Body/Sprite2DHit.show()

	# Change state
	_play_waiting_animation.call_deferred()


func _attempt_to_spawn_plant(plant : Node2D):
	if not plants_state[plant]["state"] == "spawning":
		plants_state[plant]["state"] = "spawning"
		plant.get_node("Body/TextureButtonGrowth").hide()
		plant.get_node("Body/TextureButtonWait").show()
		plant.get_node("Sun/TextureButtonAbsorb").hide()
		plant.get_node("Sun/TextureButtonWait").show()

func _attempt_to_growth_plant(plant : Node2D):
	if not plants_state[plant]["state"] == "growth":
		plants_state[plant]["state"] = "growth"
		plant.get_node("Body/TextureButtonGrowth").show()
		plant.get_node("Body/TextureButtonWait").hide()
		plant.get_node("Sun/TextureButtonAbsorb").hide()
		plant.get_node("Sun/TextureButtonWait").show()
		# REMI: moved fx here
		var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
		target_fx.w = 200.0
		target_fx.h = 200.0
		target_fx.position = Vector2.ZERO # carefull these are local coordinates
		plant.add_child(target_fx)
		

func _attempt_to_invicible_plant(plant : Node2D):
	if not plants_state[plant]["state"] == "invicible":
		plants_state[plant]["state"] = "invicible"
		plant.get_node("Body/TextureButtonGrowth").hide()
		plant.get_node("Body/TextureButtonWait").show()
		plant.get_node("Sun/TextureButtonAbsorb").hide()
		plant.get_node("Sun/TextureButtonWait").show()


func _attempt_to_absorb_sun(plant : Node2D):
	if not plants_state[plant]["state"] == "absorbed":
		plants_state[plant]["state"] = "absorbed"
		plant.get_node("Body/TextureButtonGrowth").hide()
		plant.get_node("Body/TextureButtonWait").show()
		plant.get_node("Sun/TextureButtonAbsorb").show()
		plant.get_node("Sun/TextureButtonWait").hide()
		# REMI: moved fx here
		var target_fx = preload("res://modules/remi/fx/target.tscn").instantiate()
		target_fx.w = 200.0
		target_fx.h = 200.0
		target_fx.position = Vector2.ZERO # carefull these are local coordinates
		plant.get_node("Sun").add_child(target_fx)

func _attempt_to_destroy_sun(plant : Node2D):
	if not plants_state[plant]["state"] == "destroyed":
		plants_state[plant]["state"] = "destroyed"
		plant.get_node("Body/TextureButtonGrowth").hide()
		plant.get_node("Body/TextureButtonWait").show()
		plant.get_node("Sun/TextureButtonAbsorb").hide()
		plant.get_node("Sun/TextureButtonWait").show()
		# add blocked fx
		var blocked_fx = preload("res://modules/remi/fx/blocked.tscn").instantiate()
		blocked_fx.TARGET_SCALE = Vector2(2.0, 2.0)
		blocked_fx.position = plant.transform * plant.get_node("Sun").position
		add_child(blocked_fx)


func _attempt_to_wait_sun(plant : Node2D):
	if not plants_state[plant]["state"] == "waiting":
		plants_state[plant]["state"] = "waiting"
		plant.get_node("Body/TextureButtonGrowth").hide()
		plant.get_node("Body/TextureButtonWait").show()
		plant.get_node("Sun/TextureButtonAbsorb").hide()
		plant.get_node("Sun/TextureButtonWait").show()


func _plant_growth_pressed(plant : Node2D):
	_hit(character.damage_per_attack)

func _plant_wait_pressed(plant : Node2D):
	pass # TODO: MAYBE DO SOMETHING HERE
	
func _sun_absorb_pressed(plant : Node2D):
	_reduce_sun(plant)

func _sun_wait_pressed(plant : Node2D):
	pass # TODO: MAYBE DO SOMETHING HERE
	

func _hit(damage_points : float):
	life_points -= damage_points
	_set_hp_bar()
	_attempt_to_play_hit_animation()
	# TODO: DEATH ANIMATION
	if life_points <= 0.0:
		_attempt_to_play_death_animation()

var hp_bar_tween : Tween

func _set_hp_bar():
	if hp_bar_tween:
		hp_bar_tween.kill()
	hp_bar_tween = get_tree().create_tween()
	hp_bar_tween.tween_property(mob_hp_progress_bar, "value", life_points, 0.25)


func _reduce_sun(plant : Node2D):
	plants_state[plant]["rel_energy"] -= SUN_REDUCING_SCALE
	plant.get_node("Sun").scale = Vector2(plants_state[plant]["rel_energy"], plants_state[plant]["rel_energy"])	

	if plants_state[plant]["rel_energy"] < SUN_REDUCING_MINIMUM:
		plant.get_node("Sun").scale = Vector2(0.0, 0.0)
		plants_state[plant]["rel_energy"] = 0.0
		plant.get_node("Sun").hide()


func _damage_character():
	character.hit(DMG_MAX_PER_SUN * sunbeam_n_suns * sunbeam_energy_rel)


var hit_tween : Tween

func _attempt_to_play_hit_animation():
	if not hit_tween or not hit_tween.is_running():
		hit_tween = create_tween()
		hit_tween.tween_callback($Cuteplant/Body/Sprite2DNormal.hide)
		hit_tween.tween_callback($Cuteplant/Body/Sprite2DAttack.hide)
		hit_tween.tween_callback($Cuteplant/Body/Sprite2DBeam.hide)
		hit_tween.tween_callback($Cuteplant/Body/Sprite2DHit.show)
		hit_tween.tween_property($Cuteplant/Body, "modulate", Color(1.0, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_property($Cuteplant/Body, "modulate", Color(0.5, 0.5, 0.5), 0.125).set_trans(Tween.TRANS_CUBIC)
		hit_tween.tween_callback($Cuteplant/Body/Sprite2DNormal.show)
		hit_tween.tween_callback($Cuteplant/Body/Sprite2DHit.hide)

func _attempt_to_play_death_animation():
	if state != "dying":
		state = "dying"
		if main_tween:
			main_tween.kill()
		if hit_tween:
			hit_tween.kill()
			hit_tween = create_tween()
			hit_tween.tween_property($Cuteplant/Body, "modulate", Color(1.0, 1.0, 1.0), 0.125).set_trans(Tween.TRANS_CUBIC)
			await hit_tween.finished
		$Cuteplant/Body/Sprite2DNormal.hide()
		$Cuteplant/Body/Sprite2DAttack.hide()
		$Cuteplant/Body/Sprite2DBeam.hide()
		$Cuteplant/Body/Sprite2DHit.show()
		main_tween = create_tween()
		main_tween.tween_property($Cuteplant, "rotation", 0.0, 0.5)
		for plant in plants:
			main_tween.tween_property(plant, "position:y", 800.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await main_tween.finished
		main_tween = create_tween()
		main_tween.parallel().tween_property($Cuteplant/Body, "rotation", 6.0*2.0*PI, 2.0).as_relative().from_current()
		main_tween.parallel().tween_property($Cuteplant/Body, "scale", Vector2.ZERO, 2.0)
		main_tween.parallel().tween_property(self, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_CUBIC)
		await main_tween.finished
		just_died.emit()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta : float):
	$MobHPBar.position = $Cuteplant.position + Vector2.UP * 325.0
