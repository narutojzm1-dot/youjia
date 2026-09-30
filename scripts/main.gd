extends Control
const OpenSourceLicenses = preload("res://scripts/manus/open_source_licenses.gd")
const YardWorldType := preload("res://scripts/game/yard_world.gd")
const TITLE_PAPER := preload("res://assets/holiday/ui/scrapbook_paper.png")
const POLAROID := preload("res://assets/holiday/ui/polaroid_frame.png")

const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const MUTED := Color("8a7060")
const APRICOT := Color("f3b27a")
const SAGE := Color("8fb389")
const CREAM := Color("fffaf1")
const LAVENDER := Color("cbb6d6")

var _paper: TextureRect
var _world_root: Node2D
var _world: YardWorld
var _camera: Camera2D
var _title_screen: Control
var _title_label: Label
var _subtitle_label: Label
var _tagline_label: Label
var _play_button: Button
var _album_button: Button
var _licenses_button: Button
var _title_hint: Label
var _hud: Control
var _hint_label: Label
var _album_chip: Button
var _weather_chip: Button
var _pause_button: Button
var _pause_screen: Control
var _pause_title: Label
var _resume_button: Button
var _restart_button: Button
var _pause_title_button: Button
var _confirm_screen: Control
var _confirm_title: Label
var _confirm_message: Label
var _confirm_accept_button: Button
var _confirm_cancel_button: Button
var _pending_destructive_action := ""
var _album_screen: Control
var _album_title: Label
var _album_grid: GridContainer
var _album_back_button: Button
var _notice: Label
var _notice_time := 0.0
var _screen := "title"
var _cam_zoom := 1.0
var _cam_target_zoom := 1.0
var _cam_offset := Vector2.ZERO
var _cam_target_offset := Vector2.ZERO
var _latest_photo := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	I18n.set_locale("zh-CN")
	_build_layers()
	_build_title_screen()
	_build_hud()
	_build_pause_screen()
	_build_confirmation_screen()
	_build_album_screen()
	_build_notice()
	I18n.locale_changed.connect(_on_locale_changed)
	TuningStore.value_changed.connect(_on_tuning_value_changed)
	resized.connect(_layout)
	_refresh_texts()
	_show_title()
	call_deferred("_layout")


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			_notice.visible = false
	if _screen == "game" and _world != null and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible:
		var move := Vector2.ZERO
		if _world.input_enabled:
			move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_world.tick(delta, move)
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var lerp_rate := 12.0 if reduced else 3.2
	_cam_zoom = lerpf(_cam_zoom, _cam_target_zoom, 1.0 - exp(-delta * lerp_rate))
	_cam_offset = _cam_offset.lerp(_cam_target_offset, 1.0 - exp(-delta * (12.0 if reduced else 3.0)))
	var zoom := _cam_zoom * float(TuningStore.get_value("environment.camera.zoom", 1.0))
	_camera.zoom = Vector2(zoom, zoom)
	_camera.position = YardWorld.WORLD_SIZE * 0.5 + _cam_offset
	if _screen == "game":
		_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _album_screen.visible:
			_hide_album()
		elif _screen == "game":
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _screen != "game" or _world == null or not _world.input_enabled:
		return
	if _pause_screen.visible or _album_screen.visible or _confirm_screen.visible:
		return
	if event.is_action_pressed("ui_accept"):
		_world.try_interact()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var world_point := _screen_to_world(event.position)
		if not _world.try_walk_to(world_point):
			_world.try_interact()
		get_viewport().set_input_as_handled()


func _build_layers() -> void:
	_paper = TextureRect.new()
	_paper.texture = TITLE_PAPER
	_paper.stretch_mode = TextureRect.STRETCH_SCALE
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_paper)
	_world_root = Node2D.new()
	_world_root.name = "WorldRoot"
	add_child(_world_root)
	_camera = Camera2D.new()
	_camera.position = YardWorld.WORLD_SIZE * 0.5
	_camera.enabled = false
	_world_root.add_child(_camera)


