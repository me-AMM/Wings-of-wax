# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
extends MenuModal
# HabitatMenu: Eat (ration / radish meal), Sleep, Gym. Disabled rows show why.
# `outpost` is set by the Outpost scene; sleep and gym need its fade/animation.
var outpost: Node

func _ready() -> void:
	super._ready()
	title_text = Text.t("ui.habitat")
	var gs := GameState
	var left := Text.t("ui.left")
	# Eat ration
	var why := ""
	if gs.ate_today:
		why = Text.t("ui.already_ate")
	elif gs.rations <= 0:
		why = Text.t("ui.no_food")
	items.append({"icon": "icon_ration", "text": Text.t("ui.eat") + ": " + Text.t("ui.ration"),
		"sub": why if why != "" else "%d %s" % [gs.rations, left], "enabled": why == "",
		"call": func(): _eat("ration")})
	# Eat radish meal (shown once radishes exist)
	if gs.day >= 2 or gs.radish_meals > 0:
		why = ""
		if gs.ate_today:
			why = Text.t("ui.already_ate")
		elif gs.radish_meals <= 0:
			why = Text.t("ui.no_food")
		items.append({"icon": "icon_radish", "text": Text.t("ui.eat") + ": " + Text.t("ui.radish_meal"),
			"sub": why if why != "" else "%d %s" % [gs.radish_meals, left], "enabled": why == "",
			"call": func(): _eat("radish")})
	# Sleep
	var sw := gs.can_sleep()
	items.append({"icon": "icon_sleep", "text": Text.t("ui.sleep"), "sub": Text.t(sw) if sw != "" else "+%d %s" % [int(Config.data["health"]["sleep_heal"][gs.sliders[2]]), Text.t("ui.health_word")],
		"enabled": sw == "", "call": func(): outpost.do_sleep()})
	# Gym (opens on day 2)
	if gs.is_unlocked("gym"):
		var gw := gs.can_gym()
		items.append({"icon": "icon_gym", "text": Text.t("ui.gym"), "sub": Text.t(gw) if gw != "" else "+5 " + Text.t("ui.health_word"),
			"enabled": gw == "", "call": func(): outpost.do_gym()})
	menu_width = 260.0
	build()

func _eat(kind: String) -> void:
	var r := GameState.eat(kind)
	if r == "":
		outpost.hud.toast("+%d" % int(Config.data["health"]["meal_heal"]), UIStyle.DANGER)
		Audio.play("eat")
	else:
		outpost.hud.toast(Text.t(r))
