extends CanvasLayer

func _ready():
	BackgroundMusic.play_menu.call_deferred()

func _on_animation_player_global_animation_finished(anim_name):
	get_tree().change_scene_to_file("res://modules/corentin/menu.tscn")
