extends Node

var difficulty : int
@export var dungeon : PackedScene

var state : String

var node_dungeon : Node2D = null
@onready var node_settings : Control = $CanvasLayer/Settings
@onready var node_start : Control = $CanvasLayer/Start
@onready var node_black : Control = $CanvasLayer/Black

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_custom_mouse_cursor(preload("res://modules/remi/assets/graphics/cursor.png"))
	_on_easy_button_down()
	state = "main menu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	# init anim
	$CanvasLayer/Start.modulate.a = 0.0
	$CanvasLayer/Settings.modulate.a = 0.0
	$Overlay/Control.modulate.a = 0.0
	
	BackgroundMusic.play_menu.call_deferred()
	
	# play anim
	_play_appear_animation.call_deferred()

func _play_appear_animation():
	# tween
	var tween = create_tween()
	tween.tween_property($CanvasLayer/Start, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($CanvasLayer/Settings, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property($Overlay/Control, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var next_state = state
	
	if Input.is_action_just_released("ui_cancel") && state == "game":
		get_tree().paused = true
		node_black.show()
		node_settings.show()
		next_state = "pause"
	
	if Input.is_action_just_released("ui_cancel") && state == "pause":
		get_tree().paused = false
		node_black.hide()
		node_settings.hide()
		next_state = "game"
	
	
	state = next_state

@onready var easy_button : TextureButton = $CanvasLayer/Settings/Difficulty/HBoxContainer/Easy
@onready var medium_button : TextureButton = $CanvasLayer/Settings/Difficulty/HBoxContainer/Medium
@onready var hard_button : TextureButton = $CanvasLayer/Settings/Difficulty/HBoxContainer/Hard

func _on_easy_button_down():
	difficulty = 1
	easy_button.disabled = true
	medium_button.disabled = false
	hard_button.disabled = false


func _on_medium_button_down():
	difficulty = 2
	easy_button.disabled = false
	medium_button.disabled = true
	hard_button.disabled = false


func _on_hard_button_down():
	difficulty = 3
	easy_button.disabled = false
	medium_button.disabled = false
	hard_button.disabled = true


func _on_texture_button_button_up():
	$CanvasLayer/Start/StartButton.disabled = true
	var tween : Tween = create_tween()
	# hide settings
	tween.tween_property(node_settings, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# zoom in
	tween.parallel().tween_property(node_start, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node_start, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(node_settings.hide)
	tween.tween_callback(node_start.hide)
	await  tween.finished
	node_settings.modulate.a = 1.0
	# instance dungeon
	state = "game"
	node_dungeon = dungeon.instantiate()
	node_dungeon.difficulty = difficulty
	node_dungeon.name = "Dungeon"
	node_dungeon.process_mode=Node.PROCESS_MODE_PAUSABLE
	$DungeonContainer.add_child(node_dungeon)
	node_dungeon._game_over.connect(_on_game_over)
	node_dungeon.z_index = -1
	# dungeon appear anim
	tween = create_tween()
	node_dungeon.modulate.a = 0.0
	tween.tween_property(node_dungeon, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)

func _on_game_over():
	BackgroundMusic.play_menu()
	var tween : Tween = create_tween()
	$CanvasLayer/Go/RoomReached.text = "ROOM REACHED: " + str(max(0,node_dungeon.room))
	state = "game over"
	# free dungeon
	node_dungeon.queue_free()
	# show settings
	node_settings.modulate.a = 0.0
	node_settings.show()
	tween.tween_property(node_settings, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
	# zoom in
	node_start.show()
	tween.parallel().tween_property(node_start, "scale", Vector2(0.5, 0.5), 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(node_start, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	# test
	await tween.finished
	
	$CanvasLayer/Go.show()

func _on_exit_button_up():
	get_tree().free()

func _on_retry_button_up():
	state = "main menu"
	$CanvasLayer/Go.hide()
	$CanvasLayer/Start/StartButton.disabled = false


func _input(event):
	if event is InputEventMouseButton && event.button_index == MouseButton.MOUSE_BUTTON_LEFT && event.is_pressed():
		$Audio/GeneralClick.play.bind(0.05).call_deferred()


func _on_credits_pressed():
	get_tree().change_scene_to_file("res://modules/remi/credits.tscn")
