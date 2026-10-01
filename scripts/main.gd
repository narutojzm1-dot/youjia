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

# 昼夜渐变覆盖层（CanvasLayer 5，介于世界与 HUD 之间）
const TOD_COLORS := {
	"dawn":    Color(1.0, 0.92, 0.68),  # 晨光：暖金
	"morning": Color(1.0, 0.95, 0.82),  # 早晨：淡金
	"noon":    Color(1.0, 1.0, 0.96),   # 正午：几乎无色
	"afternoon": Color(1.0, 0.80, 0.52), # 下午：暖琥珀
	"evening": Color(0.90, 0.60, 0.42), # 傍晚：桃橙
	"night":   Color(0.52, 0.54, 0.78), # 夜晚：蓝紫
}

# 季节色调（随假期天数推进，叠加在昼夜层下方）
const SEASON_COLORS := {
	"spring":      Color(0.88, 0.97, 0.90),  # 春：淡翠绿
	"summer":      Color(1.00, 1.00, 0.95),  # 夏：几乎无色
	"late_summer": Color(1.00, 0.95, 0.82),  # 仲夏末：暖琥珀
	"autumn":      Color(1.00, 0.90, 0.72),  # 秋：金黄
}

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
var _action_button: Button
var _ui_layer: CanvasLayer
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
var _album_scroll: ScrollContainer
var _album_panel: PanelContainer
var _album_back_button: Button
var _notice: Label
var _notice_time := 0.0
var _notice_key := ""
var _screen := "title"
var _cam_zoom := 1.0
var _cam_target_zoom := 1.0
var _cam_offset := Vector2.ZERO
var _cam_target_offset := Vector2.ZERO
var _latest_photo := ""
var _last_touch_ms := -1000
# 假期天数标签
var _day_label: Label
# 昼夜色调覆盖层
var _tod_canvas: CanvasLayer
var _tod_rect: ColorRect
# 季节底色（渲染在昼夜层之下，随假期天数推进）
var _season_rect: ColorRect
# P1.5: 拍立得入账时短暂亮一次屏，提示照片已捕获。
var _photo_flash: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	I18n.set_locale("zh-CN")
	_build_layers()
	_build_title_screen()
	_build_hud()
	_build_pause_screen()
	_build_confirmation_screen()
	_build_album_screen()
	_build_notice()
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)
	for panel in [_paper,_title_screen,_hud,_pause_screen,_confirm_screen,_album_screen,_notice]:
		panel.reparent(_ui_layer, false)
	# P1.5: 拍立得闪光叠加层加入 _ui_layer，确保渲染在所有 UI 之上。
	_photo_flash = ColorRect.new()
	_photo_flash.color = Color(CREAM, 0.0)
	_photo_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photo_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_photo_flash)
	I18n.locale_changed.connect(_on_locale_changed)
	TuningStore.value_changed.connect(_on_tuning_value_changed)
	resized.connect(_layout)
	_refresh_texts()
	_show_title()
	call_deferred("_layout")
	if OS.has_feature("web"):
		call_deferred("_report_web_first_frame")


func _report_web_first_frame() -> void:
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("window.dispatchEvent(new Event('youjia:first-frame'));", true)


func _process(delta: float) -> void:
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			_notice.visible = false
	_notice.visible = _notice_time > 0.0 and _screen == "game" and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible
	if _screen == "game" and _world != null and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible:
		var move := Vector2.ZERO
		if _world.input_enabled:
			move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_world.tick(delta, move)
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var lerp_rate := 12.0 if reduced else 3.2
	_cam_zoom = lerpf(_cam_zoom, _cam_target_zoom, 1.0 - exp(-delta * lerp_rate))
	_cam_offset = _cam_offset.lerp(_cam_target_offset, 1.0 - exp(-delta * (12.0 if reduced else 3.0)))
	var hud_space := 140.0 if size.x < 700.0 else 76.0
	var fit := minf(size.x/YardWorld.WORLD_SIZE.x,maxf(100.0,size.y-hud_space)/YardWorld.WORLD_SIZE.y)
	var zoom := _cam_zoom * float(TuningStore.get_value("environment.camera.zoom", 1.0)) * fit
	_camera.zoom = Vector2(zoom, zoom)
	_camera.position = YardWorld.WORLD_SIZE * 0.5 + _cam_offset + Vector2(0,hud_space/(2.0*zoom))
	if _screen == "game":
		_refresh_hud()
		# 更新昼夜色调覆盖层与季节底色
		if _world != null:
			_update_tod_tint(_world.tod_fraction())
			_update_season_tint(_world.holiday_day)


