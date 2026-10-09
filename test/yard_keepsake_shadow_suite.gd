extends SceneTree
# REQ-20261008-066: keepsakes placed in the yard (round stone, pine cone, feather)
# are drawn from textures with no grounding at all, so on grass they read as
# floating stickers. Each textured keepsake now gets a still, soft contact shadow
# under its lower edge. The shadow must stay inside YardPropVisual.bounds so
# decor occlusion and photo framing rects do not move, must not depend on time
# or motion settings, and only appears when the texture is in use.
var checks := 0
var failures: Array[String] = []
const PROP := "res://scripts/game/yard_prop_visual.gd"

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func has_static(script: Script, method: String) -> bool:
	for m: Dictionary in script.get_script_method_list():
		if m.name == method: return true
	return false

func texture_extent(find_id: String) -> Vector2:
	var tex := KeepsakeArt.texture(find_id)
	var span := (24.0 if find_id.get_slice(".", 2) == "brook_stone" else KeepsakeArt.TEXTURE_SPAN) * 0.65 / maxf(tex.get_width(), tex.get_height())
	return Vector2(tex.get_width(), tex.get_height()) * span

func run() -> void:
	var script: Script = load(PROP)
	var bounds: Rect2 = script.call("bounds", "keepsake")
	check(bounds == Rect2(-14, -12, 28, 24), "keepsake bounds unchanged for decor occlusion and photo framing")
	var available := has_static(script, "keepsake_shadow")
	check(available, "YardPropVisual exposes keepsake_shadow(find_id)")
	check(ExplorationRoutes.FINDS.size() == 3, "three formal finds to cover")
	for find_id: String in ExplorationRoutes.FINDS:
		var tag := find_id.get_slice(".", 2)
		check(KeepsakeArt.texture(find_id) != null, tag + " has its runtime texture")
		var shadow: Dictionary = script.call("keepsake_shadow", find_id) if available else {}
		check(not shadow.is_empty(), tag + " textured keepsake gets a contact shadow")
		if shadow.is_empty():
			for i in 9: check(false, tag + " shadow geometry")
			continue
		var center: Vector2 = shadow.center
		var radii: Vector2 = shadow.radii
		var extent := texture_extent(find_id)
		var oval := Rect2(center - radii, radii * 2.0)
		check(bounds.encloses(oval), tag + " shadow stays inside keepsake bounds %s" % oval)
		check(is_zero_approx(center.x), tag + " shadow centred under the item")
		check(center.y > 0.0, tag + " shadow sits below the prop origin (on the ground side)")
		check(center.y - radii.y < extent.y * 0.5, tag + " shadow top tucks under the art, not floating beneath it")
		check(center.y + radii.y > (extent.y * 0.5 if tag != "feather" else extent.y * 0.2), tag + " shadow reaches the art's lower edge")
		check(radii.x >= 4.0 and radii.x < extent.x * 0.5, tag + " shadow narrower than the art (%.1f vs %.1f)" % [radii.x * 2.0, extent.x])
		check(radii.y >= 2.0 and radii.y <= 4.0, tag + " shadow stays a flat ground oval (%.1f px tall)" % (radii.y * 2.0))
		check(radii.x > radii.y * 2.0, tag + " shadow is wider than tall")
		check(script.call("keepsake_shadow", find_id) == shadow, tag + " shadow is static (same result every call)")
		# Live props, decor previews and photo replays all go through configure/_draw;
		# none of them carries motion state for keepsakes, so the shadow cannot animate.
		var state: Dictionary = script.call("sanitize_state", "keepsake", {"find_id": find_id})
		check(state == {"find_id": find_id}, tag + " keepsake state still only the find id")
		check(script.call("sanitize_state", "keepsake", {"find_id": find_id, "reduced_motion": true}).is_empty(), tag + " keepsake state still rejects extra motion fields")
	check((script.call("keepsake_shadow", "find.near_path.unknown") if available else {"x": 1}).is_empty(), "unknown find without texture draws no extra shadow")
	var prop: Node2D = script.new()
	root.add_child(prop)
	prop.call("configure", "keepsake", {"find_id": ExplorationRoutes.FINDS[0]})
	await process_frame
	check(prop.get("state") == {"find_id": ExplorationRoutes.FINDS[0]}, "configured prop draws without error")
	prop.queue_free()
	await process_frame
	if failures.is_empty():
		print("[yard-keepsake-shadow] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 20): push_error(f)
		print("[yard-keepsake-shadow] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