func _build_title_screen() -> void:
	_title_screen = Control.new()
	_title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_title_screen)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -240
	column.offset_right = 240
	column.offset_top = -220
	column.offset_bottom = 260
	_title_screen.add_child(column)
	_title_label = _label(40, INK)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title_label)
	_subtitle_label = _label(18, APRICOT)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_subtitle_label)
	_tagline_label = _label(16, MUTED)
	_tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_tagline_label)
	_play_button = _soft_button()
	_play_button.pressed.connect(_start_holiday)
	column.add_child(_play_button)
	_album_button = _soft_button()
	_album_button.pressed.connect(_show_album)
	column.add_child(_album_button)
	_licenses_button = _text_button()
	_licenses_button.pressed.connect(_open_licenses)
	column.add_child(_licenses_button)
	_title_hint = _label(14, MUTED)
	_title_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title_hint)


func _build_hud() -> void:
	_hud = Control.new()
	_hud.visible = false
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hud)
	_hint_label = _label(15, INK)
	_hint_label.position = Vector2(24, 18)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.size = Vector2(520, 70)
	_hud.add_child(_hint_label)
	_album_chip = _chip_button()
	_album_chip.pressed.connect(_show_album)
	_hud.add_child(_album_chip)
	_weather_chip = _chip_button()
	_weather_chip.pressed.connect(_on_weather_pressed)
	_hud.add_child(_weather_chip)
	_pause_button = _chip_button()
	_pause_button.pressed.connect(_toggle_pause)
	_hud.add_child(_pause_button)


func _build_pause_screen() -> void:
	_pause_screen = _overlay()
	add_child(_pause_screen)
	var box := _centered_column(Vector2(360, 280), _pause_screen)
	_pause_title = _label(26, INK)
	_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_pause_title)
	_resume_button = _soft_button()
	_resume_button.pressed.connect(_toggle_pause)
	box.add_child(_resume_button)
	_restart_button = _soft_button()
	_restart_button.pressed.connect(func() -> void: _request_destructive_action("restart"))
	box.add_child(_restart_button)
	_pause_title_button = _soft_button()
	_pause_title_button.pressed.connect(func() -> void: _request_destructive_action("title"))
	box.add_child(_pause_title_button)


func _build_confirmation_screen() -> void:
	_confirm_screen = _overlay()
	add_child(_confirm_screen)
	var box := _centered_column(Vector2(420, 240), _confirm_screen)
	_confirm_title = _label(22, INK)
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_confirm_title)
	_confirm_message = _label(15, MUTED)
	_confirm_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_confirm_message)
	_confirm_accept_button = _soft_button()
	_confirm_accept_button.pressed.connect(_confirm_destructive_action)
	box.add_child(_confirm_accept_button)
	_confirm_cancel_button = _soft_button()
	_confirm_cancel_button.pressed.connect(_cancel_destructive_action)
	box.add_child(_confirm_cancel_button)


func _build_album_screen() -> void:
	_album_screen = _overlay()
	add_child(_album_screen)
	var box := _centered_column(Vector2(860, 560), _album_screen)
	_album_title = _label(24, INK)
	_album_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_album_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 400)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_album_grid = GridContainer.new()
	_album_grid.columns = 3
	_album_grid.add_theme_constant_override("h_separation", 16)
	_album_grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_album_grid)
	_album_back_button = _soft_button()
	_album_back_button.pressed.connect(_hide_album)
	box.add_child(_album_back_button)


func _build_notice() -> void:
	_notice = _label(16, INK)
	_notice.visible = false
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_notice.offset_left = -220
	_notice.offset_right = 220
	_notice.offset_top = -92
	_notice.offset_bottom = -52
	add_child(_notice)


func _start_holiday() -> void:
	TuningStore.begin_run(false)
	AudioDirector.set_game_paused(false)
	_clear_world()
	_world = YardWorldType.new()
	_world_root.add_child(_world)
	_world.setup(SaveStore.get_album())
	_world.album_updated.connect(_on_album_updated)
	_world.notice_requested.connect(_show_notice_key)
	_world.weather_changed.connect(func(_w: String) -> void: _refresh_hud())
	_world.camera_focus_requested.connect(_on_focus)
	_world.camera_release_requested.connect(_on_release_focus)
	_camera.enabled = true
	_cam_zoom = 1.0
	_cam_target_zoom = 1.0
	_cam_offset = Vector2.ZERO
	_cam_target_offset = Vector2.ZERO
	_camera.make_current()
	_screen = "game"
	_title_screen.visible = false
	_paper.visible = false
	_hud.visible = true
	_pause_screen.visible = false
	_confirm_screen.visible = false
	_album_screen.visible = false
	get_tree().paused = false
	_show_notice_key("notice.arrive")
	_refresh_hud()


