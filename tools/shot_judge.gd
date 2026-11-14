extends Node
var n := 0
func _process(_d: float) -> void:
	n += 1
	if n == 3:
		Judge.begin_judge_run()
		Judge.open_panel(true)
	if n == 14:
		get_viewport().get_texture().get_image().save_png("E:/AMUNi/shot11.png")
		get_tree().quit()
