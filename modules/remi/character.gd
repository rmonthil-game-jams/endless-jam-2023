extends Node2D

# public

signal just_died

func hit(damage_points : float):
	life_points -= damage_points
	_set_hpbar_level(life_points)
	_hit_label_animation.call_deferred(damage_points)
	_hit_color_rect_animation.call_deferred() # also checks for character death
	

func heal(heal_points : float):
	life_points = min(life_points + heal_points, max_life_points)
	_set_hpbar_level(life_points)
	_heal_label_animation.call_deferred(heal_points)
	_heal_color_rect_animation.call_deferred()

# private

## state
var max_life_points : float = 10.0
var life_points : float = 10.0
var damage_per_attack : float = 1.0

signal set_maxhp (max_hp : float)
func _ready():
	_set_hpbar_max(max_life_points)
	_set_hpbar_level(max_life_points)

	# TODO: WHEN CURSOR SHAPES ARE DONE
	# Input.set_custom_mouse_cursor(preload("res://path/to/cursor.(svg|png|etc...)"))
	# Input.set_custom_mouse_cursor(preload("res://path/to/cursor.(svg|png|etc...)"))
	# ...

@onready var label_hit : Label = $CanvasLayer/LabelHit
var tween_label_hit : Tween
@onready var label_hit_initial_position_y : float = label_hit.position.y

func _hit_label_animation(damage_points : float):
	# init
	label_hit.position.y = label_hit_initial_position_y
	label_hit.modulate.a = 1.0
	label_hit.text = "- " + str(damage_points)
	label_hit.show()
	# anim
	if tween_label_hit != null:
		tween_label_hit.kill()
	tween_label_hit = create_tween()
	tween_label_hit.tween_property(label_hit, "position:y", label_hit_initial_position_y - 20.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_label_hit.parallel().tween_property(label_hit, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_label_hit.tween_callback(label_hit.hide)

@onready var color_rect_hit : ColorRect = $CanvasLayer/ColorRectHit
var tween_color_rect_hit : Tween

func _hit_color_rect_animation():
	# init
	color_rect_hit.color.a = 0.0
	color_rect_hit.show()
	# anim
	if tween_color_rect_hit != null:
		tween_color_rect_hit.kill()
	tween_color_rect_hit = create_tween()
	tween_color_rect_hit.tween_property(color_rect_hit, "color:a", 0.5, .125).set_trans(Tween.TRANS_CUBIC)
	tween_color_rect_hit.tween_property(color_rect_hit, "color:a", 0.0, .125).set_trans(Tween.TRANS_CUBIC)
	tween_color_rect_hit.set_loops(4)
	tween_color_rect_hit.tween_callback(color_rect_hit.hide)
	tween_color_rect_hit.tween_callback(_attempt_dying)

func _attempt_dying():
	if life_points <= 0:
		# init
		color_rect_hit.color.a = 0.0
		color_rect_hit.show()
		# anim
		if tween_color_rect_hit != null:
			tween_color_rect_hit.kill()
		tween_color_rect_hit = create_tween()
		tween_color_rect_hit.tween_property(color_rect_hit, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC)
		await tween_color_rect_hit.finished
		# signal
		just_died.emit()

@onready var label_heal : Label = $CanvasLayer/LabelHeal
var tween_label_heal : Tween
@onready var label_heal_initial_position_y : float = label_heal.position.y

func _heal_label_animation(heal_points : float):
	# init
	label_heal.position.y = label_heal_initial_position_y
	label_heal.modulate.a = 1.0
	label_heal.text = "+ " + str(heal_points)
	label_heal.show()
	# anim
	if tween_label_hit != null:
		tween_label_hit.kill()
	tween_label_hit = create_tween()
	tween_label_hit.tween_property(label_heal, "position:y", label_heal_initial_position_y - 20.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween_label_hit.parallel().tween_property(label_heal, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween_label_hit.tween_callback(label_heal.hide)

@onready var color_rect_heal : ColorRect = $CanvasLayer/ColorRectHit
var tween_color_rect_heal : Tween

func _heal_color_rect_animation():
	# init
	color_rect_heal.color.a = 0.0
	color_rect_heal.show()
	# anim
	if tween_color_rect_heal != null:
		tween_color_rect_heal.kill()
	tween_color_rect_heal = create_tween()
	tween_color_rect_heal.tween_property(color_rect_heal, "color:a", 0.5, .125).set_trans(Tween.TRANS_CUBIC)
	tween_color_rect_heal.tween_property(color_rect_heal, "color:a", 0.0, .125).set_trans(Tween.TRANS_CUBIC)
	tween_color_rect_heal.set_loops(4)
	tween_color_rect_heal.tween_callback(color_rect_heal.hide)
	tween_color_rect_heal.tween_callback(_attempt_dying)

const PX_PER_HP : int = 50
const HEALTH_TRANS_TIME : float = 0.25

var max_hp_tween : Tween

@onready var character_hp_bar : TextureProgressBar = $CanvasLayer/HP_hud/HPBar/CharacterHPBar

func _set_hpbar_max(max_hp : int):
	character_hp_bar.custom_minimum_size = Vector2(max_hp * PX_PER_HP, character_hp_bar.custom_minimum_size.y)
	if max_hp_tween:
		max_hp_tween.kill()
	max_hp_tween = get_tree().create_tween()
	max_hp_tween.tween_property(character_hp_bar, "max_value", max_hp, HEALTH_TRANS_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

var hp_tween : Tween

func _set_hpbar_level(hp):
	if hp_tween:
		hp_tween.kill()
	hp_tween = get_tree().create_tween()
	hp_tween.tween_property(character_hp_bar, "value", hp, HEALTH_TRANS_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# TODO: SLIGHT CAMERA SHAKE
	
