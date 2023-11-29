extends Node2D

@export var POINTER_ANGULAR_SPEED : float = 0.4
@export var POINTER_DISTANCE_RADIUS : float = 100
@export var POINTER_CLICK_PERIOD : float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	phase = randf()
	$Timer.wait_time = POINTER_CLICK_PERIOD
	$Timer.autostart = true
	$Timer.start()
	
	


var phase : float
var offset : Vector2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	phase += delta*POINTER_ANGULAR_SPEED
	offset = Vector2(sin(phase), cos(phase))*POINTER_DISTANCE_RADIUS
	global_position = get_viewport().get_mouse_position()*2-get_viewport_rect().size + offset

func _on_timer_timeout():
	call_deferred("_click")

func _click():
	var event = InputEventMouseButton.new()
	event.position = global_position
	event.set_pressed(true)
	event.set_button_index(0)
	Input.parse_input_event(event)
#	event.pressed = false
#	Input.parse_input_event(event)
