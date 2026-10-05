extends Node

func _ready() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._on_play_pressed()
	await get_tree().process_frame
	main.set_process(false)
	var world = main._world
	world.set_process(false)
	# Explicit controlled fixture, not a natural fishing claim.
	world._player.position = world._fishing_point() + Vector2(0, -50)
	world._fish_carry_type = "small"
	world._fish_carry_timer = 12.0
	world._fish_state = world.FISH_BITE
	world._fish_timer = 0.1
	world._fish_bite_nudge = 10.0
	if OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("locale=en"):
		I18n.set_locale("en")
	world._tick_fishing(0.2)
	main._process(0.0)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.fishMissFixture = " + JSON.stringify({"notice":main._notice_key,"carry":world._fish_carry_type,"timer":world._fish_carry_timer,"locale":I18n.get_locale()}), true)
