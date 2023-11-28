extends Node

var MENU_DB : float = -25
var UPGRADE_DB : float = -20
var COMBAT_DB : float = -15
var CLIC_CLIC_DB : float = COMBAT_DB

var OFF_DB = -80

var INTRO_END : AudioStream = preload("res://modules/hugo/assets/audio/1.intro.wav")
var DROP_SLICE : AudioStream = preload("res://modules/hugo/assets/audio/2.dropslice.wav")
var SLICE_COMBAT : AudioStream = preload("res://modules/hugo/assets/audio/3.combatslice.wav")
var COMBAT : AudioStream = preload("res://modules/hugo/assets/audio/4.combat.wav")

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_volume(MENU_DB)
	
	# For testing
	# play_menu.call_deferred()

func _set_volume(volume : float):
	$Internals/CurrentTrack.volume_db = volume

var interruptible_tween : Tween

func smooth_fade_to(new_stream : AudioStream, new_db : float):
	# Already fading out to another track. Maybe we want to force the new music anyway though
	if $Internals/PrevTrack.playing:
		brutal_fade_to(new_stream, new_db, $Internals/PrevTrack.get_playback_position())
		return
		
	if interruptible_tween != null and interruptible_tween.is_running():
		await interruptible_tween.finished # Easier to do, but probably wrong in extreme scenarios
	
	var current_db : float = $Internals/CurrentTrack.volume_db
	
	var current_pos : float = 0
	$Internals/PrevTrack.stream = $Internals/CurrentTrack.stream
	if $Internals/CurrentTrack.playing:
		current_pos = $Internals/CurrentTrack.get_playback_position()
		$Internals/PrevTrack.play(current_pos)
	
	var anim : Animation = $Internals/FadeAnimation.get_animation("Fade")
	anim.track_set_key_value(0, 0, current_db)
	anim.track_set_key_value(1, 1, new_db)
	$Internals/CurrentTrack.stream = new_stream
	$Internals/CurrentTrack.play(current_pos)
	$Internals/FadeAnimation.play("Fade")

func brutal_fade_to(new_stream : AudioStream, new_db : float, position : float):
	# May wake up some coroutines waiting on finished
	$Internals/PrevTrack.stop()
	$Internals/CurrentTrack.stop()
	
	$Internals/CurrentTrack.stream = new_stream
	_set_volume(new_db)
	$Internals/CurrentTrack.play(position)


func play_menu():
	smooth_fade_to(INTRO_END, MENU_DB)


func play_combat(click_delay : float):
	# First switch to CLIC CLICK after the given delay (Maybe we always want it to land on a given tempo ?)
	interruptible_tween = create_tween()
	await interruptible_tween.tween_interval(click_delay).finished
	brutal_fade_to(DROP_SLICE, CLIC_CLIC_DB, 0)
	
	# Wait the end of the player (May be waked by something else, though shouldn't happen here)
	await $Internals/CurrentTrack.finished
	if $Internals/CurrentTrack.stream != DROP_SLICE:
		return
	
	# Then play combat with cling at start 
	brutal_fade_to(SLICE_COMBAT, COMBAT_DB, 0)
	interruptible_tween = create_tween()
	await interruptible_tween.tween_interval(1).finished # Wait the cling to finish and continue on the classic combat loop
	smooth_fade_to(COMBAT, COMBAT_DB)


func play_upgrade_menu():
	smooth_fade_to(INTRO_END, UPGRADE_DB)

