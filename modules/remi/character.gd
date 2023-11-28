extends Node2D

# public

signal just_died

var upgrades : Dictionary = {
	"HP1" : {
				"name" : "Health Bonus",
				"hover" : "res://modules/remi/assets/graphics/up_health_1_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_health_1_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_health_1_pressed.svg",
				"tooltip" : "Increases total health by a small amount",
				"weight" : 1,
				"type" : "HP UP",
				"tier" : 1,
				"max_life_points" : 4,
			},
	"HP2" : {
				"name" : "Health Bonus +",
				"hover" : "res://modules/remi/assets/graphics/up_health_2_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_health_2_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_health_2_pressed.svg",
				"tooltip" : "Increases total health by a significant amount",
				"weight" : 1,
				"type" : "HP UP",
				"tier" : 2,
				"max_life_points" : 8,
			},
	"HP3" : {
				"name" : "Health Bonus ++",
				"hover" : "res://modules/remi/assets/graphics/up_health_3_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_health_3_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_health_3_pressed.svg",
				"tooltip" : "Increases total health by a large amount",
				"weight" : 1,
				"type" : "HP UP",
				"tier" : 3,
				"max_life_points" : 12,
			},
	"HPR1" : {
				"name" : "Health Regen Bonus",
				"hover" : "res://modules/remi/assets/graphics/up_vitality_1_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_vitality_1_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_vitality_1_pressed.svg",
				"tooltip" : "Increases health generation after each fight by a small amount",
				"weight" : 1,
				"type" : "HP R UP",
				"tier" : 1,
				"hp_regen" : 1,
			},
	"HPR2" : {
				"name" : "Health Regen Bonus +",
				"hover" : "res://modules/remi/assets/graphics/up_vitality_2_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_vitality_2_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_vitality_2_pressed.svg",
				"tooltip" : "Increases health generation after each fight by a small amount",
				"weight" : 1,
				"type" : "HP R UP",
				"tier" : 2,
				"hp_regen" : 2,
			},
	"HPR3" : {
				"name" : "Health Regen Bonus ++",
				"hover" : "res://modules/remi/assets/graphics/up_vitality_3_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_vitality_3_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_vitality_3_pressed.svg",
				"tooltip" : "Increases health generation after each fight by a small amount",
				"weight" : 1,
				"type" : "HP R UP",
				"tier" : 3,
				"hp_regen" : 4,
			},
	"DMG1" : {
				"name" : "Damage per Click",
				"hover" : "res://modules/remi/assets/graphics/up_strength_1_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_strength_1_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_strength_1_pressed.svg",
				"tooltip" : "Increases damage inflicted by a small amount",
				"weight" : 1,
				"type" : "DMG UP",
				"tier" : 1,
				"damage_per_attack" : 0.5,
			},
	"DMG2" : {
				"name" : "Damage per Click +",
				"hover" : "res://modules/remi/assets/graphics/up_strength_2_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_strength_2_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_strength_2_pressed.svg",
				"tooltip" : "Increases damage inflicted by a significant amount",
				"weight" : 1,
				"type" : "DMG UP",
				"tier" : 2,
				"damage_per_attack" : 0.8,
			},
	"DMG3" : {
				"name" : "Damage per Click ++",
				"hover" : "res://modules/remi/assets/graphics/up_strength_3_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_strength_3_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_strength_3_pressed.svg",
				"tooltip" : "Increases damage inflicted by a large amount",
				"weight" : 1,
				"type" : "DMG UP",
				"tier" : 3,
				"damage_per_attack" : 1.8,
			},
	"HEAL1" : {
				"name" : "Healing potion",
				"hover" : "res://modules/remi/assets/graphics/up_heal_1_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_heal_1_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_heal_1_pressed.svg",
				"tooltip" : "Regenerates your health by a small amount",
				"weight" : 1,
				"type" : "HEAL",
				"tier" : 1,
				"life_points" : 50,
			},
	"HEAL2" : {
				"name" : "Healing potion +",
				"hover" : "res://modules/remi/assets/graphics/up_heal_2_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_heal_2_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_heal_2_pressed.svg",
				"tooltip" : "Regenerates your health by a significant amount",
				"weight" : 1,
				"type" : "HEAL",
				"tier" : 2,
				"life_points" : 100,
			},
	"HEAL3" : {
				"name" : "Healing potion ++",
				"hover" : "res://modules/remi/assets/graphics/up_heal_3_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_heal_3_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_heal_3_pressed.svg",
				"tooltip" : "Regenerates your health by a large amount",
				"weight" : 1,
				"type" : "HEAL",
				"tier" : 3,
				"life_points" : 200,
			},
	"BSK2" : {
				"name" : "Berserk +",
				"hover" : "res://modules/remi/assets/graphics/up_steroid_2_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_steroid_2_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_steroid_2_pressed.svg",
				"tooltip" : "Increases damage at the cost of maximum health by a significant amount",
				"weight" : 0.5,
				"type" : "BSK",
				"tier" : 2,
				"max_life_points" : -8,
				"damage_per_attack" : 1.2,
			},
	"BSK3" : {
				"name" : "Berserk ++",
				"hover" : "res://modules/remi/assets/graphics/up_steroid_3_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_steroid_3_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_steroid_3_pressed.svg",
				"tooltip" : "Increases damage at the cost of maximum health by a large amount",
				"weight" : 0.5,
				"type" : "BSK",
				"tier" : 3,
				"max_life_points" : -15,
				"damage_per_attack" : 2,
			},
	"MORE" : {
				"name" : "More Upgrade Options",
				"hover" : "res://modules/remi/assets/graphics/up_choice_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_choice_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_choice_pressed.svg",
				"tooltip" : "Increases the number of upgrades to chose from after each fight by one (max. 6)",
				"weight" : 0.5,
				"type" : "OPTIONS",
				"tier" : 2,
				"upgrade_options" : 1,
			},
	"BETTER1" : {
				"name" : "Better Upgrade Options",
				"hover" : "res://modules/remi/assets/graphics/up_update_1_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_update_1_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_update_1_pressed.svg",
				"tooltip" : "Improves the quality of the upgrades by a small amount",
				"weight" : 2,
				"type" : "BETTER",
				"tier" : 1,
				"upgrade_level" : 0.2,
			},
	"BETTER2" : {
				"name" : "Better Upgrade Options",
				"hover" : "res://modules/remi/assets/graphics/up_update_2_hover.svg",
				"normal" : "res://modules/remi/assets/graphics/up_update_2_normal.svg",
				"pressed" : "res://modules/remi/assets/graphics/up_update_2_pressed.svg",
				"tooltip" : "Improves the quality of the upgrades by a large amount",
				"weight" : 2,
				"type" : "BETTER",
				"tier" : 2,
				"upgrade_level" : 0.5,
			},
#	"EXTRA1" : {
#				"name" : "Add Companion",
#				"icon" : "res://modules/remi/assets/graphics/hud_life_bar_progress.svg",
#				"tooltip" : "Adds a new pointer helping you periodically",
#				"weight" : 100,
#				"type" : "EXTRA",
#				"tier" : 1,
#				"add_pointer" : 1,
#			},
}

