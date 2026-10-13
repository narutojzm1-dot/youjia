extends SceneTree

const Store := preload("res://test/fixtures/exploration_memory_store.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func run() -> void:
	var model := NearPathMotion.new()
	var sprite := Sprite2D.new()
	root.add_child(sprite)
	model.bind(sprite, false)
	check(sprite.material is ShaderMaterial, "nearby has one masked paint material")
	model.advance(1.0, false)
	check(is_equal_approx(model.phase, 0.42), "cosmetic phase advances independently")
	model.apply(true, true)
	var frozen := model.phase
	model.advance(30.0, true)
	check(sprite.material == null and model.phase == frozen, "reduced motion removes GPU pass and freezes phase")
	model.apply(true, false)
	check(sprite.material != null and model.phase == frozen, "resuming keeps exact prior phase")
	model.advance(-1.0, false)
	check(model.phase == frozen, "negative delta cannot reverse scene")
	model.apply(false, false)
	model.advance(5.0, false)
	check(sprite.material == null and model.phase == frozen, "other page cannot use near-path mask")
	model.release()
	sprite.queue_free()
	var mask: Image = NearPathMotion.REGIONS.get_image()
	check(mask.get_size() == Vector2i(1672, 941), "mask registered to exact original painting bounds")
	for point: Vector2i in [Vector2i(306,573), Vector2i(254,589), Vector2i(188,610), Vector2i(240,640), Vector2i(251,694), Vector2i(182,718), Vector2i(242,763), Vector2i(210,790)]:
		var ink := mask.get_pixelv(point)
		check(ink.r > 0.5 and ink.g == 0.0, "water interior has only red channel: " + str(point))
	for point: Vector2i in [Vector2i(1098,54), Vector2i(1287,45), Vector2i(1350,139), Vector2i(1578,220), Vector2i(488,475), Vector2i(539,545), Vector2i(614,692), Vector2i(719,670), Vector2i(1422,769), Vector2i(850,823)]:
		var ink := mask.get_pixelv(point)
		check(ink.g > 0.5 and ink.r == 0.0, "foliage interior has only green channel: " + str(point))
	for point: Vector2i in [Vector2i(100,100), Vector2i(1635,600), Vector2i(300,519), Vector2i(212,665), Vector2i(314,690), Vector2i(380,773), Vector2i(1439,379), Vector2i(1200,530), Vector2i(1000,728), Vector2i(1500,94)]:
		var ink := mask.get_pixelv(point)
		check(ink.r == 0.0 and ink.g == 0.0, "paper, bridge, rocks, house, fence, road and trunk stay still: " + str(point))
	await _scene()
	print("NEARBY_MOTION checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _scene() -> void:
	var tuning := root.get_node("TuningStore")
	tuning.set_value("ui.reduced_motion", false)
	var store := Store.new()
	root.add_child(store)
	var host := ExplorationHost.new(store)
	host.restore()
	host.begin({"day": 2, "elapsed": 20.0}, 3)
	store.pump()
	var record: Dictionary = host.session.to_record().duplicate(true)
	var scroll = load("res://scripts/exploration/near_path_scroll.gd").new()
	root.add_child(scroll)
	scroll.setup(host, "sun")
	var foot: Vector2 = scroll.foot()
	await process_frame
	await process_frame
	check(scroll.scenery_motion.phase > 0.0, "actual production scene advances local effect")
	check(scroll.foot() == foot and host.session.to_record() == record, "paint motion never changes position or trip/persistence")
	paused = true
	var phase: float = scroll.scenery_motion.phase
	await process_frame
	await process_frame
	check(scroll.scenery_motion.phase == phase, "SceneTree pause freezes effect exactly")
	tuning.set_value("ui.reduced_motion", true)
	check(scroll.painting.material == null, "live reduced setting removes material even while paused")
	paused = false
	await process_frame
	check(scroll.scenery_motion.phase == phase, "reduced scene stays static after resume")
	tuning.set_value("ui.reduced_motion", false)
	check(scroll.painting.material != null, "live enable restores paint material")
	scroll.set_process(false)
	scroll.spot = {"arm": "lane", "d": 0.0}
	check(scroll.cross_page() and scroll.village and scroll.painting.material == null, "cross-map removes mask from village composition")
	scroll.spot = {"arm": "lane", "d": 0.0}
	check(scroll.cross_page() and not scroll.village and scroll.painting.material != null, "returning near-path restores same masked pass")
	scroll.release()
	check(scroll.painting.material == null, "release leaves no live effect")
	scroll.queue_free()
	store.queue_free()
