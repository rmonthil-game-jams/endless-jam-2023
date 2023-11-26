extends AudioStreamPlayer2D

# Ideally put this in Character, st. everyone has it

func _ready():
	max_polyphony = 5 # Several clicks = several sounds
	attenuation = 0 # Do not fade sound out : it can be really weird otherwise
	pass # Replace with function body.


func _unhandled_input(event):
	# On release click
	if event is InputEventMouseButton and not event.pressed:
		# Recenter position on the camera viewport st. it is in [-viewport/2, viewport/2] coordinates
		# (position [0, 0] is a centered sound)
		# Useless now that I removed fading
		position = get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2
		play()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
