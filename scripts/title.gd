extends Control
# Minimal M0 title screen. Replaced by the real title in M5.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		$Hint.text = "Hello, Moon!"