signal finished_upgrade

func _apply_up(upgrade : Dictionary):
	for key in upgrade:
		match key:
			
			"max_life_points" : 
				max_life_points += upgrade["max_life_points"]
				_set_hpbar_max(max_life_points)
				if upgrade["max_life_points"]>= 0:
					heal(upgrade["max_life_points"])
				else:
					hit(-upgrade["max_life_points"])
				
			"damage_per_attack" :
				damage_per_attack += upgrade["damage_per_attack"]
				$CanvasLayer/Control/Damage/CenterContainer/DamageProgressBar.value = damage_per_attack
			"life_points" :
				heal(upgrade["life_points"])
				
			"upgrade_options" :
				if upgrade_options < 6:
					upgrade_options += upgrade["upgrade_options"]
				
			"upgrade_level":
				upgrade_level += upgrade["upgrade_level"]
				$CanvasLayer/Control/Update/CenterContainer/UpdateProgressBar.value = upgrade_level
			"hp_regen" : 
				hp_regen += upgrade["hp_regen"]
				$CanvasLayer/Control/Vitality/CenterContainer/RegenProgressBar.value = hp_regen
			"add_pointer":
				_add_pointer()
	
	$CanvasLayer/UpgradeMenu.hide()
	for upgrade_button in $CanvasLayer/UpgradeMenu/HBoxContainer.get_children():
		upgrade_button.queue_free()
	$CanvasLayer/Control/Room/MarginContainer/Number.text = str(cur_room + 1)
	finished_upgrade.emit()
	
@export var POINTER_NODE : PackedScene
@export var MAX_POINTERS : int = 3
var npointers : int = 0
func _add_pointer():
	if npointers < MAX_POINTERS:
		var new_pointer = POINTER_NODE.instantiate()
		$Pointers.add_child(new_pointer)

