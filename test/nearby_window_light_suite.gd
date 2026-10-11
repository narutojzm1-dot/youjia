extends SceneTree
const Store := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)
func run() -> void:
	var painting := Sprite2D.new()
	painting.centered = false; painting.texture = load(NearPathLayout.ART)
	root.add_child(painting)
	var water := NearPathMotion.new(); water.bind(painting, false)
	var original: Material = painting.material
	var light := NearPathWindowLight.new(); light.bind(painting, false)
	check(painting.material == original, "local light does not replace water or tree paint")
	check(light._layer.layer == 6 and light._layer.follow_viewport_enabled, "light stays in world space after multiplier and before HUD")
	check(light._layer.custom_viewport == painting.get_viewport(), "each composition uses its own viewport")
	var mask: Image = NearPathWindowLight.MASK.get_image()
	check(mask.get_size() == Vector2i(170,112), "pane mask is 76,160 decoded bytes, not another background")
	for point: Vector2i in [Vector2i(1412,322),Vector2i(1422,329),Vector2i(1412,338),Vector2i(1373,397),Vector2i(1380,404),Vector2i(1472,403),Vector2i(1480,410)]:
		check(mask.get_pixelv(point-Vector2i(NearPathWindowLight.BOUNDS.position)).r > 0.8, "glass receives light "+str(point))
	for point: Vector2i in [Vector2i(1417,329),Vector2i(1412,334),Vector2i(1373,401),Vector2i(1472,399),Vector2i(1420,400)]:
		check(mask.get_pixelv(point-Vector2i(NearPathWindowLight.BOUNDS.position)).r == 0.0, "frame, crossbar or doorway stays unmasked "+str(point))
	var state := {"day_fraction":0.625,"weather":"rain","day":2}
	var copy := state.duplicate(true)
	light.sync_environment(state, true)
	check(state == copy and light.amount == 1.0 and light._layer.visible, "public night snapshot is consumed read-only")
	light.sync_environment({"day_fraction":0.82},true)
	check(light.amount == 1.0, "outdoor house stays lit after midnight under the shared rule")
	light.sync_environment({"day_fraction":0.25},false)
	light.advance(0.25,false)
	check(light.amount > 0.0 and light.amount < 1.0, "daybreak only fades decorative opacity")
	light.apply(true,true)
	check(light.amount == 0.0 and not light._layer.visible, "reduced motion settles static daylight immediately")
	light.sync_environment(state,true)
	check(light._layer.visible, "reduced motion retains useful static night light")
	light.apply(false,true);light.sync_environment({"day_fraction":0.25},false)
	light.apply(true,false)
	check(not light._layer.visible, "returning from another map cannot show stale night light in daytime")
	light.release();await process_frame
	check(not painting.get_parent().has_node("NearWindowLight"), "release frees the local canvas only")
	water.release();painting.queue_free()
	await scene()
	print("NEARBY_WINDOW_LIGHT checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
func scene() -> void:
	var tuning := root.get_node("TuningStore");tuning.set_value("ui.reduced_motion",false)
	var store := Store.new();root.add_child(store)
	var host := ExplorationHost.new(store);host.restore();host.begin({"day":2,"elapsed":20.0},3);store.pump()
	var record: Dictionary = host.session.to_record().duplicate(true)
	var scroll = load("res://scripts/exploration/near_path_scroll.gd").new();root.add_child(scroll);scroll.setup(host,"sun")
	scroll.sync_environment({"day_fraction":0.625},true)
	var foot: Vector2 = scroll.foot()
	await process_frame
	check(scroll.window_light._layer.visible and scroll.foot() == foot and host.session.to_record() == record, "production integration never moves or edits the trip")
	scroll.sync_environment({"day_fraction":0.25})
	paused = true
	var amount: float = scroll.window_light.amount
	await process_frame;await process_frame
	check(scroll.window_light.amount == amount, "real SceneTree pause freezes the decorative fade")
	tuning.set_value("ui.reduced_motion",true)
	check(scroll.window_light.amount == 0.0, "live preference settles even while paused")
	paused = false;scroll.set_process(false);scroll.sync_environment({"day_fraction":0.625},true)
	scroll.spot={"arm":"lane","d":0.0}
	check(scroll.cross_page() and not scroll.window_light._layer.visible, "village does not inherit near panes")
	scroll.spot={"arm":"lane","d":0.0}
	check(scroll.cross_page() and scroll.window_light._layer.visible, "near composition restores its own panes")
	scroll.release();await process_frame
	check(not scroll.has_node("NearWindowLight"), "normal return removes the local pass")
	scroll.queue_free();store.queue_free()