func _input(event: InputEvent) -> void:
	# Keyboard controls must also work after a mouse click focused a HUD button.
	if event.is_action_pressed("pause") and not event.is_echo():
		if _confirm_screen.visible:
			_cancel_destructive_action()
		elif _album_screen.visible:
			_hide_album()
		elif _screen == "game":
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _screen == "game" and _world != null and _world.input_enabled and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible:
		if event.is_action_pressed("ui_accept") and not event.is_echo():
			_world.try_interact()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and (event.is_action("move_left") or event.is_action("move_right") or event.is_action("move_up") or event.is_action("move_down")):
			# Arrow keys move the person in the yard, never focus HUD buttons.
			get_viewport().set_input_as_handled()
			return
	# Native browser touch and synthesized mouse must produce exactly one action.
	if event is InputEventMouseButton and Time.get_ticks_msec()-_last_touch_ms < 400:
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventScreenTouch) or not event.pressed:
		return
	var buttons: Array = []
	if _confirm_screen.visible:
		buttons = [_confirm_accept_button,_confirm_cancel_button]
	elif _pause_screen.visible:
		buttons = [_resume_button,_restart_button,_pause_title_button]
	elif _album_screen.visible:
		buttons = [_album_back_button]
	elif _screen == "title":
		buttons = [_play_button,_album_button,_licenses_button]
	else:
		buttons = [_action_button,_album_chip,_weather_chip,_pause_button]
	for button: Button in buttons:
		var local: Vector2 = button.get_global_transform_with_canvas().affine_inverse()*event.position
		if button.is_visible_in_tree() and not button.disabled and Rect2(Vector2.ZERO,button.size).has_point(local):
			_last_touch_ms = Time.get_ticks_msec()
			button.pressed.emit()
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if _screen != "game" or _world == null or not _world.input_enabled:
		return
	if _pause_screen.visible or _album_screen.visible or _confirm_screen.visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		_last_touch_ms = Time.get_ticks_msec()
		_world.request_pointer_action(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Browsers can synthesize a mouse event for the same touch.
		if Time.get_ticks_msec() - _last_touch_ms > 400:
			_world.request_pointer_action(_screen_to_world(event.position))
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
	# 昼夜/季节覆盖层：在世界(0)之上、HUD(10)之下（layer 5）
	_tod_canvas = CanvasLayer.new()
	_tod_canvas.layer = 5
	add_child(_tod_canvas)
	# 季节底色（渲染顺序在昼夜之下，先加入）
	_season_rect = ColorRect.new()
	_season_rect.color = Color(0, 0, 0, 0)
	_season_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_season_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tod_canvas.add_child(_season_rect)
	# 昼夜色调（覆盖在季节之上）
	_tod_rect = ColorRect.new()
	_tod_rect.color = Color(0, 0, 0, 0)
	_tod_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tod_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tod_canvas.add_child(_tod_rect)


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
	# P0.2: MOUSE_FILTER_PASS 确保子控件在 web 导出时可靠收到点击。
	_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hud)
	_hint_label = _label(15, INK)
	_hint_label.position = Vector2(24, 18)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.size = Vector2(520, 70)
	_hud.add_child(_hint_label)
	# 假期天数标签：居中上方
	_day_label = _label(14, MUTED)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.size = Vector2(160, 28)
	_day_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_day_label)
	_album_chip = _chip_button()
	_album_chip.pressed.connect(_show_album)
	# P0.2: tooltip 告知玩家此处可点，辅助鼠标悬停时的发现性。
	_album_chip.tooltip_text = I18n.t("hud.album.tooltip")
	_hud.add_child(_album_chip)
	_weather_chip = _chip_button()
	_weather_chip.pressed.connect(_on_weather_pressed)
	_hud.add_child(_weather_chip)
	_pause_button = _chip_button()
	_pause_button.pressed.connect(_toggle_pause)
	_hud.add_child(_pause_button)
	_action_button = _chip_button()
	# 按下时先触发视觉脉冲，再执行动作，让触控/鼠标点击有明确反馈
	_action_button.pressed.connect(func(): _pulse_button(_action_button); _world.request_primary_action())
	_hud.add_child(_action_button)
	for button: Button in [_album_chip,_weather_chip,_pause_button,_action_button]:
		button.focus_mode = Control.FOCUS_NONE


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
	_album_panel = box.get_parent()
	_album_title = _label(24, INK)
	_album_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_album_title)
	var scroll := ScrollContainer.new()
	_album_scroll = scroll
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
	_world.setup(
		SaveStore.get_album(),
		SaveStore.get_photo_moments(),
		SaveStore.get_holiday_day(),
		SaveStore.get_holiday_day_elapsed(),
		SaveStore.get_plant_state(),
		SaveStore.get_first_fish_caught()
	)
	_world.album_updated.connect(_on_album_updated)
	_world.notice_requested.connect(_show_notice_key)
	_world.notice_dismiss_requested.connect(_dismiss_notice_key)
	_world.weather_changed.connect(func(_w: String) -> void: _refresh_hud())
	_world.camera_focus_requested.connect(_on_focus)
	_world.camera_release_requested.connect(_on_release_focus)
	_world.day_advanced.connect(_on_day_advanced)
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
	# P0.2: HUD 可见后立即重算布局，确保相册按钮落在正确的点击区域。
	_layout()
	_show_notice_key("notice.arrive")
	_refresh_hud()
	# 首次进院（第1天且相册为空）时，延迟发送柔性引导提示，帮助玩家发现活动
	if _world.holiday_day == 1 and SaveStore.get_album().is_empty():
		_show_delayed_soft_hint()


