extends Node2D

signal just_died

@export var mob_scene : PackedScene

# This controls the overall fight difficulty.
# It may add mobs, inscrease their speed, etc.
@export var DIFFICULTY : float = 0: set = set_difficulty

### Sub variables
var NB_MOBS : int
var PER_MOB_DIFFICULTY : float

var alive_mobs : int
var total_health : float

func set_difficulty(d : float):
	DIFFICULTY = d
	NB_MOBS = 1 + DIFFICULTY/2
	PER_MOB_DIFFICULTY = fmod(DIFFICULTY, 2) / 2 # This sets the mobs difficulty in [0,1[. Probably better to just do DIFFICULTY/nb_mobs

var SpawnSlots : Array[Vector2]

# Called when the node enters the scene tree for the first time.
func _ready():
	set_difficulty(DIFFICULTY) # Force call of set_difficulty
	# Max spawn slots is : 4
	for i in [0, 0.33, 0.66, 1]:
		# Add a small scramble to this spot
		var Spot : Vector2 = _get_spot(i) + Vector2(randf_range(-100, 100), randf_range(-40, 200))
		SpawnSlots.append(Spot)
	
	SpawnSlots.shuffle()
	_spawn_mobs()

func _get_hud_min_offset():
	return Vector2(300, 200)
	
func _get_hud_max_offset():
	return Vector2(300, 200)

# Scale factor induced by camera
func get_viewport_size():
	return get_viewport().get_visible_rect().size * 2

func _get_spot(i : float):
	var screen_size = get_viewport_size()
	
	var pmin : Vector2 = -screen_size / 2 + _get_hud_min_offset() + Vector2(150, 200)
	var pmax : Vector2 = screen_size / 2 - _get_hud_max_offset() - Vector2(100, 0) # Not too close from border (HP bar should be visible at start)
	var size : Vector2 = pmax - pmin
	
	return pmin + Vector2(i * size.x, 0.5 * size.y)
	


func _spawn_mobs():
	total_health = 0;
	
	for i in range(min(NB_MOBS, SpawnSlots.size())):
		var new_mob : Node2D = mob_scene.instantiate()
		new_mob.set_difficulty(PER_MOB_DIFFICULTY)
		new_mob.position = SpawnSlots[i]
		total_health += new_mob.life_points
		
		new_mob.just_died.connect(_on_mob_died.bind(new_mob))
		
		$Mobs.add_child(new_mob)
	
	alive_mobs = NB_MOBS


func _on_mob_take_damage():
	pass

func _on_mob_died(mob : Node2D):
	alive_mobs -= 1
	mob.queue_free() # probably not that usefull
	if alive_mobs <= 0:
		just_died.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
