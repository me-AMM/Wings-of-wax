extends MenuModal
# Pause menu (Esc in the Outpost or a mission): Resume, Save game, Quit to title (with a confirmation).
# Saving is disabled, with the reason shown, during a mission, a storm warning or a storm, and in judge mode.
var hud: Node = null
var in_mission := false

func _ready() -> void:
	super._ready()
	title_text = Text.t("ui.pause")
	var why := Save.can_save(in_mission)
	items.append({"icon": "icon_clock", "text": Text.t("ui.resume")})
	items.append({"icon": "icon_pack", "text": Text.t("ui.save_game"),
		"sub": Text.t(why) if why != "" else "%s %d" % [Text.t("ui.day"), GameState.day],
		"enabled": why == "", "call": _save})
	items.append({"icon": "icon_sleep", "text": Text.t("ui.quit_title"), "call": _confirm_quit})
	build()

func _save() -> void:
	var ok := Save.write(in_mission)
	if hud != null:
		hud.toast(Text.t("ui.game_saved") if ok else Text.t("ui.save_failed"), Color("5FC96B") if ok else Color("FF8080"))
	if ok:
		Audio.play("interact_done")

func _confirm_quit() -> void:
	var m := MenuModal.new()
	m.title_text = Text.t("ui.confirm_quit")
	m.items = [
		{"icon": "icon_lock", "text": Text.t("ui.no")},
		{"icon": "icon_sleep", "text": Text.t("ui.yes"), "sub": Text.t("ui.confirm_quit_sub"), "call": func(): Scenes.go("res://scenes/Title.tscn")}]
	m.menu_width = 250.0
	get_parent().add_child(m)
	m.build()