func _clear_world() -> void:
	if _world != null:
		# Preserve the partial day before title/restart replaces this world.
		_world._save_progress()
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
	# 回到标题时清除昼夜叠色与季节底色
	if _tod_rect != null:
		_tod_rect.color = Color(0, 0, 0, 0)
	if _season_rect != null:
		_season_rect.color = Color(0, 0, 0, 0)
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
	var fresh := latest_id not in SaveStore.get_album()
	SaveStore.set_album(collected,_world.photo_moments if _world != null else {})
	if fresh:
		_latest_photo = latest_id
		_show_notice_key("notice.photo")
		# P1.5: 拍立得入账时短暂发白，让玩家明确感知到照片已拍入手帐。
		_flash_photo()
	_refresh_hud()
	if _album_screen.visible: _rebuild_album(collected)


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
		_album_grid.remove_child(child)
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
	var moment := SaveStore.get_photo_moment(str(rule.get("id",""))) if owned else {}
	if owned and not moment.is_empty():
		var photograph := PhotoMoment.new()
		photograph.position = portrait.position
		photograph.size = portrait.size
		photograph.setup(moment)
		holder.add_child(photograph)
		portrait.visible = false
	elif owned:
		var owner := str(rule.get("owner", "llama"))
		var expression := str(rule.get("expression", "idle"))
		var path := CastArt.texture_path(owner,expression)
		if ResourceLoader.exists(path):
			portrait.texture = load(path)
			if owner=="llama" and ResourceLoader.exists(CastArt.DIRECTORY+"llama_smirk.png"):
				portrait.texture=load(CastArt.DIRECTORY+"llama_smirk.png")
				var material:=ShaderMaterial.new()
				material.shader=preload("res://shaders/felt_walk.gdshader")
				material.set_shader_parameter("face_override",true)
				material.set_shader_parameter("expression_texture",load(path))
				material.set_shader_parameter("face_region",Vector4(805.0/1254,225.0/1254,225.0/1254,160.0/1254))
				portrait.material=material
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
	return get_viewport().get_canvas_transform().affine_inverse() * screen


func _dismiss_notice_key(key: String) -> void:
	if _notice_key == key:
		_notice_time = 0.0
		_notice.visible = false