var upgrade_level : float = 0
var upgrade_options : int = 3
var cur_room : int = 1
func _loot(lootbuff : float, room : float):
	
	if hp_regen > 0.0:
		heal(hp_regen)
	
	# start anim
	var tween : Tween = create_tween()
	# init
	$CanvasLayer/UpgradeMenu.modulate.a = 0.0
	$CanvasLayer/UpgradeMenu.show()
	# tween
	tween.tween_property($CanvasLayer/UpgradeMenu, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	cur_room = room
	_generate_upgrades(lootbuff)
	


func _generate_upgrades(lootbuff : float):
	var all_unused_upgrades = upgrades.duplicate(true)
	for up_option in range(upgrade_options):
		var upgrade_tier = _chose_upgrade_tier(lootbuff)
		var available_upgrades : Array
		
		var cum_prob : Array[float]
		var tot_weights : float = 0.0
		for upgrade in all_unused_upgrades:
			if all_unused_upgrades[upgrade]["tier"] == upgrade_tier:
				available_upgrades.append(all_unused_upgrades[upgrade])
				tot_weights += all_unused_upgrades[upgrade]["weight"]
				cum_prob.append(tot_weights)
		
		var selected_up
		var roll = randf_range(0, tot_weights)
		for i in range(available_upgrades.size()):
			if roll<cum_prob[i]:
				selected_up = available_upgrades[i]
				break
		
		all_unused_upgrades.erase(all_unused_upgrades.find_key(selected_up))
		
		var upgrade_button = TextureButton.new()
		upgrade_button.name = selected_up["name"]
		upgrade_button.pressed.connect(_apply_up.bind(selected_up))
		upgrade_button.texture_normal = load(selected_up["normal"])
		upgrade_button.texture_pressed = load(selected_up["pressed"])
		upgrade_button.texture_hover = load(selected_up["hover"])
		upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		upgrade_button.tooltip_text = selected_up["tooltip"]
		upgrade_button.ignore_texture_size = true
		upgrade_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		upgrade_button.custom_minimum_size = Vector2(200,200)
		var mat : Material
		match selected_up["tier"]:
			1: 
				mat = $ShaderCache/normal_mat_cached.material
			2: 
				mat = $ShaderCache/rare_mat_cached.material
			3:
				mat = $ShaderCache/epic_mat_cached.material
		upgrade_button.material = mat
		$CanvasLayer/UpgradeMenu/HBoxContainer.add_child(upgrade_button)
		# quick anim
		var tween : Tween = create_tween()
		# init
		upgrade_button.modulate.a = 0.0
		# tween
		tween.tween_property(upgrade_button, "modulate:a", 1.0, 0.125).set_trans(Tween.TRANS_CUBIC)
		await tween.finished


@export var TIER_SELECTIVITY : float = 0.6
@export var MAXTIER : int = 3

func _chose_upgrade_tier(lootbuff : float):
	var tiers_prob : Array
	var prob_tot : float = 0.0
	for tier in range(MAXTIER):
		tiers_prob.append(1/(TIER_SELECTIVITY*sqrt(2*PI))*exp(-1.0/2.0*pow((upgrade_level+lootbuff-tier)/TIER_SELECTIVITY,2.0)))
		prob_tot += tiers_prob[tier]
		
	for tier in range(MAXTIER):
		tiers_prob[tier] /= prob_tot
		
	var cumprobs : Array
	var part_cum : float = 0.0
	for tier in range(MAXTIER):
		cumprobs.append(part_cum+tiers_prob[tier])
		part_cum += tiers_prob[tier]
	var roll = randf()
	for tier in range(MAXTIER):
		if roll<=cumprobs[tier]:
			return tier+1
	return -1

func hit(damage_points : float):
	if not state == "dying":
		life_points -= damage_points
		_set_hpbar_level(life_points)
		$Audio/Hit.play.call_deferred()
		# label fx
		var label_fx = preload("res://modules/remi/fx/label.tscn").instantiate()
		label_fx.position = Vector2(get_viewport_rect().size.x/2.0, get_viewport_rect().size.y - 20.0) # carefull these are local coordinates
		label_fx.COLOR = Color(1.0, 0.6, 0.6)
		label_fx.TEXT = "- " + str(snapped(life_points, 0.1))
		$CanvasLayerOverlay.add_child(label_fx)
		# cam shake
		$Camera2D.shake.call_deferred(0.2, 15, 24)
		# hit anim
		_hit_animation.call_deferred() # also checks for character death

func heal(heal_points : float):
	life_points = min(life_points + heal_points, max_life_points)
	_set_hpbar_level(life_points)
	$Audio/Heal.play.call_deferred()
	# label fx
	var label_fx = preload("res://modules/remi/fx/label.tscn").instantiate()
	label_fx.position = Vector2(get_viewport_rect().size.x/2.0, get_viewport_rect().size.y - 20.0) # carefull these are local coordinates
	label_fx.COLOR = Color(0.6, 1.0, 0.6)
	label_fx.TEXT = "+ " + str(snapped(heal_points, 0.1))
	$CanvasLayerOverlay.add_child(label_fx)
	# heal anim
	_heal_animation.call_deferred()

# private

## state
var max_life_points : float = 10.0
var life_points : float = 10.0
var hp_regen : float = 0.0
var damage_per_attack : float = 1.0
var state : String = ""

signal set_maxhp (max_hp : float)
func _ready():
	_set_hpbar_max(max_life_points)
	_set_hpbar_level(max_life_points)
	$CanvasLayer/Control/Vitality/CenterContainer/RegenProgressBar.value = hp_regen
	$CanvasLayer/Control/Damage/CenterContainer/DamageProgressBar.value = damage_per_attack
	$CanvasLayer/Control/Update/CenterContainer/UpdateProgressBar.value = upgrade_level
	# TODO: WHEN CURSOR SHAPES ARE DONE
	# Input.set_custom_mouse_cursor(preload("res://path/to/cursor.(svg|png|etc...)"))
	# Input.set_custom_mouse_cursor(preload("res://path/to/cursor.(svg|png|etc...)"))
	_play_appear_animation.call_deferred()

func _play_appear_animation():
	$CanvasLayer/Control.modulate.a = 0.0
	var tween : Tween = create_tween()
	tween.tween_property($CanvasLayer/Control, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_ELASTIC)
	await tween.finished

var tween_hit : Tween
@onready var shader_material : ShaderMaterial = $CanvasLayer/Control/HP_hud/AstronautAnchor/HudAstronaut.material
@onready var astronaut : Node2D = $CanvasLayer/Control/HP_hud/AstronautAnchor

func _hit_animation():
	# anim
	if tween_hit != null:
		tween_hit.kill()
	if tween_heal != null:
		tween_heal.kill()
	tween_hit = create_tween()
	tween_hit.tween_method(_set_hud_astronaut_color, Color(1, 1, 1, 1), Color(1.0, 0.25, 0.25, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_hit.parallel().tween_property(astronaut, "rotation", randf_range(-0.125, 0.125), 0.25).set_trans(Tween.TRANS_ELASTIC)
	
	tween_hit.tween_method(_set_hud_astronaut_color, Color(1.0, 0.25, 0.25, 1.0), Color(1, 1, 1, 1), 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_hit.parallel().tween_property(astronaut, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC)
	tween_hit.tween_callback(_attempt_dying)

func _set_hud_astronaut_color(value: Color):
	shader_material.set_shader_parameter("ColorParameter", value)

func _attempt_dying():
	if life_points <= 0:
		state = "dying"
		# death anim
		$CanvasLayer/ColorRect.show()
		$AnimationPlayer.play("death")
		await $AnimationPlayer.animation_finished
		# signal
		just_died.emit()

var tween_heal : Tween

func _heal_animation():
	# anim
	if tween_heal != null:
		tween_heal.kill()
	if tween_hit != null:
		tween_hit.kill()
	tween_heal = create_tween()
	tween_heal.tween_method(_set_hud_astronaut_color, Color(1, 1, 1, 1), Color(0.25, 1.0, 0.25, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_heal.parallel().tween_property(astronaut, "rotation", randf_range(-0.125, 0.125), 0.25).set_trans(Tween.TRANS_ELASTIC)
	
	tween_heal.tween_method(_set_hud_astronaut_color, Color(0.25, 1.0, 0.25, 1.0), Color(1, 1, 1, 1), 0.25).set_trans(Tween.TRANS_CUBIC)
	tween_heal.parallel().tween_property(astronaut, "rotation", 0.0, 0.25).set_trans(Tween.TRANS_ELASTIC)
	tween_heal.tween_callback(_attempt_dying)

const PX_PER_HP : int = 25
const HEALTH_TRANS_TIME : float = 0.5

var max_hp_tween : Tween

@onready var character_hp_bar : TextureProgressBar = $CanvasLayer/Control/HP_hud/HPBar/CharacterHPBar

func _set_hpbar_max(max_hp : int):
	character_hp_bar.custom_minimum_size.x = min(max_hp * PX_PER_HP, 400.0)
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
