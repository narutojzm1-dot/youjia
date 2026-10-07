extends SceneTree
# REQ-20261007-062: when the basket has no finds left to place, the yard decor
# panel must not keep asking the player to "pick a place, then a find" while
# every find button reads ×0 and is greyed out. On an empty spot it says why
# and what to do instead (go out for finds, or adjust a placed one). Other
# states (has finds, busy, save failed, unchanged placement, model not loaded)
# keep their existing wording, and the panel stays on screen.
var checks := 0
var failures: Array[String] = []
const VIEWPORTS := [Vector2(280, 653), Vector2(320, 568), Vector2(390, 844), Vector2(568, 320), Vector2(844, 390), Vector2(1280, 720)]
const TEXT := {
	"zh-CN": {
		"choose": "选一处，再选小物；半透明的是预览。",
		"none": "背篓里还没有小物；去门前小路「出门走走」，捡到圆石、松果或落羽再来摆。",
		"placed": "小物都摆出去了；选已摆好的地方，可以挪动或收回背篓。",
		"adjust": "用箭头稍微挪动，也可收回背篓。",
		"busy": "正在确认保存，原有摆设保留着。",
		"failed": "这次还未确认保存，原有物品保留着。",
	},
	"en": {
		"choose": "Choose a place and a find. The faded item is a preview.",
		"none": "No finds yet. Choose \"Take a walk outside\" on the path by the gate, then come back.",
		"placed": "All your finds are placed. Pick a filled place to adjust or put one back.",
		"adjust": "Use the arrows to adjust, or put it back.",
		"busy": "Checking the save. Your arrangement is kept.",
		"failed": "Not confirmed yet. Your items are kept.",
	},
}

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func zero() -> Dictionary:
	var out := {}
	for id: String in ExplorationRoutes.FINDS: out[id] = 0
	return out

func finds_all_grey(p: Control) -> bool:
	for id: String in ExplorationRoutes.FINDS:
		if not p.find_buttons[id].disabled: return false
	return true

func settle() -> void:
	await process_frame
	await process_frame

func on_screen(p: Control, vs: Vector2) -> bool:
	var r: Rect2 = p.paper.get_global_rect()
	return Rect2(Vector2.ZERO, vs).encloses(r) and p.close_button.get_global_rect().end.y <= r.end.y + 0.5

func run() -> void:
	var i18n := root.get_node("I18n")
	var some := zero()
	some[ExplorationRoutes.FINDS[1]] = 1
	var placed := {"places": {"house_edge": {"find_id": ExplorationRoutes.FINDS[0], "dx": 0, "dy": 0}}}
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		var t: Dictionary = TEXT[loc]
		for vs: Vector2 in VIEWPORTS:
			var tag := "%s %dx%d" % [loc, vs.x, vs.y]
			root.size = Vector2i(vs)
			var host := Control.new()
			root.add_child(host)
			host.size = vs
			var p: Control = load("res://scripts/ui/yard_decor_panel.gd").new()
			host.add_child(p)
			await process_frame
			p.size = vs
			# Model not loaded yet: keep the old neutral line, no guessing.
			p.update_view({}, zero(), "idle", false)
			await settle()
			check(p.status.text == t.choose, tag + " model not loaded keeps the neutral line")
			# Brand-new player: nothing found, nothing placed.
			p.update_view({"places": {}}, zero(), "idle", false)
			await settle()
			check(finds_all_grey(p), tag + " no finds: every find button is unavailable")
			check(p.status.text == t.none, tag + " no finds: status says to go out for finds")
			check(p.status.text.find("Take a walk outside" if loc == "en" else "出门走走") >= 0, tag + " hint names the real go-out action")
			check(on_screen(p, vs), tag + " no finds: panel and close button stay on screen")
			check(not p.status.get_combined_minimum_size().x > p.paper.size.x, tag + " hint wraps inside the paper")
			check(not p.close_button.disabled and p.confirm_button.disabled, tag + " no finds: close still works, confirm stays off")
			# Picking another empty spot keeps the same hint.
			p.choose_spot("fence_edge")
			check(p.status.text == t.none, tag + " no finds: other empty spot shows the same hint")
			# Has something to place: the original instruction comes back.
			p.update_view({"places": {}}, some, "idle", false)
			await settle()
			check(p.status.text == t.choose, tag + " with a find: original instruction")
			p.choose_find(ExplorationRoutes.FINDS[1])
			check(p.status.text == t.choose and not p.confirm_button.disabled, tag + " previewing a find keeps the instruction")
			# Everything already placed: empty spot points at the placed ones.
			p.draft.clear()
			p.update_view(placed, zero(), "idle", false)
			p.choose_spot("fence_edge")
			await settle()
			check(p.status.text == t.placed, tag + " all placed: empty spot says finds are out")
			check(on_screen(p, vs), tag + " all placed: panel stays on screen")
			p.choose_spot("house_edge")
			check(p.status.text == t.adjust, tag + " all placed: the filled spot keeps its adjust line")
			check(not p.remove_button.disabled, tag + " all placed: the filled spot can still be put back")
			# Busy and failed saves keep their own wording.
			p.choose_spot("fence_edge")
			p.update_view(placed, zero(), "idle", true)
			check(p.status.text == t.busy, tag + " busy wording wins over the hint")
			p.update_view(placed, zero(), "failed", false)
			check(p.status.text == t.failed, tag + " failed-save wording wins over the hint")
			p.update_view({"places": {}}, zero(), "unknown", false)
			check(p.status.text == t.failed, tag + " unknown-save wording wins over the hint")
			host.queue_free()
			await process_frame
	if failures.is_empty():
		print("[yard-decor-empty-hint] PASS: %d checks" % checks)
		quit(0)
	else:
		for f in failures.slice(0, 20): push_error(f)
		print("[yard-decor-empty-hint] FAIL: %d/%d" % [failures.size(), checks])
		quit(1)
