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
	painting.centered = false
	painting.texture = load(NearPathLayout.ART)
	root.add_child(painting)
	var water := NearPathMotion.new()
	water.bind(painting, false)
	var material: Material = painting.material
	var mist := NearPathMist.new()
	mist.bind(painting, false)
	var overlay: Sprite2D = painting.get_node("FarMist")
	check(painting.material == material, "mist never replaces the existing water/grass material")
	check(overlay.region_enabled and overlay.region_rect == NearPathMist.BOUNDS, "only a cropped far region is drawn")
	check(overlay.position == NearPathMist.BOUNDS.position, "overlay registered to original painting coordinates")
	var mask: Image = NearPathMist.REGIONS.get_image()
	check(mask.get_size() == Vector2i(540,220), "mask is a small 0.45MiB crop, not another full background")
	for point: Vector2i in [Vector2i(763,432)]:
		var ink := mask.get_pixelv(point - Vector2i(NearPathMist.BOUNDS.position))
		check(ink.r > 0.8 and ink.g == 0.0, "lake interior retains its own soft region: " + str(point))
	for point: Vector2i in [Vector2i(648,294),Vector2i(834,266),Vector2i(927,288),Vector2i(827,356),Vector2i(970,389)]:
		var ink := mask.get_pixelv(point - Vector2i(NearPathMist.BOUNDS.position))
		check(ink.g > 0.8 and ink.r == 0.0, "ridge mist stays on the authored distant slope: " + str(point))
	for point: Vector2i in [Vector2i(532,371),Vector2i(716,410),Vector2i(500,300),Vector2i(620,420),Vector2i(880,435),Vector2i(1005,450),Vector2i(800,450)]:
		var ink := mask.get_pixelv(point - Vector2i(NearPathMist.BOUNDS.position))
		check(ink.r == 0.0 and ink.g == 0.0, "far trees and shores remain clear: " + str(point))
	var state := {"weather":"sun","daylight":1.0,"day":2,"elapsed":30.0}
	var before := state.duplicate(true)
	mist.sync_environment(state, true)
	var sun := mist.strength
	check(state == before, "environment snapshot is read-only")
	mist.sync_environment({"weather":"overcast","daylight":1.0},true)
	var cloud := mist.strength
	mist.sync_environment({"weather":"rain","daylight":1.0},true)
	check(mist.strength > cloud and cloud > sun, "rain/overcast only adjust the same local paint layer")
	mist.sync_environment({"weather":"rain","daylight":0.0},true)
	check(mist.strength < sun, "shared night daylight dims mist instead of emitting a bright veil")
	mist.sync_environment(state)
	var starting := mist.strength
	mist.advance(1.0,false)
	check(mist.strength > starting and mist.strength < sun, "weather transition fades gradually")
	mist.apply(true,true)
	var phase := mist.phase
	mist.advance(200.0,true)
	check(not overlay.visible and mist.phase == phase, "reduced motion removes the pass and freezes phase")
	mist.apply(true,false)
	mist.advance(-1.0,false)
	check(overlay.visible and mist.phase == phase, "resuming keeps phase and negative delta has no effect")
	mist.apply(false,false)
	mist.advance(10.0,false)
	check(not overlay.visible and mist.phase == phase, "other composition cannot inherit the near mask")
	mist.release()
	await process_frame
	check(not painting.has_node("FarMist") and painting.material == material, "release removes only mist")
	water.release()
	painting.queue_free()
	await scene()
	print("NEARBY_MIST checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

func scene() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.set_value("ui.reduced_motion",false)
	var store := Store.new()
	root.add_child(store)
	var host := ExplorationHost.new(store)
	host.restore();host.begin({"day":2,"elapsed":20.0},3);store.pump()
	var record: Dictionary = host.session.to_record().duplicate(true)
	var scroll = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll);scroll.setup(host,"sun")
	var foot: Vector2 = scroll.foot()
	await process_frame;await process_frame
	check(scroll.scenery_mist.phase > 0.0, "actual production scene advances local mist")
	check(scroll.foot() == foot and host.session.to_record() == record, "mist never changes position or trip/transactions")
	paused = true
	var phase: float = scroll.scenery_mist.phase
	await process_frame;await process_frame
	check(scroll.scenery_mist.phase == phase, "SceneTree pause freezes mist")
	tuning.set_value("ui.reduced_motion",true)
	check(not scroll.painting.get_node("FarMist").visible, "reduced setting removes mist even while paused")
	paused = false
	await process_frame
	check(scroll.scenery_mist.phase == phase, "reduced scene remains static after resume")
	tuning.set_value("ui.reduced_motion",false)
	check(scroll.painting.get_node("FarMist").visible, "live setting restores local mist")
	scroll.set_process(false);scroll.spot={"arm":"lane","d":0.0}
	check(scroll.cross_page() and not scroll.painting.get_node("FarMist").visible, "village composition does not inherit mist")
	scroll.spot={"arm":"lane","d":0.0}
	check(scroll.cross_page() and scroll.painting.get_node("FarMist").visible, "return restores mask on the original near painting")
	scroll.release()
	await process_frame
	check(not scroll.painting.has_node("FarMist"), "return cleanup removes mist and its GPU pass")
	scroll.queue_free();store.queue_free()