func _clear_world() -> void:
	if _world != null:
		_world.queue_free()
		_world = null


func _show_title() -> void:
	get_tree().paused = false
	TuningStore.end_run()
	AudioDirector.set_game_paused(false)
	_screen = "title"
	_clear_world()
	_camera.enabled = false
	_paper.visible = true
	_title_screen.visible = true
	_hud.visible = false
	_pause_screen.visible = false
	_confirm_screen.visible = false
	_album_screen.visible = false
	_refresh_texts()


func _toggle_pause() -> void:
	if _screen != "game":
		return
	var paused := not _pause_screen.visible
	_pause_screen.visible = paused
	get_tree().paused = paused
	AudioDirector.set_game_paused(paused)
	if _world != null:
		_world.input_enabled = not paused
	_refresh_texts()


func _request_destructive_action(action: String) -> void:
	_pending_destructive_action = action
	_confirm_screen.visible = true
	_refresh_texts()


func _confirm_destructive_action() -> void:
	var action := _pending_destructive_action
	_pending_destructive_action = ""
	_confirm_screen.visible = false
	if action == "restart":
		_start_holiday()
	elif action == "title":
		_show_title()


func _cancel_destructive_action() -> void:
	_pending_destructive_action = ""
	_confirm_screen.visible = false


func _on_weather_pressed() -> void:
	if _world == null:
		return
	_world.toggle_weather()
	_show_notice_key("notice.weather")


func _on_album_updated(collected: PackedStringArray, latest_id: String) -> void:
	_latest_photo = latest_id
	SaveStore.set_album(collected)
	_show_notice_key("notice.photo")
	_refresh_hud()
	_rebuild_album(collected)


func _show_album() -> void:
	_album_screen.visible = true
	if _world != null:
		_world.input_enabled = false
		_rebuild_album(_world.collected)
	else:
		_rebuild_album(PackedStringArray(SaveStore.get_album()))
	_refresh_texts()


func _hide_album() -> void:
	_album_screen.visible = false
	if _world != null and not _pause_screen.visible:
		_world.input_enabled = true


func _rebuild_album(collected: PackedStringArray) -> void:
	for child in _album_grid.get_children():
		child.queue_free()
	for rule: Dictionary in ExpressionCatalog.RULES:
			if not bool(rule.get("polaroid", false)):
				continue
			var card := _photo_card(rule, str(rule.get("id", "")) in collected)
			_album_grid.add_child(card)


func _photo_card(rule: Dictionary, owned: bool) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(240, 300)
	var frame := TextureRect.new()
	frame.texture = POLAROID
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(frame)
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(28, 28)
	portrait.size = Vector2(184, 184)
	if owned:
		var owner := str(rule.get("owner", "llama"))
		var expression := str(rule.get("expression", "idle"))
		var path := "res://assets/holiday/characters/%s.png" % owner
		if owner == "llama":
			match expression:
				"annoyed":
					path = "res://assets/holiday/characters/llama_annoyed.png"
				"happy":
					path = "res://assets/holiday/characters/llama_happy.png"
				"smirk":
					path = "res://assets/holiday/characters/llama_smirk.png"
		if ResourceLoader.exists(path):
			portrait.texture = load(path)
	else:
		portrait.modulate = Color(1, 1, 1, 0.08)
	holder.add_child(portrait)
	var caption := _label(13, INK if owned else MUTED)
	caption.position = Vector2(24, 232)
	caption.size = Vector2(192, 52)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.text = I18n.t(str(rule.get("title_key", ""))) if owned else I18n.t("album.empty_slot")
	holder.add_child(caption)
	return holder


func _on_focus(world_point: Vector2, zoom: float) -> void:
	_cam_target_zoom = zoom
	_cam_target_offset = (world_point - YardWorld.WORLD_SIZE * 0.5) * 0.35


func _on_release_focus() -> void:
	_cam_target_zoom = 1.0
	_cam_target_offset = Vector2.ZERO


func _screen_to_world(screen: Vector2) -> Vector2:
	var view := get_viewport_rect().size
	var zoom := _camera.zoom
	if zoom.x == 0.0 or zoom.y == 0.0:
		zoom = Vector2.ONE
	return _camera.get_screen_center_position() + (screen - view * 0.5) / zoom


