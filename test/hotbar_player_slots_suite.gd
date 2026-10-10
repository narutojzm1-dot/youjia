extends SceneTree
## #597 2026-10-09 用户追加：五格快捷栏不预设内容，由玩家配置。
## 空格点一下打开背篓；背篓开着时快捷栏仍在屏幕最下方，背篓纸面让出这一条；
## 可手持的东西从背篓拖进格子（鼠标、手指），或用格子纸片「放进快捷栏 / 从快捷栏拿下」。
## 格子只记种类：配置、替换、拿下、松在别处都不增减背篓里任何东西。配置存在界面偏好里，重开读回。
## 在真实 Main 与隔离存档上跑。
const Prefs := preload("res://scripts/ui/hotbar_slots_prefs.gd")
const VIEWPORTS := [Vector2i(390, 844), Vector2i(280, 653), Vector2i(568, 320), Vector2i(640, 300), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(1920, 1080)]

var checks := 0
var failures: Array[String] = []
var main
var store
var HotbarScript

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)

func settle() -> void:
	check(await store.flush_pending(), "native write and acknowledgement complete")
	for frame in 3: await process_frame

func frames(n: int = 4) -> void:
	for frame in n: await process_frame

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	main._input(event)

func touch_drag(at: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = at
	event.relative = relative
	main._input(event)

func center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func bring_into_view(c: Control) -> void:
	main._basket_panel.scroll.ensure_control_visible(c)
	await frames()

func stock() -> String:
	return JSON.stringify(main._inventory.view())

func run() -> void:
	var isolated := OS.get_environment("YOUJIA_TEST_ISOLATED_DATA").replace("\\", "/").to_lower()
	if isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(isolated):
		push_error("Hotbar player slots requires an isolated player profile")
		quit(2)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Prefs.PATH))
	store = root.get_node("SaveStore")
	HotbarScript = load("res://scripts/ui/hold_hotbar.gd")
	root.size = Vector2i(390, 844)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(3)
	await main._start_holiday()
	main._world._reel_in_fish()
	await settle()
	var bar = main._hold_hotbar
	var panel = main._basket_panel
	var grid = panel.grid
	var fish: String = main._inventory.view().fish.keys()[0]

	# 1. 没有预设：五格都空，点空格打开背篓
	check(bar.slots == ["", "", "", "", ""], "fresh hotbar has no preset contents")
	check(bar.cells.is_empty(), "no slot is bound to any item kind")
	for index in bar.SLOT_COUNT:
		check(bar.slot_counts[index].text.is_empty() and bar.slot_icons[index].texture == null, "slot %d shows nothing" % index)
	await frames()
	check(bar.visible and not panel.visible, "hotbar shows in the yard")
	check(bar.press_at(center(bar.slot_cells[2])), "touching an empty slot is taken by the hotbar")
	await frames()
	check(panel.visible, "touching an empty slot opens the basket")
	main._hide_basket()
	await frames()
	bar.slot_cells[0].pressed.emit()
	await frames()
	check(panel.visible, "clicking an empty slot opens the basket")

	# 2. 背篓开着：快捷栏贴底边、在纸面上层、纸面不压住它
	for viewport: Vector2i in VIEWPORTS:
		var tag := str(viewport)
		root.size = viewport
		await frames()
		check(bar.visible and bar.configuring, tag + " hotbar stays visible as a drop target while the basket is open")
		var r: Rect2 = bar.get_global_rect()
		check(r.position.x >= 0.0 and r.end.x <= float(viewport.x) + 0.5, tag + " hotbar fits the width")
		var paper: Rect2 = panel.panel.get_global_rect()
		var window: Rect2 = panel.scroll.get_global_rect()
		var cell_h: float = grid.cells["small"].size.y
		if panel.shared_row:
			# 矮横屏：快捷栏在纸面右下角，与收窄的「合上背篓」同排
			check(paper.encloses(r), tag + " hotbar sits in the paper's bottom-right corner")
			check(r.end.y <= float(viewport.y) - bar.BASKET_MARGIN + 0.5, tag + " hotbar stays at the bottom")
			check(not panel.close_button.get_global_rect().intersects(r), tag + " close button and hotbar share the row without overlap")
			check(panel.close_button.size.x >= panel.SHARED_CLOSE_MIN and panel.close_button.size.y >= 44.0, tag + " close button stays a full touch target")
			check(window.end.y <= r.position.y + 0.5, tag + " the item window ends above the hotbar")
		else:
			check(is_equal_approx(r.end.y, float(viewport.y) - bar.BASKET_MARGIN), tag + " hotbar sits at the bottom edge")
			check(paper.end.y <= r.position.y - bar.BASKET_MARGIN + 0.5, tag + " basket paper leaves the hotbar strip free")
		check(window.size.y >= cell_h, tag + " at least one full row of items stays visible (%d >= %d)" % [window.size.y, cell_h])
		check(viewport.y > 420 or panel.shared_row, tag + " short landscapes put the hotbar in the paper's corner")
		check(panel.panel.get_global_rect().position.y >= 0.0, tag + " basket paper stays on screen")
		check(bar.get_index() > panel.get_index(), tag + " hotbar draws above the basket shade")
	root.size = Vector2i(390, 844)
	await frames()
	var before := stock()

	# 3. 格子纸片：放进快捷栏 / 从快捷栏拿下（键盘与触屏不拖也能配）
	await bring_into_view(grid.cells[fish])
	grid.open_menu(fish)
	await frames()
	check(grid.menu_hotbar.visible and not grid.menu_hotbar.disabled and grid.menu_hotbar.text == "放进快捷栏", "fish paper offers putting it on the hotbar")
	grid.menu_hotbar.pressed.emit()
	await frames()
	check(bar.slots[0] == fish, "menu puts the fish into the first empty slot")
	check(grid.menu.visible and grid.menu_hotbar.text == "从快捷栏第1格拿下", "paper stays open and now offers taking it off slot 1")
	check(panel.status.text.contains("第1格"), "basket note says which slot")
	check(Prefs.persistent(), "native user:// is a real file, so the preference is written")
	check(Prefs.load_slots() == bar.slots, "slots are saved to the UI preference file")
	check(bar.slot_counts[0].text == "×1" and bar.slot_icons[0].texture != null, "slot shows the fish and its basket count")
	grid.menu_hotbar.pressed.emit()
	await frames()
	check(bar.slots[0].is_empty() and grid.menu_hotbar.text == "放进快捷栏", "taking it off empties the slot")
	check(stock() == before, "menu add / remove never changes the basket")
	grid.close_menu()

	# 4. 鼠标拖：拖到第 3 格；再拖麦粒到同一格替换；鱼拖到第 5 格不会占两格；松在格外不变
	await bring_into_view(grid.cells[fish])
	check(panel.can_drag(fish), "fish can be dragged toward the hotbar")
	check(panel.begin_drag(fish, center(grid.cells[fish])), "mouse drag starts on the fish")
	panel.drag_to(center(bar.slot_cells[2]))
	check(bar.drop_hint == 2, "slot under the pointer lights up")
	check(panel.drag_spot.is_empty(), "no yard spot is lit for a hotbar drag")
	check(panel.end_drag(center(bar.slot_cells[2])) == "hotbar", "dropping on slot 3 configures it")
	check(bar.slots[2] == fish and bar.drop_hint == -1, "slot 3 holds the fish, hint cleared")
	await bring_into_view(grid.cells["wheat"])
	check(panel.begin_drag("wheat", center(grid.cells["wheat"])), "wheat can be dragged too")
	panel.drag_to(center(bar.slot_cells[2]))
	check(panel.end_drag(center(bar.slot_cells[2])) == "hotbar", "dropping wheat on slot 3 replaces the fish")
	check(bar.slots[2] == "wheat" and bar.slot_of(fish) == -1, "replaced fish leaves the bar, stays in the basket")
	await bring_into_view(grid.cells[fish])
	check(panel.begin_drag(fish, center(grid.cells[fish])), "fish drag starts again")
	panel.end_drag(center(bar.slot_cells[4]))
	check(panel.begin_drag("wheat", center(grid.cells["wheat"])), "wheat drag starts again")
	panel.end_drag(center(bar.slot_cells[0]))
	check(bar.slots == ["wheat", "", "", "", fish], "the same kind never takes two slots")
	check(panel.begin_drag("corn", center(grid.cells["corn"])), "corn drag starts")
	var none: String = panel.end_drag(center(panel.title))
	check(none.is_empty() and bar.slots == ["wheat", "", "", "", fish], "releasing away from the hotbar changes nothing")
	check(panel.status.text.contains("快捷格"), "basket says where to drop it")
	check(stock() == before, "mouse drags never change the basket")

	# 5. 手指拖：按住玉米格横拖到第 2 格松手
	await bring_into_view(grid.cells["corn"])
	var from := center(grid.cells["corn"])
	var to := center(bar.slot_cells[1])
	touch(from, true)
	touch_drag(from + Vector2(24, 0), Vector2(24, 0))
	check(panel.drag_kind == "corn", "finger drag starts on the corn cell")
	touch_drag(to, to - from)
	check(bar.drop_hint == 1, "finger over slot 2 lights it")
	touch(to, false)
	await frames()
	check(bar.slots[1] == "corn", "finger drop configures slot 2")
	check(stock() == before, "finger drag never changes the basket")
	# 背篓开着时点快捷格不取物、不开关背篓
	bar.slot_cells[4].pressed.emit()
	bar.slot_cells[3].pressed.emit()
	await frames()
	check(stock() == before and panel.visible, "pressing slots while the basket is open does nothing")

	# 6. 合上背篓：快捷栏回到底栏上方；点鱼格取出；没进格子的东西拿在手里也能点地投放
	main._hide_basket()
	await frames()
	check(bar.visible and not bar.configuring, "hotbar returns to its yard place")
	var yard_rect: Rect2 = HotbarScript.preferred_rect(main.size, main._stacked_hud())
	check(bar.get_global_rect().position.is_equal_approx(yard_rect.position), "hotbar back above the bottom chip row")
	for viewport: Vector2i in VIEWPORTS:
		root.size = viewport
		await frames()
		var yr: Rect2 = bar.get_global_rect()
		check(yr.position.x >= 0.0 and yr.end.x <= float(viewport.x) + 0.5, str(viewport) + " yard hotbar fits the width")
		check(yr.size.is_equal_approx(bar.get_combined_minimum_size()) or yr.size.x >= bar.get_combined_minimum_size().x, str(viewport) + " slots are not squeezed below their size")
	root.size = Vector2i(390, 844)
	await frames()
	check(bar.cells["wheat"].disabled == false and bar.cells["corn"].disabled == false, "grain slots with more than one handful can be used")
	bar.cells[fish].pressed.emit()
	await settle()
	check(main._inventory.view().held == fish, "tapping the fish slot takes the fish out")
	check(bar.selected_kind() == fish and bar.is_place_armed(), "held fish slot is selected and armed")
	main._inventory.request("return", fish)
	await settle()
	bar.set_slots(["", "", "", "", ""])
	main._inventory.request("withdraw", fish)
	await settle()
	check(main._inventory.view().held == fish and bar.is_place_armed(), "food not on the hotbar still arms tap-to-place")
	main._inventory.request("return", fish)
	await settle()

	# 7. 读回：配置跨重开保留；坏值、重复都当空格
	bar.set_slots(Prefs.load_slots())
	check(bar.slots == ["wheat", "corn", "", "", fish], "slots reload from the preference file")
	var fresh = HotbarScript.new()
	root.add_child(fresh)
	await frames(1)
	fresh.set_slots(["wheat", "round_stone", "wheat", 7, "", "millet"])
	check(fresh.slots == ["wheat", "", "", "", ""], "unknown, duplicate and extra entries become empty")
	fresh.queue_free()

	# 8. 只剩一把种子的谷物格不可点（留着播种），与背篓同一规则
	var reserve = HotbarScript.new()
	root.add_child(reserve)
	await frames(1)
	reserve.set_slots(["wheat"])
	reserve.update_view({"held": "", "fish": {}, "wheat": 1}, {}, "idle", false)
	check(reserve.cells["wheat"].disabled and reserve.slot_counts[0].text == "×1", "last handful of wheat stays for planting")
	reserve.queue_free()

	# 9. 空闲帧不重建格子样式（每帧 _refresh_hud 都会同步配置态）
	var builds: int = bar.restyle_builds
	await frames(30)
	check(bar.restyle_builds == builds, "idle yard frames rebuild no slot styles (%d)" % (bar.restyle_builds - builds))
	main._show_basket()
	await frames()
	builds = bar.restyle_builds
	await frames(30)
	check(bar.configuring and bar.restyle_builds == builds, "idle frames with the basket open rebuild no slot styles")
	await bring_into_view(grid.cells["wheat"])
	check(panel.begin_drag("wheat", center(grid.cells["wheat"])), "wheat drag starts for the hint check")
	panel.drag_to(center(bar.slot_cells[3]))
	check(bar.drop_hint == 3 and bar.restyle_builds > builds, "drag hint still restyles the slot it lights")
	var hot_box := bar.slot_cells[3].get_theme_stylebox("normal") as StyleBoxFlat
	check(hot_box.border_color == bar.DROP_EDGE, "lit slot shows the drop edge")
	main._hide_basket()
	await frames()
	check(bar.drop_hint == -1 and not bar.configuring, "closing the basket clears the drop hint")
	var cool_box := bar.slot_cells[3].get_theme_stylebox("normal") as StyleBoxFlat
	check(cool_box.border_color != bar.DROP_EDGE, "slot loses the drop edge after the basket closes")
	builds = bar.restyle_builds
	for repeat in 5:
		bar.set_configuring(false)
		bar.set_drop_hint(-1)
	check(bar.restyle_builds == builds, "repeating the same configuring state rebuilds nothing")

	# 10. 英文
	root.get_node("I18n").set_locale("en")
	main._show_basket()
	await frames()
	await bring_into_view(grid.cells[fish])
	grid.open_menu(fish)
	await frames()
	check(grid.menu_hotbar.text == "Take off hotbar slot 5", "English paper names the slot")
	grid.close_menu()
	main._hide_basket()
	root.get_node("I18n").set_locale("zh-CN")
	_finish()

func _finish() -> void:
	check(checks >= 60, "suite ran enough checks (%d)" % checks)
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("[hotbar-player-slots] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure in failures: push_error(failure)
		print("[hotbar-player-slots] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
