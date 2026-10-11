extends SceneTree

# #350: isolated presentation fixture derived from an actual public photograph.
# No save mutation, world stepping or browser injection is needed for geometry.
const VIEWS := [Vector2i(390, 844), Vector2i(844, 390), Vector2i(1280, 720), Vector2i(360, 640), Vector2i(700, 400), Vector2i(700, 460), Vector2i(720, 460), Vector2i(700, 500),
	Vector2i(320, 568), Vector2i(280, 653)]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ", message)

func descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(descendants(child))
	return result

func run() -> void:
	var actual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://test/fixtures/album_landscape_photo.json"))
	await scenario(actual.duplicate(true), "five actual photographs")
	# Presentation-only clones exercise every existing caption/note, including
	# rare events. These are geometry fixtures, not natural event/capture proof.
	for variant in range(3):
		var moments: Dictionary = {}
		for rule: Dictionary in ExpressionCatalog.RULES:
			if not bool(rule.get("polaroid", false)): continue
			var record: Dictionary = actual.values()[0].duplicate(true)
			record.rule_id = rule.id
			record.caption_variant = variant % int(rule.get("caption_variants", 1))
			moments[rule.id] = record
		await scenario(moments, "all existing captions variant %d" % variant)
	print("ALBUM_LAYOUT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func scenario(moments: Dictionary, description: String) -> void:
	var store = root.get_node("SaveStore")
	store._data = store._default_data()
	for photo: Dictionary in moments.values():
		photo.day = 10000
		check(not PhotoMoment.sanitize(photo).is_empty(), "historical photograph fixture remains valid")
	store._data.album = moments.keys() + ["cow_pet_gentle"]
	store._data.photo_moments = moments
	var before: Dictionary = store._data.duplicate(true)
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main._show_album()
	for locale in ["zh-CN", "en"]:
		root.get_node("I18n").set_locale(locale)
		for dims in VIEWS:
			root.size = dims
			await process_frame
			main._layout()
			for index in range(store._data.album.size()):
				main._album_index = index
				main._render_album_pages()
				for frame in range(4): await process_frame
				inspect_pages(main, "%s %s %s #%d" % [description, locale, dims, index])
			main._album_entries.clear()
			main._render_album_pages()
			for frame in range(3): await process_frame
			inspect_pages(main, "%s %s empty" % [locale, dims])
			main._album_entries = PackedStringArray(store._data.album)
	check(store._data.album == before.album and store._data.photo_moments == before.photo_moments, "resizing, languages, legacy and empty pages preserve historical photographs")
	main.queue_free()
	await process_frame

func inspect_pages(main: Control, tag: String) -> void:
	var page_index: int = main._album_index
	for page in main._album_spread.get_children():
		if page is ColorRect: continue
		var bounds: Rect2 = page.get_global_rect().grow(0.5)
		check(Rect2(Vector2.ZERO, main.size).encloses(bounds.grow(-0.5)), tag + " page stays on screen")
		var navigation: Array[Control] = [main._album_previous_button, main._album_next_button, main._album_back_button]
		for button in navigation:
			check(not bounds.grow(-0.5).intersects(button.get_global_rect()), tag + " page clear of navigation")
		_check_frame(main, tag)
		var texts: Array[Label] = []
		var photos: Array[Control] = []
		for node in descendants(page):
			if node is Label and not node.text.is_empty():
				texts.append(node)
				check(bounds.encloses(node.get_global_rect()), tag + " text stays on page: " + node.text)
				check(node.size.y + 0.5 >= node.get_minimum_size().y, tag + " text fits its height")
			if node is PhotoMoment:
				if not node.get_parent().get_global_rect().grow(0.5).encloses(node.get_global_rect()):
					print("PHOTO_GEOMETRY ", tag, " actual=", node.get_global_rect(), " minimum=", node.custom_minimum_size, " holder=", node.get_parent().get_global_rect())
				photos.append(node)
				check(bounds.encloses(node.get_global_rect()), tag + " photograph stays on page")
				check(node.get_parent().get_global_rect().grow(0.5).encloses(node.get_global_rect()), tag + " photograph stays inside its polaroid")
				check(is_equal_approx(node.size.x, node.size.y), tag + " photograph keeps its square aspect")
		var expected_photos := 0
		if page_index < main._album_entries.size():
			if not root.get_node("SaveStore").get_photo_moment(main._album_entries[page_index]).is_empty():
				expected_photos = 1
		check(photos.size() == expected_photos, tag + " recorded photographs remain present; legacy/empty pages keep their fallback")
		page_index += 1
		for text in texts:
			for button in navigation:
				check(not text.get_global_rect().intersects(button.get_global_rect()), tag + " text clear of all navigation")
			for photograph in photos:
				check(not text.get_global_rect().intersects(photograph.get_global_rect()), tag + " photograph does not cover text: " + text.text)
			for other in texts:
				if text.get_instance_id() < other.get_instance_id():
					check(not text.get_global_rect().intersects(other.get_global_rect()), tag + " text blocks do not overlap")
		for photograph in photos:
			for button in navigation:
				check(not photograph.get_global_rect().intersects(button.get_global_rect()), tag + " photograph clear of all navigation")
			var expected := PhotoDiary.caption(photograph._snapshot)
			var found := false
			for text in texts:
				if text.text == expected: found = true
			check(found, tag + " full original photograph date and caption remain present")

## 窄竖屏（280、320 宽）：整张手帐和三枚翻页按钮都留在屏幕里，按钮字不被挤出按钮，按钮互不重叠
func _check_frame(main: Control, tag: String) -> void:
	var screen := Rect2(Vector2.ZERO, main.size)
	check(screen.encloses(main._album_panel.get_global_rect()), tag + " album frame stays on screen %s" % main._album_panel.get_global_rect())
	var navigation: Array[Button] = [main._album_previous_button, main._album_next_button, main._album_back_button]
	for button in navigation:
		var rect := button.get_global_rect()
		check(main._album_panel.get_global_rect().grow(0.5).encloses(rect), tag + " '%s' stays inside the album frame" % button.text)
		var paper := button.get_theme_stylebox("normal")
		var need := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x + paper.get_margin(SIDE_LEFT) + paper.get_margin(SIDE_RIGHT)
		check(need <= button.size.x + 0.5, tag + " '%s' label fits its button" % button.text)
		check(button.size.y >= 40.0, tag + " '%s' keeps a touch height" % button.text)
		for other in navigation:
			if other != button:
				check(not rect.intersects(other.get_global_rect()), tag + " '%s' clear of '%s'" % [button.text, other.text])
