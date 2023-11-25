extends Control

var difficulty : int
@export var dungeon : PackedScene

var state : String

# Called when the node enters the scene tree for the first time.
func _ready():
	difficulty = 1
	state = "main menu"
	process_mode = Node.PROCESS_MODE_ALWAYS

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var next_state = state
	
	if Input.is_action_just_released("ui_cancel") && state == "game":
		get_tree().paused = true
		$Settings.show()
		next_state = "pause"
	
	
	if Input.is_action_just_released("ui_cancel") && state == "pause":
		get_tree().paused = false
		$Settings.hide()
		next_state = "game"
	
	
	state = next_state




func _on_easy_button_down():
	difficulty = 1


func _on_medium_button_down():
	difficulty = 2


func _on_hard_button_down():
	difficulty = 3


func _on_texture_button_button_up():
	$StartButton.hide()
	$Settings.hide()
	state = "game"
	var new_dungeon = dungeon.instantiate()
	new_dungeon.difficulty = difficulty
	new_dungeon.name = "dungeon"
	new_dungeon.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(new_dungeon)
	$dungeon._game_over.connect(_on_game_over)
	$dungeon.z_index = -1
	$dungeon.position = get_viewport_rect().size / 2

func _on_game_over():
	$dungeon.queue_free()
	state = "main menu"
	$StartButton.show()
	$Settings.show()

func _on_exit_button_up():
	get_tree().free()
