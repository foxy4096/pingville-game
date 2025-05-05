extends CanvasLayer


func change_scene(target):
	$AnimationPlayer.play("play")
	yield($AnimationPlayer, "animation_finished")
	var _x= get_tree().change_scene(target)
	$AnimationPlayer.play_backwards("play")

func restart_scene():
	$AnimationPlayer.play("play")
	yield($AnimationPlayer, "animation_finished")
	var _x = get_tree().reload_current_scene()
	$AnimationPlayer.play_backwards("play")