func _show_notice_key(key: String) -> void:
	_notice_key = key
	_notice.text = I18n.t(key)
	_notice.visible = true
	_notice_time = 3.2


func _open_licenses() -> void:
	OpenSourceLicenses.open(self)


# P1.5: 触发拍立得入账的短暂亮屏动画：快速淡入奶油白，再慢慢消散。
func _flash_photo() -> void:
	if _photo_flash == null:
		return
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		return
	_photo_flash.color.a = 0.0
	var tween := create_tween()
	tween.tween_property(_photo_flash, "color:a", 0.46, 0.08)
	tween.tween_property(_photo_flash, "color:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _layout() -> void:
	var pad := 20.0
	if _album_chip == null: return
	var compact := size.x < 700.0
	var title_column: Control = _title_label.get_parent()
	var title_width := minf(480.0,size.x-40.0)
	title_column.offset_left = -title_width*0.5
	title_column.offset_right = title_width*0.5
	title_column.offset_top = -(size.y-40.0)*0.5
	title_column.offset_bottom = (size.y-40.0)*0.5
	title_column.add_theme_constant_override("separation",8 if size.y<500 else 14)
	_title_label.add_theme_font_size_override("font_size",28 if size.y<500 else 40)
	_tagline_label.add_theme_font_size_override("font_size",14 if size.y<500 else 16)
	_title_hint.add_theme_font_size_override("font_size",12 if size.y<500 else 14)
	var album_width := minf(860.0,size.x-32.0)
	var album_height := minf(560.0,size.y-32.0)
	_album_panel.custom_minimum_size = Vector2(album_width,album_height)
	_album_panel.offset_left = -album_width*0.5
	_album_panel.offset_right = album_width*0.5
	_album_panel.offset_top = -album_height*0.5
	_album_panel.offset_bottom = album_height*0.5
	_album_scroll.custom_minimum_size = Vector2(album_width-40.0,maxf(80.0,album_height-150.0))
	_album_grid.columns = maxi(1,floori((album_width-40.0)/256.0))
	_notice.offset_left = -minf(220,size.x*0.5-20)
	_notice.offset_right = minf(220,size.x*0.5-20)
	_notice.offset_top = -170 if compact else -110
	_notice.offset_bottom = -130 if compact else -70
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var half := maxf(100.0,(size.x-pad*3.0)*0.5)
	var chip_width := half if compact else 188.0
	for button in [_album_chip,_weather_chip]:
		button.custom_minimum_size = Vector2(chip_width,48)
		button.size = Vector2(chip_width,48)
	_action_button.custom_minimum_size = Vector2(size.x-pad*2.0 if compact else 188.0,48)
	_action_button.size = _action_button.custom_minimum_size
	_pause_button.custom_minimum_size = Vector2(120.0 if compact else 188.0,48)
	_pause_button.size = _pause_button.custom_minimum_size
	_pause_button.position = Vector2(size.x-_pause_button.size.x-pad,pad)
	_hint_label.position = Vector2(pad,16)
	_hint_label.size = Vector2(maxf(120.0,size.x-_pause_button.size.x-pad*3.0),72)
	# 天数标签居中顶部
	if _day_label != null:
		_day_label.size = Vector2(160, 28)
		_day_label.position = Vector2(size.x * 0.5 - 80.0, pad)
	var row := size.y-124.0 if compact else size.y-68.0
	_album_chip.position = Vector2(pad,row)
	_weather_chip.position = Vector2(size.x-half-pad if compact else pad+210.0,row)
	_action_button.position = Vector2(pad if compact else size.x-_action_button.size.x-pad,size.y-68.0)


func _refresh_hud() -> void:
	if _world == null:
		return
	_hud.modulate.a = float(TuningStore.get_value("ui.hud.opacity", 0.94))
	_album_chip.text = I18n.t("hud.album", {"count": str(_world.collected_count()), "total": str(_world.collectible_total())})
	_weather_chip.text = I18n.t("hud.weather.%s" % _world.weather)
	_pause_button.text = I18n.t("hud.pause")
	# 上下文提示：牵行/持草时使用高优先级提示，其余情况由 hint_context() 根据位置决定
	_hint_label.text = I18n.t(_world.hint_context())
	_action_button.text = I18n.t(_world.primary_action_key())
	# 更新假期天数标签
	if _day_label != null:
		_day_label.text = I18n.t("hud.day", {"n": str(_world.holiday_day)})


func _on_day_advanced(_day: int) -> void:
	# 翻天时刷新 HUD（天数已在 _world.holiday_day 中更新）
	_refresh_hud()


## 第1天进院且相册为空时，延迟 4.5 秒发送柔性引导提示（淡出后已看不到 arrive 通知）
func _show_delayed_soft_hint() -> void:
	await get_tree().create_timer(4.5).timeout
	if _screen != "game" or _world == null:
		return
	_show_notice_key("notice.first_hint")


## 行动按钮按下时触发短暂视觉脉冲：暖光闪亮再消散，给触控/鼠标点击明确反馈
func _pulse_button(btn: Button) -> void:
	if btn == null:
		return
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		return
	var tween := create_tween()
	tween.tween_property(btn, "modulate", Color(1.35, 1.10, 0.88, 1.0), 0.07).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 根据假期天数计算并应用季节底色（叠加在昼夜层之下）
## 天数越大，色调从春绿→夏白→仲夏琥珀→秋金，alpha 极低，保持视觉干净
func _update_season_tint(day: int) -> void:
	if _season_rect == null:
		return
	var sc: Color
	var alpha: float
	if day <= 3:
		# 第 1-3 天：春意，淡翠绿渐现
		sc = SEASON_COLORS.spring
		alpha = lerpf(0.0, 0.04, float(day - 1) / 2.0)
	elif day <= 7:
		# 第 4-7 天：盛夏，近乎无色
		sc = SEASON_COLORS.summer
		alpha = 0.01
	elif day <= 12:
		# 第 8-12 天：仲夏末，暖琥珀渐浓
		sc = SEASON_COLORS.late_summer
		alpha = lerpf(0.02, 0.05, float(day - 8) / 4.0)
	else:
		# 第 13 天起：金秋，上限 0.08
		sc = SEASON_COLORS.autumn
		alpha = minf(0.08, 0.05 + float(day - 13) * 0.005)
	_season_rect.color = Color(sc.r, sc.g, sc.b, alpha)


## 根据 tod_fraction (0.0-1.0) 计算并应用昼夜渐变覆盖色
## 0.0 = 日出, 0.5 = 正午, 0.85 = 黄昏, 1.0 = 深夜
func _update_tod_tint(t: float) -> void:
	if _tod_rect == null:
		return
	var base_color: Color
	var alpha: float
	if t < 0.10:
		# 日出：金橙暖光
		base_color = TOD_COLORS.dawn
		alpha = lerpf(0.08, 0.05, t / 0.10)
	elif t < 0.25:
		# 早晨：淡金渐隐
		base_color = TOD_COLORS.morning
		alpha = lerpf(0.05, 0.01, (t - 0.10) / 0.15)
	elif t < 0.55:
		# 正午：几乎无色
		base_color = TOD_COLORS.noon
		alpha = 0.0
	elif t < 0.72:
		# 下午：暖琥珀渐强
		base_color = TOD_COLORS.afternoon
		alpha = lerpf(0.0, 0.09, (t - 0.55) / 0.17)
	elif t < 0.87:
		# 傍晚/黄昏：桃橙
		var frac := (t - 0.72) / 0.15
		base_color = TOD_COLORS.afternoon.lerp(TOD_COLORS.evening, frac)
		alpha = lerpf(0.09, 0.16, frac)
	else:
		# 夜晚：蓝紫
		var frac := (t - 0.87) / 0.13
		base_color = TOD_COLORS.evening.lerp(TOD_COLORS.night, frac)
		alpha = lerpf(0.16, 0.22, frac)
	_tod_rect.color = Color(base_color.r, base_color.g, base_color.b, alpha)


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
	# P0.2: locale 切换时同步更新相册 tooltip。
	if _album_chip != null:
		_album_chip.tooltip_text = I18n.t("hud.album.tooltip")
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
