extends CanvasLayer

func _on_animation_player_global_animation_finished(anim_name):
	get_tree().change_scene_to_file("res://modules/corentin/menu.tscn")