func _show_notice_key(key: String) -> void:
	_notice.text = I18n.t(key)
	_notice.visible = true
	_notice_time = 3.2


func _open_licenses() -> void:
	OpenSourceLicenses.open(self)


func _layout() -> void:
	var pad := 20.0
	if _hint_label:
		_hint_label.position = Vector2(pad, 16.0)
		# 给暂停按钮留出右边，提示整句都留在画面里。
		_hint_label.size = Vector2(maxf(320.0, size.x - 188.0), 72.0)
	if _album_chip:
		_album_chip.position = Vector2(pad, size.y - 68.0)
		_weather_chip.position = Vector2(pad + 210.0, size.y - 68.0)
		_pause_button.position = Vector2(size.x - 132.0, pad)


func _refresh_hud() -> void:
	if _world == null:
		return
	_hud.modulate.a = float(TuningStore.get_value("ui.hud.opacity", 0.94))
	_album_chip.text = I18n.t("hud.album", {"count": str(_world.collected_count()), "total": str(_world.collectible_total())})
	_weather_chip.text = I18n.t("hud.weather.%s" % _world.weather)
	_pause_button.text = I18n.t("hud.pause")
	_hint_label.text = I18n.t("hud.hint")


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _on_tuning_value_changed(_id: String, _requested: Variant, _active: Variant) -> void:
	if _world != null:
		_world._apply_weather_art()
	_refresh_hud()


func _refresh_texts() -> void:
	_title_label.text = I18n.t("app.title")
	_subtitle_label.text = I18n.t("app.subtitle")
	_tagline_label.text = I18n.t("app.tagline")
	_play_button.text = I18n.t("menu.play")
	_album_button.text = I18n.t("menu.album")
	_licenses_button.text = I18n.t("ui.open_source_licenses")
	_title_hint.text = I18n.t("menu.hint")
	_pause_title.text = I18n.t("pause.title")
	_resume_button.text = I18n.t("pause.resume")
	_restart_button.text = I18n.t("pause.restart")
	_pause_title_button.text = I18n.t("pause.main_menu")
	_confirm_title.text = I18n.t("confirm.heading")
	_confirm_message.text = I18n.t("confirm.title" if _pending_destructive_action == "title" else "confirm.restart")
	_confirm_accept_button.text = I18n.t("confirm.accept")
	_confirm_cancel_button.text = I18n.t("confirm.cancel")
	_album_title.text = I18n.t("album.title")
	_album_back_button.text = I18n.t("album.back")
	if _world != null:
		_refresh_hud()


func _label(size_px: int, color: Color) -> Label:
	var result := Label.new()
	result.add_theme_font_size_override("font_size", size_px)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


func _soft_button() -> Button:
	var result := Button.new()
	result.custom_minimum_size = Vector2(260, 44)
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override("font_color", INK)
	result.add_theme_color_override("font_hover_color", Color("3d2d23"))
	result.add_theme_stylebox_override("normal", _flat(CREAM, APRICOT))
	result.add_theme_stylebox_override("hover", _flat(Color("ffe7c8"), SAGE))
	result.add_theme_stylebox_override("pressed", _flat(Color("f3d3ae"), INK))
	result.add_theme_stylebox_override("focus", _flat(CREAM, LAVENDER, 3))
	return result


func _chip_button() -> Button:
	var result := _soft_button()
	result.custom_minimum_size = Vector2(188, 40)
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	return result


func _text_button() -> Button:
	var result := Button.new()
	result.flat = true
	result.add_theme_color_override("font_color", MUTED)
	result.add_theme_font_size_override("font_size", 14)
	return result


func _overlay() -> Control:
	var overlay := Control.new()
	overlay.visible = false
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.35, 0.26, 0.2, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	return overlay


func _paper_panel(min_size: Vector2) -> VBoxContainer:
	return _centered_column(min_size, self)


func _centered_column(min_size: Vector2, parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _flat(PAPER, APRICOT, 2, 22))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -min_size.x * 0.5
	panel.offset_right = min_size.x * 0.5
	panel.offset_top = -min_size.y * 0.5
	panel.offset_bottom = min_size.y * 0.5
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box


func _flat(bg: Color, border: Color, width: int = 2, radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
