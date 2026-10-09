extends Control
const OpenSourceLicenses = preload("res://scripts/manus/open_source_licenses.gd")
const YardWorldType := preload("res://scripts/game/yard_world.gd")
const TITLE_PAPER := preload("res://assets/holiday/ui/scrapbook_paper.png")
const POLAROID := preload("res://assets/holiday/ui/polaroid_frame.png")
## REQ-20261007-048 album polaroid caption, in 240×300 card units. RECT is the
## original box; STRIP is the frame's whole bottom paper strip (PhotoArrival).
const ALBUM_CAPTION_RECT := Rect2(24, 232, 192, 52)
const ALBUM_CAPTION_STRIP := Rect2(24, 227, 192, 56)
const ALBUM_CAPTION_MIN_FONT_SIZE := 12
const ALBUM_CAPTION_TIGHT_LINE_SPACING := 0
const ALBUM_CAPTION_BALANCE_MIN_WIDTH := 96.0
const ALBUM_CAPTION_BALANCE_SLACK := 2.0

const PAPER := Color("fff6e8")
const INK := Color("5b4637")
const MUTED := Color("8a7060")
const APRICOT := Color("f3b27a")
## 标题页副标题用的深杏色：在 PAPER 上对比约 4.6:1（APRICOT 只有约 1.7:1），#REQ-20261005-028
const TITLE_ACCENT := Color("a85d28")
const TEXT_LINK := Color("6b5242")
const TEXT_LINK_HOVER := Color("3d2d23")
## 目标纸片里文字区的最小高度：纸面最少 48px，与「歇一会儿」按钮同高（REQ-20261005-029）
const HINT_MIN_TEXT_HEIGHT := 32.0
## 「现在离开吗？」确认纸片的设计尺寸；屏幕更窄/更矮时按 _fit_confirm_panel() 收进屏内（REQ-20261005-030）。
const CONFIRM_PANEL_SIZE := Vector2(420, 240)
## 确认纸片两颗按钮的设计宽度（与 _soft_button 默认一致）；纸片内宽更窄时才收窄（REQ-20261007-052）。
const CONFIRM_BUTTON_WIDTH := 260.0
## 屏高不超过这个值时（手机横屏扣掉浏览器地址栏、568×320 等）标题页改用更紧的排版（REQ-20261005-031）。
const TITLE_TIGHT_MAX_HEIGHT := 360.0
const ALBUM_TIGHT_MAX_HEIGHT := 360.0
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
	"night":   Color(0.26, 0.34, 0.55), # 月下冷光；乘色保留原画明暗与细节
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
var _path_rain: Node2D
var _exploration: ExplorationDirector
var _camera: Camera2D
var _title_screen: Control
var _title_card: Panel
var _title_label: Label
var _subtitle_label: Label
var _tagline_label: Label
var _play_button: Button
var _album_button: Button
var _licenses_button: Button
var _title_hint: Label
var _hud: Control
var _hint_panel: Panel
var _hint_label: Label
var _album_chip: Button
var _weather_chip: Button
var _basket_chip: Button
var _basket_panel: Control
var _hold_hotbar: Control
var _residents: RefCounted
var _inventory: RefCounted
var _decor: RefCounted
var _basket_drop: Dictionary = {}
var _decor_panel: Control
var _decor_camera: Dictionary = {}
var _inventory_food_consumer := ""
var _pause_button: Button
var _action_button: Button
var _ui_layer: CanvasLayer
var _pause_screen: Control
var _pause_panel: PanelContainer
var _pause_box: VBoxContainer
var _pause_columns: HBoxContainer
var _pause_session: VBoxContainer
var _pause_audio: VBoxContainer
var _pause_title: Label
var _resume_button: Button
var _restart_button: Button
var _pause_title_button: Button
var _music_toggle: Button
var _ambience_toggle: Button
var _mute_toggle: Button
var _music_volume_label: Label
var _ambience_volume_label: Label
var _music_slider: HSlider
var _ambience_slider: HSlider
var _music_toggle_frame := -1
var _ambience_toggle_frame := -1
var _confirm_screen: Control
var _confirm_panel: PanelContainer
var _confirm_title: Label
var _confirm_message: Label
var _confirm_accept_button: Button
var _confirm_cancel_button: Button
var _pending_destructive_action := ""
var _album_screen: Control
var _album_title: Label
var _album_panel: PanelContainer
var _album_spread: HBoxContainer
var _album_previous_button: Button
var _album_next_button: Button
var _album_back_button: Button
var _album_entries := PackedStringArray()
var _album_index := 0
var _album_two_pages := true
var _album_page_size := Vector2(380, 420)
var _album_touch_origin := Vector2.INF
var _notice: Label
var _notice_time := 0.0
var _notice_key := ""
var _screen := "title"
var _portrait_camera_x := 640.0
var _cam_zoom := 1.0
var _cam_target_zoom := 1.0
var _cam_offset := Vector2.ZERO
var _cam_target_offset := Vector2.ZERO
# Quiet framing owns this guard through its release tween, until another focus.
var _cam_quiet_bounds := false
var _cam_effective_offset := Vector2.ZERO
var _latest_photo := ""
var _last_touch_ms := -1000
var _volume_touch_index := -1
var _volume_touch_slider: HSlider
# 假期天数标签
var _day_label: Label
# 昼夜色调覆盖层
var _tod_canvas: CanvasLayer
var _house_lights_overlay: Node2D
var _tod_rect: ColorRect
# 季节底色（渲染在昼夜层之下，随假期天数推进）
var _season_rect: ColorRect
# 拍立得入账时短暂亮一次屏，提示照片已捕获。
var _photo_flash: ColorRect
var _photo_arrival: PhotoArrival
var _photo_arrival_queue: Array[Dictionary] = []
var _pending_photo_saves: Dictionary = {}
var _save_transition := false
var _holiday_start_pending := false
var _save_problems: Dictionary = {}
var _save_exploration_scopes: Dictionary = {}
var _save_exploration_coverage: Dictionary = {}
var _save_exploration_sequence := 0
var _save_durable_ops: Dictionary = {}
var _save_problem_revision := 0
var _save_untracked_problem := false
var _save_untracked_revision := 0
var _save_retry_coverage: Dictionary = {}
var _save_ack_coverage: Dictionary = {}
var _save_problem_active := false
var _save_status_panel: PanelContainer
var _save_retry_button: Button
var _save_status_box: BoxContainer
var _save_status_message: Label
## 钓到鱼时的蓝色庆祝闪光（独立于拍立得闪光，更冷更蓝）
var _fish_flash: ColorRect
var _cinematic_layer: CanvasLayer
var _cinematic_shade: ColorRect
var _cinematic_top_bar: ColorRect
var _cinematic_bottom_bar: ColorRect
## 空闲引导提示计时器：玩家无操作一定时间后轮播软提示
var _idle_hint_timer := 0.0
## 下一条软提示的索引（轮询 IDLE_HINTS 数组）
var _idle_hint_index := 0
## 玩家进院后是否已给过第一条引导提示
var _first_hint_shown := false
## 轮播软提示列表（引导玩家发现各活动）
const IDLE_HINTS := [
	"notice.hint.go_fish",
	"notice.hint.go_pet",
	"notice.hint.go_plant",
	"notice.hint.go_grass",
	"notice.hint.go_explore",
]
## TOD 变化追踪，用于在日段切换时显示氛围通知
var _last_tod_phase := ""

func _build_legacy_review() -> void:
	var panel := PanelContainer.new()
	panel.name = "LegacySaveReview"
	panel.add_theme_stylebox_override("panel", _flat(PAPER, PAPER, 0, 0))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var center := CenterContainer.new()
	panel.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 300
	center.add_child(box)
	var message := _label(16, INK)
	message.text = "另一份游玩进度有变化\n或暂时无法读取\n\n两份内容都保留着\n继续时使用这里的当前进度"
	message.custom_minimum_size = Vector2(300, 90)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(message)
	var export_button := _soft_button()
	export_button.text = "下载两份备份"
	box.add_child(export_button)
	var continue_button := _soft_button()
	continue_button.text = "继续当前进度"
	box.add_child(continue_button)
	export_button.pressed.connect(func():
		export_button.disabled = true
		continue_button.disabled = true
		if not SaveStore.export_recovery():
			message.text = "暂时无法导出。请保留此页面，稍后再试。"
			export_button.disabled = false
			continue_button.disabled = false)
	SaveStore.recovery_exported.connect(func(status: String, bytes: PackedByteArray):
		if not is_instance_valid(panel): return
		export_button.disabled = false
		continue_button.disabled = false
		if bytes.is_empty():
			message.text = "暂时无法导出。原有内容仍保留，请稍后再试。"
			return
		JavaScriptBridge.download_buffer(bytes, "youjia-save-backup.json", "application/json")
		message.text = "备份已交给浏览器下载。" if status != "unavailable" else "可读取的内容已交给浏览器下载。另一份仍无法完整读取，原件已保留。")
	continue_button.pressed.connect(func():
		continue_button.disabled = true
		export_button.disabled = true
		if await SaveStore.continue_current_save():
			panel.queue_free()
			_ready()
		else:
			message.text = "当前保存尚未确认，请保留此页面，稍后再试。"
			continue_button.disabled = false
			export_button.disabled = false)
	if OS.has_feature("web"):
		# This is a usable recovery screen, not a blank/default game fallback.
		JavaScriptBridge.eval("window.dispatchEvent(new Event('youjia:first-frame'));", true)


func _ready() -> void:
	# Do not construct playable state from defaults while Web recovery is pending.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_process_unhandled_input(false)
	if not SaveStore.is_initialized():
		await SaveStore.initialized
	if not SaveStore.can_play():
		if SaveStore.needs_legacy_review():
			_build_legacy_review()
		elif not OS.has_feature("web"):
			var warning := Label.new()
			warning.text = "原来的存档暂时无法确认，文件已保留。请关闭游戏后检查存档。"
			warning.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(warning)
		return
	SaveStore.commit_confirmed.connect(_on_save_confirmed)
	SaveStore.exploration_intent_accepted.connect(_on_exploration_save_accepted)
	SaveStore.commit_rejected.connect(_on_save_rejected)
	SaveStore.commit_unknown.connect(_on_save_problem)
	SaveStore.persistence_state_changed.connect(_on_save_state_changed)
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
	# 拍立得闪光叠加层加入 _ui_layer，确保渲染在所有 UI 之上。
	_photo_flash = ColorRect.new()
	_photo_flash.color = Color(CREAM, 0.0)
	_photo_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photo_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_photo_flash)
	# 钓到鱼的蓝色庆祝闪光层（渲染在拍立得闪光之上）
	_fish_flash = ColorRect.new()
	_fish_flash.color = Color(0.42, 0.75, 0.92, 0.0)
	_fish_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fish_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(_fish_flash)
	_cinematic_layer = CanvasLayer.new()
	_cinematic_layer.layer = 9
	add_child(_cinematic_layer)
	_cinematic_shade = ColorRect.new()
	_cinematic_shade.color = Color(0.035, 0.045, 0.055, 0.0)
	_cinematic_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinematic_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cinematic_layer.add_child(_cinematic_shade)
	_cinematic_top_bar = ColorRect.new()
	_cinematic_top_bar.color = Color(0.025, 0.025, 0.025, 0.0)
	_cinematic_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinematic_top_bar.anchor_right = 1.0
	_cinematic_top_bar.offset_bottom = 0.0
	_cinematic_layer.add_child(_cinematic_top_bar)
	_cinematic_bottom_bar = ColorRect.new()
	_cinematic_bottom_bar.color = Color(0.025, 0.025, 0.025, 0.0)
	_cinematic_bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cinematic_bottom_bar.anchor_top = 1.0
	_cinematic_bottom_bar.anchor_right = 1.0
	_cinematic_bottom_bar.offset_top = 0.0
	_cinematic_layer.add_child(_cinematic_bottom_bar)
	_photo_arrival = PhotoArrival.new()
	_photo_arrival.name = "PhotoArrival"
	_ui_layer.add_child(_photo_arrival)
	_photo_arrival.tucked_away.connect(_on_photo_tucked)
	_exploration = ExplorationDirector.new()
	_exploration.name = "Exploration"
	add_child(_exploration)
	_exploration.entered.connect(_on_exploration_entered)
	_exploration.returned.connect(_on_exploration_returned)
	_exploration.notice.connect(func(key: String) -> void:
		if _screen == "game": _show_notice_key(key, _exploration.last_params))
	_exploration.cleanup_resubmitted.connect(_on_exploration_cleanup_resubmitted)
	_residents = load("res://scripts/game/world_residents_controller.gd").new(SaveStore)
	_residents.changed.connect(_on_residents_changed)
	_residents.resubmitted.connect(_on_residents_resubmitted)
	_exploration.residents = _residents
	_inventory = load("res://scripts/inventory/yard_inventory_controller.gd").new(SaveStore)
	_inventory.changed.connect(_on_inventory_changed)
	_inventory.settled.connect(_on_inventory_settled)
	_inventory.resubmitted.connect(_on_inventory_resubmitted)
	_basket_panel = load("res://scripts/ui/yard_basket_panel.gd").new()
	_basket_panel.name = "YardBasket"
	_ui_layer.add_child(_basket_panel)
	_basket_panel.visible = false
	_basket_panel.close_requested.connect(_hide_basket)
	_basket_panel.action_requested.connect(func(action: String, fish: String) -> void: _inventory.request(action, fish))
	_basket_panel.retry_requested.connect(func() -> void: _inventory.retry())
	_decor = load("res://scripts/inventory/yard_decor_controller.gd").new(SaveStore)
	_decor.changed.connect(_on_decor_changed)
	_decor.resubmitted.connect(_on_decor_resubmitted)
	_decor_panel = load("res://scripts/ui/yard_decor_panel.gd").new()
	_ui_layer.add_child(_decor_panel)
	_decor_panel.visible = false
	_decor_panel.close_requested.connect(_hide_decor)
	_decor_panel.action_requested.connect(func(action: String, spot: String, details: Dictionary) -> void: _decor.request(action, spot, details))
	_decor_panel.retry_requested.connect(func() -> void: _decor.retry())
	_decor_panel.preview_changed.connect(func(spot: String, entry: Dictionary) -> void:
		if _world != null and _decor_panel.visible: _world.decor_view.show_preview(spot, entry))
	var decor_button: Button = _basket_panel._button()
	decor_button.text = "把小物摆在院里"
	decor_button.pressed.connect(_show_decor)
	_basket_panel.rows.add_child(decor_button)
	_basket_panel.decor_button = decor_button
	_basket_panel.place_requested.connect(_place_from_basket)
	_ensure_hold_hotbar()
	I18n.locale_changed.connect(_on_locale_changed)
	TuningStore.value_changed.connect(_on_tuning_value_changed)
	resized.connect(_layout)
	_build_save_status()
	_refresh_texts()
	_show_title()
	set_process(true)
	set_process_unhandled_input(true)
	call_deferred("_layout")
	if OS.has_feature("web"):
		call_deferred("_report_web_first_frame")


func _report_web_first_frame() -> void:
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("window.dispatchEvent(new Event('youjia:first-frame'));", true)


func _process(delta: float) -> void:
	if _decor_panel != null and _decor_panel.visible:
		var preview_area: Rect2 = _decor_panel.preview_rect()
		var zoom := clampf(minf(preview_area.size.x / 260.0, preview_area.size.y / 170.0), 0.2, 1.6)
		_camera.zoom = Vector2.ONE * zoom
		var focus: Vector2 = preload("res://scripts/inventory/yard_decor.gd").SPOTS[_decor_panel.selected]
		_camera.position = focus + (get_viewport_rect().size * 0.5 - preview_area.get_center()) / zoom
		_camera.force_update_scroll()
		return
	if _notice_time > 0.0 and _can_show_notice():
		_notice_time = maxf(0.0, _notice_time - delta)
	_sync_notice_visibility()
	if _notice.visible:
		_fit_notice()
	if _screen == "game" and _world != null and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible and not _basket_panel.visible and not _save_problem_active:
		var move := Vector2.ZERO
		if _world.input_enabled:
			move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_world.tick(delta, move)
		_exploration.idle_tick(delta)
	elif _screen == "exploring" and _world != null and not _pause_screen.visible and not _confirm_screen.visible and not _save_problem_active:
		_world.advance_world_time(delta)
		_sync_path_rain(delta)
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var lerp_rate := 12.0 if reduced else 3.2
	_cam_zoom = lerpf(_cam_zoom, _cam_target_zoom, 1.0 - exp(-delta * lerp_rate))
	_cam_offset = _cam_offset.lerp(_cam_target_offset, 1.0 - exp(-delta * (12.0 if reduced else 3.0)))
	var hud_space := 140.0 if size.x < 700.0 else 76.0
	# Fill the playable frame in both orientations; crop surplus painted sky
	# instead of shrinking the entire yard into a paper-bordered rectangle.
	var fit := maxf(size.x/YardWorld.WORLD_SIZE.x,maxf(100.0,size.y-hud_space)/YardWorld.WORLD_SIZE.y)
	var portrait := size.x < 700.0 and size.y > size.x
	if portrait:
		# Fill the playable height and follow the resident across the panorama.
		fit = maxf(size.x/YardWorld.WORLD_SIZE.x, maxf(100.0,size.y-hud_space)/YardWorld.WORLD_SIZE.y)
	var zoom := _cam_zoom * float(TuningStore.get_value("environment.camera.zoom", 1.0)) * fit
	_camera.zoom = Vector2(zoom, zoom)
	# 轻微玩家跟随：相机中心向玩家位置偏移约 8%，给院子更大的空间感
	## 仅在非焦点缩放时生效；焦点镜头已通过 _cam_target_offset 指定目标
	var player_follow := Vector2.ZERO
	if _world != null and _world.get_player() != null and _cam_target_zoom <= 1.05:
		var pp := _world.get_player().position
		player_follow = (pp - YardWorld.WORLD_SIZE * 0.5) * 0.08
	var home := YardWorld.WORLD_SIZE * 0.5
	if portrait and _world != null and _world.get_player() != null:
		if _cam_target_zoom <= 1.05:
			var half_width := size.x / (2.0 * zoom)
			var target_x := clampf(_world.get_player().position.x, half_width, YardWorld.WORLD_SIZE.x - half_width)
			_portrait_camera_x = lerpf(_portrait_camera_x, target_x, 1.0 - exp(-delta * 5.0))
		home.x = _portrait_camera_x
		player_follow = Vector2.ZERO
	var camera_home := home + player_follow + Vector2(0, hud_space / (2.0 * zoom))
	if _world != null:
		camera_home = _cover_yard_frame(camera_home, _world.get_backdrop_bounds(), size, zoom, hud_space)
	if _cam_quiet_bounds and _cam_target_offset.is_zero_approx() and _cam_offset.length_squared() < 0.0001:
		_cam_offset = Vector2.ZERO
		_cam_quiet_bounds = false
	var camera_position := camera_home + _cam_offset
	if _cam_quiet_bounds and _world != null:
		camera_position = _bound_quiet_camera(camera_position, camera_home, _world.get_backdrop_bounds(), size, zoom, hud_space)
	_camera.position = camera_position
	_cam_effective_offset = camera_position - camera_home
	if _house_lights_overlay != null:
		_house_lights_overlay.visible = _screen == "game" and _world != null
		if _house_lights_overlay.visible:
			_house_lights_overlay.transform = _world.get_global_transform_with_canvas()
			_house_lights_overlay.lights = _world.house.lights
			_house_lights_overlay.queue_redraw()
	# Both regional scenes share the clock and the same painted-light overlay.
	if _screen in ["game", "exploring"] and _world != null:
		_update_tod_tint(_world.tod_fraction())
		_update_season_tint(_world.holiday_day)
	if _screen == "game":
		_refresh_hud()
		# 更新昼夜色调覆盖层与季节底色
		if _world != null:
			var tod := _world.tod_fraction()
			# 空闲提示轮播：初次 55s 后，每 75s 给一条软引导
			## playtest #3 修复：原版通知 3.2s/16px 太短太小；现在等待活跃通知结束后再显示
			if not _pause_screen.visible and not _album_screen.visible:
				_idle_hint_timer -= delta
				if _idle_hint_timer <= 0.0:
					if _notice_time <= 0.5:
						# 没有活跃通知，立刻显示空闲提示
						_idle_hint_timer = 75.0
						_show_idle_hint()
					else:
						# 有活跃通知（如 TOD 切换），延迟 6 秒重试，避免覆盖
						_idle_hint_timer = 6.0
			# 追踪昼夜相位变化，切换时显示氛围文字
			var phase := _tod_phase_name(tod)
			if phase != _last_tod_phase and not _last_tod_phase.is_empty():
				var key := "notice.tod.%s" % phase
				if I18n.has_key(key):
					_show_notice_key(key)
			_last_tod_phase = phase


func _input(event: InputEvent) -> void:
	if _decor_panel != null and _decor_panel.visible:
		if event.is_action_pressed("pause") and not event.is_echo():
			_hide_decor()
			get_viewport().set_input_as_handled()
		elif _decor_ground_recall(event):
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch or event is InputEventScreenDrag:
			_last_touch_ms = Time.get_ticks_msec()
			_decor_panel.handle_touch_event(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and Time.get_ticks_msec() - _last_touch_ms < 400:
			get_viewport().set_input_as_handled()
		return
	if _basket_panel != null and _basket_panel.visible:
		if event.is_action_pressed("pause") and not event.is_echo():
			_hide_basket()
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch or event is InputEventScreenDrag:
			_last_touch_ms = Time.get_ticks_msec()
			_basket_panel.handle_touch_event(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and Time.get_ticks_msec() - _last_touch_ms < 400:
			get_viewport().set_input_as_handled()
		return
	var gesture := false
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		gesture = event.pressed
	elif event is InputEventKey:
		gesture = event.pressed and not event.is_echo()
	if gesture:
		AudioDirector.note_gesture()
	# A captured print is never a modal: the next ordinary player input both
	# dismisses its presentation and continues to its original destination.
	if _photo_arrival != null and _photo_arrival.visible and (
		(event is InputEventMouseButton and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
		or (event is InputEventKey and event.pressed and not event.is_echo())):
		_cancel_photo_arrivals()
	# Keyboard controls must also work after a mouse click focused a HUD button.
	if event.is_action_pressed("pause") and not event.is_echo():
		if _confirm_screen.visible:
			_cancel_destructive_action()
		elif _album_screen.visible:
			_hide_album()
		elif _screen in ["game", "exploring"]:
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if _album_screen.visible:
		if event is InputEventKey and event.pressed and not event.is_echo():
			if event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT:
				_flip_album(-1 if event.keycode == KEY_LEFT else 1)
				get_viewport().set_input_as_handled()
				return
		if event is InputEventScreenTouch:
			if event.pressed:
				_album_touch_origin = event.position
			elif _album_touch_origin != Vector2.INF:
				var sweep: Vector2 = event.position - _album_touch_origin
				_album_touch_origin = Vector2.INF
				if absf(sweep.x) > 78.0 and absf(sweep.y) < 100.0:
					_flip_album(-1 if sweep.x > 0.0 else 1)
					get_viewport().set_input_as_handled()
					return
	if _screen == "game" and _world != null and _world.input_enabled and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible:
		if event.is_action_pressed("ui_accept") and not event.is_echo():
			# 键盘 Space/Enter 触发动作时同步触发行动按钮视觉脉冲，保持键盘与触控体验一致
			_pulse_button(_action_button)
			_world.try_interact()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and (event.is_action("move_left") or event.is_action("move_right") or event.is_action("move_up") or event.is_action("move_down")):
			# Arrow keys move the person in the yard, never focus HUD buttons.
			get_viewport().set_input_as_handled()
			return
	if _handle_volume_touch(event):
		_last_touch_ms = Time.get_ticks_msec()
		get_viewport().set_input_as_handled()
		return
	# 触屏/鼠标同源去重：触屏处理后，400ms 内合成鼠标左键直接吞掉，防止重复触发
	if event is InputEventMouseButton:
		var _mb := event as InputEventMouseButton
		if _mb.button_index == MOUSE_BUTTON_LEFT and _mb.pressed and Time.get_ticks_msec() - _last_touch_ms < 400:
			get_viewport().set_input_as_handled()
			return
	# 触屏 pressed：覆盖所有界面（标题/暂停/相册/游戏）的按钮命中测试
	# 游戏 HUD 鼠标左键：focus_mode=NONE 按钮在 web 导出中 GUI 路由不可靠，需手动命中
	# 标题/暂停/相册界面鼠标：保留 Godot 内置 GUI 行为（FOCUS_ALL 按钮不干预）
	var is_touch_press := event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed
	var _in_game_hud := (_screen == "game" and not _pause_screen.visible
		and not _album_screen.visible and not _confirm_screen.visible)
	var is_mouse_press := (_in_game_hud
		and event is InputEventMouseButton
		and (event as InputEventMouseButton).pressed
		and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT)
	if not is_touch_press and not is_mouse_press:
		return
	var event_pos: Vector2 = (event as InputEventMouseButton).position if is_mouse_press else (event as InputEventScreenTouch).position
	var buttons: Array = []
	if _confirm_screen.visible:
		buttons = [_confirm_accept_button, _confirm_cancel_button]
	elif _pause_screen.visible:
		buttons = [_resume_button, _restart_button, _pause_title_button, _music_toggle, _ambience_toggle, _mute_toggle]
	elif _album_screen.visible:
		buttons = [_album_previous_button, _album_next_button, _album_back_button]
	elif _screen == "title":
		buttons = [_play_button, _album_button, _licenses_button]
	else:
		buttons = [_action_button, _album_chip, _weather_chip, _basket_chip, _pause_button]
	# get_global_rect() 在 web 导出的 CanvasLayer 中比 get_global_transform_with_canvas() 更可靠
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(event_pos):
			_last_touch_ms = Time.get_ticks_msec()
			# An emulated mouse press can already hold the native GUI button.
			# Let its release complete the pause/modal action once. Hiding the
			# overlay from a second manual emission can interrupt GUI visibility.
			if not (is_touch_press and button in [_music_toggle, _ambience_toggle, _mute_toggle, _resume_button, _restart_button, _pause_title_button, _confirm_accept_button, _confirm_cancel_button] and button.is_pressed()):
				button.pressed.emit()
			get_viewport().set_input_as_handled()
			return
	# 手持快捷栏触屏命中（与背篓格子同思路；不依赖 GUI 路由）
	if _in_game_hud and _hold_hotbar != null and _hold_hotbar.visible:
		if _hold_hotbar.press_at(event_pos):
			_last_touch_ms = Time.get_ticks_msec()
			get_viewport().set_input_as_handled()
			return
	# 触屏点到空白处：更新时间戳，交给 _unhandled_input 处理世界点击
	if is_touch_press:
		_last_touch_ms = Time.get_ticks_msec()


func _unhandled_input(event: InputEvent) -> void:
	if _screen != "game" or _world == null or not _world.input_enabled:
		return
	if _pause_screen.visible or _album_screen.visible or _confirm_screen.visible:
		return
	if _basket_panel != null and _basket_panel.visible:
		return
	if _decor_panel != null and _decor_panel.visible:
		return
	# 触屏和鼠标世界点击：触屏已在 _input() 中更新 _last_touch_ms，此处只处理
	# 真正落到世界画布上的点击（HUD 命中测试未拦截的情况）。
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec() - _last_touch_ms > 400:
			if _try_hold_place_at(event.position):
				get_viewport().set_input_as_handled()
				return
			_world.request_pointer_action(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		# 触屏已在 _input() 中标记时间戳；此分支只处理落到世界的触点
		if _try_hold_place_at(event.position):
			get_viewport().set_input_as_handled()
			return
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
	var tint_material := ShaderMaterial.new()
	tint_material.shader = preload("res://shaders/scene_tint.gdshader")
	_season_rect.material = tint_material
	_tod_canvas.add_child(_season_rect)
	# 昼夜色调（覆盖在季节之上）
	_tod_rect = ColorRect.new()
	_tod_rect.color = Color(0, 0, 0, 0)
	_tod_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tod_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tod_rect.material = tint_material
	_tod_canvas.add_child(_tod_rect)
	_house_lights_overlay = preload("res://scripts/game/house_lights.gd").new()
	_tod_canvas.add_child(_house_lights_overlay)


func _build_title_screen() -> void:
	_title_screen = Control.new()
	_title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_title_screen)
	# 标题文字下垫一张半透明纸片，避免副标题/简介/操作说明压在花草底图上看不清（REQ-20261005-028）
	_title_card = Panel.new()
	_title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_card.add_theme_stylebox_override("panel", _flat(Color(PAPER, 0.84), Color(APRICOT, 0.6), 1, 18))
	_title_screen.add_child(_title_card)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -240
	column.offset_right = 240
	column.offset_top = -220
	column.offset_bottom = 260
	_title_screen.add_child(column)
	column.sort_children.connect(_fit_title_card)
	_title_label = _label(40, INK)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title_label)
	_subtitle_label = _label(18, TITLE_ACCENT)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_subtitle_label)
	_tagline_label = _label(16, MUTED)
	_tagline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_tagline_label)
	_play_button = _soft_button()
	_play_button.pressed.connect(_on_play_pressed)
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
	I18n.locale_changed.connect(_on_title_copy_locale_changed)
	call_deferred("_balance_title_copy")


## 标题列按屏高分三档排版。≥500 原样；短横屏缩字号与间距；屏高 ≤360（568×320、
## 带地址栏的手机横屏）原来内容高 321px 超出可用高度，操作说明掉出屏幕和纸片，
## 这一档再收紧上下边距、行距、标题/副标题/按钮字号和两个主按钮高度，让整列完整留在屏内（REQ-20261005-031）。
func _fit_title_column() -> void:
	if _title_label == null: return
	var title_column: Control = _title_label.get_parent()
	var short := size.y < 500.0
	var tight := size.y <= TITLE_TIGHT_MAX_HEIGHT
	var margin := 8.0 if tight else 20.0
	var title_width := minf(480.0,size.x-40.0)
	title_column.offset_left = -title_width*0.5
	title_column.offset_right = title_width*0.5
	title_column.offset_top = -(size.y-margin*2.0)*0.5
	title_column.offset_bottom = (size.y-margin*2.0)*0.5
	title_column.add_theme_constant_override("separation",4 if tight else (8 if short else 14))
	_title_label.add_theme_font_size_override("font_size",24 if tight else (28 if short else 40))
	_subtitle_label.add_theme_font_size_override("font_size",15 if tight else 18)
	_tagline_label.add_theme_font_size_override("font_size",14 if short else 16)
	_title_hint.add_theme_font_size_override("font_size",12 if short else 14)
	for button: Button in [_play_button, _album_button]:
		button.custom_minimum_size = Vector2(260.0, 40.0 if tight else 44.0)
		button.add_theme_font_size_override("font_size",14 if tight else 16)
	_licenses_button.add_theme_font_size_override("font_size",12 if tight else 14)
	_balance_title_copy()


## 纸片贴合标题列里实际可见的内容（列本身是整屏高、内容居中），左右留 18、上下留 14，并夹在屏内。
func _fit_title_card() -> void:
	if _title_card == null or _title_label == null: return
	var column: Control = _title_label.get_parent()
	var content := Rect2()
	var first := true
	for child in column.get_children():
		var c := child as Control
		if c == null or not c.visible: continue
		var r := Rect2(column.position + c.position, c.size)
		content = r if first else content.merge(r)
		first = false
	if first:
		_title_card.visible = false
		return
	_title_card.visible = true
	var card := content.grow_individual(18.0, 14.0, 18.0, 14.0)
	var screen := Rect2(Vector2(4.0, 4.0), _title_screen.size - Vector2(8.0, 8.0))
	if screen.size.x > 0.0 and screen.size.y > 0.0:
		card = card.intersection(screen)
	_title_card.position = card.position
	_title_card.size = card.size


## 标题页简介和操作说明在窄屏/矮屏上会把最后两三个字单独甩到下一行（360×640 操作说明剩「互动。」，
## 844×390 简介剩「出现。」），像没排完。这里给两段文字各找一个「行数不变、尽量窄」的平衡宽度
## （类似 CSS text-wrap: balance），文字仍居中；行数、字号、文案、按钮和纸片规则都不变，
## 只是断行点更均匀（REQ-20261006-044）。
const TITLE_BALANCE_SLACK := 2.0


func _on_title_copy_locale_changed(_locale: String) -> void:
	call_deferred("_balance_title_copy")


func _balance_title_copy() -> void:
	if _title_label == null or _tagline_label == null or _title_hint == null: return
	var column: Control = _title_label.get_parent()
	var avail := column.offset_right - column.offset_left
	if avail < 64.0: return
	for label: Label in [_tagline_label, _title_hint]:
		_balance_label_width(label, avail)


func _balance_label_width(label: Label, avail: float) -> void:
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var width := avail
	var lines := _title_copy_line_count(label.text, font, font_size, avail)
	if lines >= 2:
		var lo := avail * 0.4
		var hi := avail
		while hi - lo > 1.0:
			var mid := (lo + hi) * 0.5
			if _title_copy_line_count(label.text, font, font_size, mid) <= lines:
				hi = mid
			else:
				lo = mid
		width = minf(avail, ceilf(hi) + TITLE_BALANCE_SLACK)
		# 平衡宽度可能把「草泥马」这类词拆在两行。行数不变的前提下再稍微放宽，优先让每处换行落在标点或空格后面；
		# 找不到就保留平衡宽度（不比原来更差，也没有孤字）。
		var probe := width
		while probe <= avail:
			if _title_copy_line_count(label.text, font, font_size, probe) == lines and _title_copy_breaks_at_pauses(label.text, font, font_size, probe):
				width = probe
				break
			probe += 2.0
	if not is_equal_approx(label.custom_minimum_size.x, width):
		label.custom_minimum_size.x = width


const TITLE_BREAK_PAUSES := "，。、：；！？）」,.;:!?) "


## 给定宽度下，每处自动换行（不含最后一行和手动 \n）是否都落在标点或空格后面。
func _title_copy_breaks_at_pauses(text: String, font: Font, font_size: int, width: float) -> bool:
	var ts := TextServerManager.get_primary_interface()
	for para: String in text.split("\n"):
		if para.is_empty(): continue
		var shaped := ts.create_shaped_text()
		ts.shaped_text_add_string(shaped, para, font.get_rids(), font_size)
		var breaks := ts.shaped_text_get_line_breaks(shaped, width, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		ts.free_rid(shaped)
		for i in range(1, breaks.size() - 2, 2):
			var end: int = breaks[i]
			if end <= 0 or not TITLE_BREAK_PAUSES.contains(para.substr(end - 1, 1)):
				return false
	return true


## 与 Label 的 AUTOWRAP_WORD_SMART 相同的断行规则下，这段文字在给定宽度里排几行（含 \n 手动换行）。
func _title_copy_line_count(text: String, font: Font, font_size: int, width: float) -> int:
	if text.is_empty() or font == null: return 0
	var ts := TextServerManager.get_primary_interface()
	var total := 0
	for para: String in text.split("\n"):
		var shaped := ts.create_shaped_text()
		ts.shaped_text_add_string(shaped, para, font.get_rids(), font_size)
		var breaks := ts.shaped_text_get_line_breaks(shaped, width, 0, TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE)
		ts.free_rid(shaped)
		total += maxi(1, breaks.size() / 2)
	return total


func _build_hud() -> void:
	_hud = Control.new()
	_hud.visible = false
	# P0.2: MOUSE_FILTER_PASS 确保子控件在 web 导出时可靠收到点击。
	_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hud)
	_hint_panel = Panel.new()
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.add_theme_stylebox_override("panel", _flat(Color(PAPER, 0.90), Color(APRICOT, 0.65), 1, 12))
	_hud.add_child(_hint_panel)
	_hint_label = _label(15, INK)
	_hint_label.position = Vector2(24, 18)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint_label.size = Vector2(520, HINT_MIN_TEXT_HEIGHT)
	_hud.add_child(_hint_label)
	# 假期天数标签：挂在「歇一会儿」下方的小纸签，避开目标纸片并在树叶/天空上都可读（#338）
	_day_label = _label(14, INK)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var day_paper := _flat(Color(PAPER, 0.90), Color(APRICOT, 0.65), 1, 10)
	day_paper.content_margin_left = 8
	day_paper.content_margin_right = 8
	day_paper.content_margin_top = 2
	day_paper.content_margin_bottom = 2
	_day_label.add_theme_stylebox_override("normal", day_paper)
	_day_label.size = Vector2(160, 28)
	_day_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_day_label)
	_album_chip = _chip_button()
	# _show_album() 内部已调用 _pulse_button，此处直接连接即可
	_album_chip.pressed.connect(_show_album)
	# P0.2: tooltip 告知玩家此处可点，辅助鼠标悬停时的发现性。
	_album_chip.tooltip_text = I18n.t("hud.album.tooltip")
	_hud.add_child(_album_chip)
	_weather_chip = _chip_button()
	_weather_chip.pressed.connect(_on_weather_pressed)
	_hud.add_child(_weather_chip)
	_basket_chip = _chip_button()
	_basket_chip.pressed.connect(_show_basket)
	_hud.add_child(_basket_chip)
	_pause_button = _chip_button()
	_pause_button.pressed.connect(_toggle_pause)
	_hud.add_child(_pause_button)
	_action_button = _chip_button()
	# 按下时先触发视觉脉冲，再执行动作，让触控/鼠标点击有明确反馈
	_action_button.pressed.connect(func(): _pulse_button(_action_button); _world.request_primary_action())
	_hud.add_child(_action_button)
	for button: Button in [_album_chip,_weather_chip,_basket_chip,_pause_button,_action_button]:
		button.focus_mode = Control.FOCUS_NONE


func _build_pause_screen() -> void:
	_pause_screen = _overlay()
	add_child(_pause_screen)
	_pause_box = _centered_column(Vector2(360, 620), _pause_screen)
	_pause_panel = _pause_box.get_parent()
	_pause_title = _label(26, INK)
	_pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_box.add_child(_pause_title)
	_pause_columns = HBoxContainer.new()
	_pause_columns.add_theme_constant_override("separation", 12)
	_pause_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_box.add_child(_pause_columns)
	_pause_session = VBoxContainer.new()
	_pause_session.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_session.add_theme_constant_override("separation", 12)
	_pause_columns.add_child(_pause_session)
	_pause_audio = VBoxContainer.new()
	_pause_audio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pause_audio.add_theme_constant_override("separation", 12)
	_pause_columns.add_child(_pause_audio)
	_resume_button = _soft_button()
	_resume_button.pressed.connect(_toggle_pause)
	_restart_button = _soft_button()
	_restart_button.pressed.connect(func() -> void: _request_destructive_action("restart"))
	_pause_title_button = _soft_button()
	_pause_title_button.pressed.connect(func() -> void: _request_destructive_action("title"))
	_music_toggle = _soft_button()
	_music_toggle.pressed.connect(_toggle_music_layer)
	_ambience_toggle = _soft_button()
	_ambience_toggle.pressed.connect(_toggle_ambience_layer)
	_music_volume_label = _label(15, INK)
	_music_slider = _volume_slider()
	_music_slider.value_changed.connect(_on_music_gain_changed)
	_ambience_volume_label = _label(15, INK)
	_ambience_slider = _volume_slider()
	_ambience_slider.value_changed.connect(_on_ambience_gain_changed)
	_mute_toggle = _soft_button()
	_mute_toggle.pressed.connect(_toggle_master_mute)
	_place_pause(_pause_session, [_resume_button, _restart_button, _pause_title_button, _music_toggle, _music_volume_label, _music_slider, _ambience_toggle, _ambience_volume_label, _ambience_slider, _mute_toggle])
	_pause_box.minimum_size_changed.connect(_on_pause_content_resized)
	_fit_pause_panel()


## 矮屏（高 < 500）暂停纸片原来固定撑到「屏高 − 24」，844×390 上标题和两列按钮只占中间约 220px，
## 上下各留约 75px 空纸，像一张没排完的大白卡。现在矮屏按实际内容高度贴合（内容 + 纸边距 +
## 上下各 PAUSE_SHORT_BREATH 留白），仍不超过「屏高 − 24」并保持居中；宽度、字号、按钮、两列
## 分组与竖屏/大屏排版都不变（REQ-20261006-043）。
const PAUSE_SHORT_BREATH := 14.0
## 竖屏/大屏原来固定 min(620, 屏高 − 24)：390×844 上纸片 620px 高、单列内容连纸边距约 553px，
## 标题上方和最后一个按钮下方各空出约 43px，纸片下端还压住底栏一排按钮的上沿。
## 现在高屏也按内容贴合，上下各留 PAUSE_TALL_BREATH；上限、居中、360 宽、单列、字号与按钮都不变
## （REQ-20261007-059）。
const PAUSE_TALL_BREATH := 20.0


func _fit_pause_panel() -> void:
	if _pause_panel == null or size.x < 64.0 or size.y < 64.0:
		return
	var short := size.y < 500.0
	var margin := 12.0
	var panel_w := minf(680.0 if short else 360.0, size.x - margin * 2.0)
	var panel_h := minf(620.0, size.y - margin * 2.0)
	var sep := 4 if short else 12
	var button_h := 36.0 if short else 44.0
	_pause_box.add_theme_constant_override("separation", sep)
	_pause_session.add_theme_constant_override("separation", sep)
	_pause_audio.add_theme_constant_override("separation", sep)
	_pause_title.add_theme_font_size_override("font_size", 18 if short else 26)
	for button in [_resume_button, _restart_button, _pause_title_button, _music_toggle, _ambience_toggle, _mute_toggle]:
		button.custom_minimum_size = Vector2(120.0, button_h)
		button.add_theme_font_size_override("font_size", 13 if short else 16)
	for slider in [_music_slider, _ambience_slider]:
		slider.custom_minimum_size = Vector2(120.0, 28.0 if short else 32.0)
	for label in [_music_volume_label, _ambience_volume_label]:
		label.add_theme_font_size_override("font_size", 12 if short else 15)
	if short:
		_pause_audio.visible = true
		_place_pause(_pause_session, [_resume_button, _restart_button, _pause_title_button, _mute_toggle])
		_place_pause(_pause_audio, [_music_toggle, _music_volume_label, _music_slider, _ambience_toggle, _ambience_volume_label, _ambience_slider])
	else:
		_pause_audio.visible = false
		_place_pause(_pause_session, [_resume_button, _restart_button, _pause_title_button, _music_toggle, _music_volume_label, _music_slider, _ambience_toggle, _ambience_volume_label, _ambience_slider, _mute_toggle])
		_place_pause(_pause_audio, [])
	_apply_pause_panel_size(panel_w, panel_h)


## 矮屏改两列/切语言后子节点最小尺寸是延迟更新的，等内容最小高度真正变化时再贴合一次。
func _on_pause_content_resized() -> void:
	if _pause_panel == null or size.x < 64.0 or size.y < 64.0:
		return
	var short := size.y < 500.0
	_apply_pause_panel_size(minf(680.0 if short else 360.0, size.x - 24.0), minf(620.0, size.y - 24.0))


func _apply_pause_panel_size(panel_w: float, panel_h: float) -> void:
	var breath := PAUSE_SHORT_BREATH if size.y < 500.0 else PAUSE_TALL_BREATH
	panel_h = minf(panel_h, _pause_content_height() + breath * 2.0)
	_pause_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	_pause_panel.offset_left = -panel_w * 0.5
	_pause_panel.offset_right = panel_w * 0.5
	_pause_panel.offset_top = -panel_h * 0.5
	_pause_panel.offset_bottom = panel_h * 0.5


## 暂停纸片装下当前内容所需的最小高度（含纸面上下内边距），矮屏与高屏贴合共用。
func _pause_content_height() -> float:
	var height := _pause_box.get_combined_minimum_size().y
	var style := _pause_panel.get_theme_stylebox("panel")
	if style != null:
		height += style.get_margin(SIDE_TOP) + style.get_margin(SIDE_BOTTOM)
	return ceilf(height)


func _place_pause(parent: Node, nodes: Array) -> void:
	for node in nodes:
		# Array 元素无静态类型，Godot 4.7 不能从 get_parent() 推断 current。
		var current: Node = node.get_parent()
		if current == parent:
			continue
		if current == null:
			parent.add_child(node)
		else:
			node.reparent(parent)
	for i in nodes.size():
		parent.move_child(nodes[i], i)


func _build_confirmation_screen() -> void:
	_confirm_screen = _overlay()
	add_child(_confirm_screen)
	var box := _centered_column(CONFIRM_PANEL_SIZE, _confirm_screen)
	_confirm_panel = box.get_parent()
	# 内容比纸片高时向上下两侧同时长，保持居中（REQ-20261005-030）。
	_confirm_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_confirm_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
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
	_fit_confirm_panel()


## REQ-20261005-030：确认纸片原来固定 420 宽，360/390 宽的竖屏手机上左右两边伸出屏外，
## 圆角、边框和按钮两端都被裁掉。现在宽高都不超过屏幕减去两侧 12px，仍居中；
## 宽屏保持 420×240 不变。文案、字号、按钮、颜色和行为都不变。
func _fit_confirm_panel() -> void:
	if _confirm_panel == null or size.x < 64.0 or size.y < 64.0:
		return
	var margin := 12.0
	var panel_w := minf(CONFIRM_PANEL_SIZE.x, size.x - margin * 2.0)
	var panel_h := minf(CONFIRM_PANEL_SIZE.y, size.y - margin * 2.0)
	_confirm_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	_confirm_panel.offset_left = -panel_w * 0.5
	_confirm_panel.offset_right = panel_w * 0.5
	_confirm_panel.offset_top = -panel_h * 0.5
	_confirm_panel.offset_bottom = panel_h * 0.5
	# REQ-20261007-052：两颗按钮最小 260 宽，加纸面左右各 16 内边距要 292；屏宽不足 316
	# （如 280 / 300 宽竖屏）时纸片被按钮撑过「屏宽 − 24」，280 宽两边各伸出屏外 6px。
	# 只在这种窄纸片上把按钮收到纸片内宽，仍 44 高、字号不变；内宽 ≥ 260 时一律保持 260。
	var style := _confirm_panel.get_theme_stylebox("panel")
	var inner_w := panel_w
	if style != null:
		inner_w -= style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT)
	var button_w := minf(CONFIRM_BUTTON_WIDTH, floorf(inner_w))
	for button in [_confirm_accept_button, _confirm_cancel_button]:
		if button != null:
			button.custom_minimum_size = Vector2(button_w, button.custom_minimum_size.y)


func _build_album_screen() -> void:
	_album_screen = _overlay()
	(_album_screen.get_child(0) as ColorRect).color = Color(0.35, 0.26, 0.2, 0.42)
	add_child(_album_screen)
	var box := _centered_column(Vector2(860, 560), _album_screen)
	_album_panel = box.get_parent()
	_album_panel.add_theme_stylebox_override("panel", _flat(Color("e8d5bb"), MUTED, 2, 12))
	box.add_theme_constant_override("separation", 8)
	_album_title = _label(24, INK)
	_album_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_album_title)
	_album_spread = HBoxContainer.new()
	_album_spread.add_theme_constant_override("separation", 0)
	box.add_child(_album_spread)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	controls.custom_minimum_size = Vector2(800, 42)
	box.add_child(controls)
	_album_previous_button = _soft_button()
	_album_previous_button.custom_minimum_size = Vector2(0, 42)
	_album_previous_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_album_previous_button.pressed.connect(func() -> void: _flip_album(-1))
	controls.add_child(_album_previous_button)
	_album_next_button = _soft_button()
	_album_next_button.custom_minimum_size = Vector2(0, 42)
	_album_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_album_next_button.pressed.connect(func() -> void: _flip_album(1))
	controls.add_child(_album_next_button)
	_album_back_button = _soft_button()
	_album_back_button.custom_minimum_size = Vector2(0, 42)
	_album_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_album_back_button.pressed.connect(_hide_album)
	controls.add_child(_album_back_button)


func _build_notice() -> void:
	_notice = _label(16, INK)
	_notice.visible = false
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# REQ-20261005-025：底部通知压在前景草石上时棕字看不清。垫一块贴合文字的半透明纸片，
	# 字色、字号、位置、时长都不变；没有动画，低动效无需分支。
	_notice.add_theme_stylebox_override("normal", _notice_paper())
	# 换行变高时向上长，纸片底边留在原位，不压住下方按钮。
	_notice.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_notice.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_notice.offset_left = -220
	_notice.offset_right = 220
	_notice.offset_top = -92
	_notice.offset_bottom = -52
	add_child(_notice)


func _on_play_pressed() -> void:
	# A touch may also release the native GUI button after entering the yard.
	# Only the title can request entry; keep audio unlock in this gesture stack.
	if _screen == "title":
		_start_holiday()
	# Same pressed stack as the real enter control. Not deferred.
	AudioDirector.unlock_audio()


func _toggle_music_layer() -> void:
	var frame := Engine.get_process_frames()
	if frame == _music_toggle_frame:
		return
	_music_toggle_frame = frame
	AudioDirector.set_music_enabled(not AudioDirector.music_enabled())
	_refresh_texts()


func _toggle_ambience_layer() -> void:
	var frame := Engine.get_process_frames()
	if frame == _ambience_toggle_frame:
		return
	_ambience_toggle_frame = frame
	AudioDirector.set_ambience_enabled(not AudioDirector.ambience_enabled())
	_refresh_texts()


func _toggle_master_mute() -> void:
	var muted := bool(TuningStore.get_value("audio.master.muted", false))
	TuningStore.set_value("audio.master.muted", not muted)
	_refresh_texts()


func _on_music_gain_changed(value: float) -> void:
	AudioDirector.set_music_gain(value / 100.0)
	_refresh_volume_labels()


func _on_ambience_gain_changed(value: float) -> void:
	AudioDirector.set_ambience_gain(value / 100.0)
	_refresh_volume_labels()


func _handle_volume_touch(event: InputEvent) -> bool:
	# Only a gesture starting on an unobscured slider can own its later drag.
	if not _pause_screen.visible or _confirm_screen.visible or _album_screen.visible:
		_volume_touch_index = -1
		_volume_touch_slider = null
		return false
	# Native Slider may still hold the mouse synthesized from the first touch.
	# Route motion through the owned ScreenDrag, not another finger's mouse move.
	if event is InputEventMouseMotion and _volume_touch_index != -1:
		return true
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index != _volume_touch_index:
				return false
			_volume_touch_index = -1
			_volume_touch_slider = null
			return true
		if _volume_touch_index != -1:
			return false
		for slider: HSlider in [_music_slider, _ambience_slider]:
			if _point_sets_slider(slider, event.position):
				_volume_touch_index = event.index
				_volume_touch_slider = slider
				return true
	elif event is InputEventScreenDrag and event.index == _volume_touch_index and _volume_touch_slider != null:
		_point_sets_slider(_volume_touch_slider, event.position)
		return true
	return false


func _point_sets_slider(slider: HSlider, point: Vector2) -> bool:
	if slider == null or not slider.is_visible_in_tree():
		return false
	var rect := slider.get_global_rect().grow_individual(8, 16, 8, 16)
	if not rect.has_point(point):
		return false
	var span := maxf(rect.size.x, 1.0)
	var ratio := clampf((point.x - rect.position.x) / span, 0.0, 1.0)
	slider.value = round(ratio * 100.0)
	return true


func _volume_slider() -> HSlider:
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = 100.0
	slider.custom_minimum_size = Vector2(260, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	return slider


func _refresh_volume_labels() -> void:
	if _music_volume_label != null:
		_music_volume_label.text = "%s %d%%" % [I18n.t("pause.music_volume"), int(round(AudioDirector.music_gain() * 100.0))]
	if _ambience_volume_label != null:
		_ambience_volume_label.text = "%s %d%%" % [I18n.t("pause.ambience_volume"), int(round(AudioDirector.ambience_gain() * 100.0))]
	if _music_slider != null:
		_music_slider.set_value_no_signal(round(AudioDirector.music_gain() * 100.0))
	if _ambience_slider != null:
		_ambience_slider.set_value_no_signal(round(AudioDirector.ambience_gain() * 100.0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		AudioDirector.set_application_active(false)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		AudioDirector.set_application_active(true)


func _start_holiday(save_progress: bool = true) -> void:
	if _holiday_start_pending or not SaveStore.can_play(): return
	_holiday_start_pending = true
	_leave_exploration()
	if save_progress and _world != null: _world._save_progress()
	if not await SaveStore.flush_pending() or _save_problem_active:
		_holiday_start_pending = false
		_show_save_pending(false)
		return
	TuningStore.begin_run(false)
	AudioDirector.set_game_paused(false)
	_clear_world(false)
	_world = YardWorldType.new()
	_world_root.add_child(_world)
	_world.setup(
		SaveStore.get_album(),
		SaveStore.get_photo_moments(),
		SaveStore.get_holiday_day(),
		SaveStore.get_holiday_day_elapsed(),
		SaveStore.get_plant_state(),
		SaveStore.get_first_fish_caught(),
		SaveStore.get_animal_relationship_memory(),
		SaveStore.get_world_weather(),
		SaveStore.get_yard_gate_open()
	)
	_world.album_updated.connect(_on_album_updated)
	_world.notice_requested.connect(_show_notice_key)
	_world.notice_dismiss_requested.connect(_dismiss_notice_key)
	_world.weather_changed.connect(func(_w: String) -> void: _refresh_hud())
	_world.camera_focus_requested.connect(_on_focus)
	_world.camera_release_requested.connect(_on_release_focus)
	_world.cinematic_view_changed.connect(_on_cinematic_view_changed)
	_world.day_advanced.connect(_on_day_advanced)
	_world.fish_caught.connect(_on_fish_caught)
	_world.ground_food_requested.connect(_on_ground_food_action)
	_world.decor_recall_requested.connect(_on_decor_recall)
	_on_inventory_changed()
	_on_decor_changed()
	_on_residents_changed()
	_residents.start_yard_residents()
	_world.exploration_requested.connect(_on_exploration_requested)
	_camera.enabled = true
	_portrait_camera_x = _world.get_player().position.x
	_cam_zoom = 1.0
	_cam_target_zoom = 1.0
	_cam_offset = Vector2.ZERO
	_cam_target_offset = Vector2.ZERO
	_cam_quiet_bounds = false
	_cam_effective_offset = Vector2.ZERO
	_camera.make_current()
	_screen = "game"
	_title_screen.visible = false
	_paper.visible = false
	_hud.visible = true
	_pause_screen.visible = false
	_confirm_screen.visible = false
	_album_screen.visible = false
	get_tree().paused = false
	# HUD 可见后立即重算布局，确保相册等按钮落在正确点击区域（同帧 + 延迟各执行一次）
	_layout()
	call_deferred("_layout")
	_idle_hint_timer = 55.0  # 进院后55秒内不显示空闲提示，让玩家先看看
	_first_hint_shown = false
	_last_tod_phase = ""
	_show_notice_key("notice.arrive")
	# 上次外出途中被打断：安全回到院里，已带上的东西照常收下
	var restored := _exploration.attach(SaveStore, _world_root)
	if not _exploration.last_companion.is_empty():
		_world.return_from_path(_exploration.last_companion)
	if not restored.is_empty():
		_show_notice_key(restored, _exploration.last_params)
	# Persist the first regional seed immediately, rather than rerolling it when
	# a new/legacy save closes before the first periodic checkpoint.
	if SaveStore.get_world_weather().is_empty(): _world._save_progress()
	_refresh_hud()
	AudioDirector.set_yard_active(true)
	if _world.holiday_day == 1 and SaveStore.get_album().is_empty():
		_show_delayed_soft_hint()
	_holiday_start_pending = false


## 标题 / 重开前先按宿主中断回院，让这趟的提交排在随后的 flush 之前
func _leave_exploration() -> void:
	if _exploration != null and _exploration.is_exploring():
		_exploration.interrupt()


func _clear_world(save_progress: bool = true) -> void:
	if _exploration != null and _exploration.is_exploring():
		if _screen == "exploring":
			_screen = "leaving"
		_exploration.interrupt()
	_cancel_photo_arrivals()
	_on_cinematic_view_changed("")
	if _world != null:
		# Preserve the partial day before title/restart replaces this world.
		if save_progress: _world._save_progress()
		_world.queue_free()
		_world = null


func _on_exploration_requested() -> void:
	if _screen != "game" or _world == null or _exploration.is_exploring():
		return
	if _inventory != null and _inventory.busy(): return
	if _decor != null and _decor.busy(): return
	_world._save_progress()
	var weather := "sunny" if _world.weather == "sun" else _world.weather
	_exploration.try_begin({"day": _world.holiday_day, "elapsed": _world._day_elapsed}, weather, null, _world.companion_context())


## 画卷有自己的相机与界面；小院隐藏，公共时钟继续推进。
func _on_exploration_entered() -> void:
	_screen = "exploring"
	_cancel_photo_arrivals()
	_on_cinematic_view_changed("")
	_world.cancel_scene_feedback()
	_world.input_enabled = false
	_world.visible = false
	_hud.visible = false
	_sync_hold_hotbar_visibility()
	_notice_time = 0.0
	_exploration.scroll.pause_requested.connect(_toggle_pause)
	_path_rain = null
	_sync_path_rain(0.0)


## Public regional weather layer. Near-path motion/geometry stays with its Owner.
func _sync_path_rain(delta: float) -> void:
	if _world == null or _exploration.scroll == null: return
	if not is_instance_valid(_path_rain):
		_path_rain = preload("res://scripts/game/regional_rain.gd").new()
		_exploration.scroll.add_child(_path_rain)
		_path_rain.configure(_exploration.scroll.layout.SIZE,false)
		_path_rain.restore({"clock":0.0,"amount":1.0 if _world.weather == "rain" else 0.0,"reduced":bool(TuningStore.get_value("ui.reduced_motion",false))})
	_path_rain.advance(delta,_world.weather == "rain",bool(TuningStore.get_value("ui.reduced_motion",false)))
	var tint := Color(0.78,0.82,0.89) if _world.weather == "rain" else Color(0.88,0.91,0.96) if _world.weather == "overcast" else Color.WHITE
	var painting: Sprite2D = _exploration.scroll.painting
	painting.modulate = tint if delta == 0.0 or bool(TuningStore.get_value("ui.reduced_motion",false)) else painting.modulate.lerp(tint,clampf(delta/3.0,0.0,1.0))


func _on_exploration_returned(notice_key: String) -> void:
	if _screen != "exploring" or _world == null:
		return
	_screen = "game"
	_world.visible = true
	_world.input_enabled = true
	_world.return_from_path(_exploration.last_companion)
	_portrait_camera_x = _world.get_player().position.x
	_camera.make_current()
	_hud.visible = true
	_layout()
	_refresh_hud()
	_show_notice_key(notice_key if not notice_key.is_empty() else "notice.exploration.back", _exploration.last_params)


func _show_title(save_progress: bool = true) -> void:
	_leave_exploration()
	if save_progress and _world != null:
		_world._save_progress()
		if not await SaveStore.flush_pending() or _save_problem_active:
			_show_save_pending(false)
			return
	get_tree().paused = false
	TuningStore.end_run()
	AudioDirector.set_game_paused(false)
	AudioDirector.set_yard_active(false)
	_screen = "title"
	_clear_world(false)
	_camera.enabled = false
	_paper.visible = true
	_title_screen.visible = true
	_hud.visible = false
	_pause_screen.visible = false
	_confirm_screen.visible = false
	_album_screen.visible = false
	_sync_hold_hotbar_visibility()
	# 回到标题时清除昼夜叠色与季节底色
	if _tod_rect != null:
		_tod_rect.color = Color(0, 0, 0, 0)
	if _season_rect != null:
		_season_rect.color = Color(0, 0, 0, 0)
	_refresh_texts()


func _show_basket() -> void:
	if _world != null and _world.house != null and _world.house.busy(): return
	if _screen != "game" or _world == null or _pause_screen.visible or _album_screen.visible:
		return
	_cancel_photo_arrivals()
	_world.cancel_scene_feedback()
	_world.input_enabled = false
	_basket_panel.visible = true
	_ui_layer.move_child(_basket_panel, _ui_layer.get_child_count() - 1)
	_on_inventory_changed()
	_sync_hold_hotbar_visibility()
	get_tree().paused = true
	AudioDirector.set_game_paused(true)
	_basket_panel.close_button.grab_focus()


func _hide_basket() -> void:
	_basket_panel.visible = false
	get_tree().paused = false
	AudioDirector.set_game_paused(false)
	if _world != null: _world.input_enabled = true
	get_viewport().gui_release_focus()
	_sync_hold_hotbar_visibility()


func _on_inventory_changed() -> void:
	if _inventory == null: return
	var inventory: Dictionary = _inventory.view()
	if _world != null:
		_world.sync_inventory(str(inventory.get("held", "")), _inventory.busy() or inventory.is_empty(), inventory.get("ground", []))
	if _basket_panel != null:
		_basket_panel.update_view(inventory, SaveStore.get_available_keepsakes(), _inventory.state, _inventory.busy())
		if _basket_panel.decor_button != null:
			_basket_panel.decor_button.text = "Arrange finds in the yard" if I18n.get_locale() == "en" else "把小物摆在院里"
			_basket_panel.decor_button.disabled = _inventory.busy()
	if _hold_hotbar != null:
		_hold_hotbar.update_view(inventory, SaveStore.get_available_keepsakes(), _inventory.state, _inventory.busy())
		_sync_hold_hotbar_visibility()


func _show_decor() -> void:
	if _world == null or _inventory.busy(): return
	_basket_panel.visible = false
	_decor_panel.visible = true
	_hud.visible = false
	_notice.visible = false
	_sync_hold_hotbar_visibility()
	_decor_camera = {"position": _camera.position, "zoom": _camera.zoom}
	_on_decor_changed()
	_decor_panel.choose_spot(_decor_panel.selected)
	_decor_panel.close_button.grab_focus()


func _hide_decor() -> void:
	_decor_panel.visible = false
	_decor_panel.draft.clear()
	if _world != null: _world.decor_view.clear_preview()
	if not _decor_camera.is_empty():
		_camera.position = _decor_camera.position
		_camera.zoom = _decor_camera.zoom
		_camera.force_update_scroll()
	_hud.visible = true
	_sync_hold_hotbar_visibility()
	_show_basket()


func _decor_ground_recall(event: InputEvent) -> bool:
	if _decor == null or _world == null or _decor.busy():
		return false
	var at := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		at = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec() - _last_touch_ms < 400:
			return false
		at = event.position
	else:
		return false
	if _decor_panel.paper != null and _decor_panel.paper.get_global_rect().has_point(at):
		return false
	var Decor = load("res://scripts/inventory/yard_decor.gd")
	var spot: String = Decor.spot_at(_decor.view(), _screen_to_world(at))
	if spot.is_empty():
		return false
	_last_touch_ms = Time.get_ticks_msec()
	_on_decor_recall(spot)
	return true


func _on_decor_recall(spot: String) -> void:
	if _decor == null or _decor.busy() or spot.is_empty():
		return
	if _decor.request("remove", spot, {}):
		_show_notice_key("notice.decor_recalled")
	else:
		_show_notice_key("notice.decor_recall_blocked")


func _on_decor_changed() -> void:
	if _decor == null: return
	if _world != null: _world.decor_view.sync(_decor.view())
	if _decor_panel != null:
		_decor_panel.update_view(_decor.view(), SaveStore.get_available_keepsakes(), _decor.state, _decor.busy())
	_on_inventory_changed()
	if not _basket_drop.is_empty() and _decor.state != "saving":
		var drop := _basket_drop
		_basket_drop = {}
		if _decor.state == "idle" and _decor.view().get("places", {}).has(drop.spot):
			_basket_panel.show_place_note(drop.find_id, drop.spot, "placed")
		elif _basket_panel.visible:
			# 没存好：转到布置面板，那里有保存状态和「再确认一次」
			_decor_panel.selected = drop.spot
			_show_decor()


## #594：背篓里的小物拖到院里空着的固定位置，松手就摆好（不微调，dx/dy 为 0）
func _place_from_basket(find_id: String, spot: String) -> void:
	if _decor == null or _decor.busy() or not _basket_drop.is_empty(): return
	_basket_drop = {"find_id": find_id, "spot": spot}
	_basket_panel.show_place_note(find_id, spot, "saving")
	if not _decor.request("place", spot, {"find_id": find_id, "dx": 0, "dy": 0}): _on_decor_changed()


func _on_decor_resubmitted(failed_ops: Array, op_id: String) -> void:
	var problems := {}
	for failed_id in failed_ops:
		if _save_problems.get(failed_id, {}).get("kind", "") == "decor":
			problems[failed_id] = _save_problems[failed_id].duplicate(true)
	if not problems.is_empty(): _save_retry_coverage[op_id] = {"problems": problems, "untracked_revision": -1}


func _on_ground_food_action(action: String, kind: String, details: Dictionary, actor_id: String) -> void:
	if _inventory == null or _inventory.busy(): return
	_inventory_food_consumer = actor_id
	_inventory.request(action, kind, details)


func _on_inventory_settled(action: String, _fish: String) -> void:
	if _world != null and _world.ground_food != null:
		_world.ground_food.settled(action, _inventory_food_consumer)
	_inventory_food_consumer = ""


func _on_residents_changed() -> void:
	if _world != null and _residents != null: _world.sync_residents(_residents.view())

func _on_residents_resubmitted(failed_ops: Array, op_id: String) -> void:
	var problems := {}
	for failed_id in failed_ops:
		if _save_problems.get(failed_id, {}).get("kind", "") == "residents":
			problems[failed_id] = _save_problems[failed_id].duplicate(true)
	if not problems.is_empty():
		_save_retry_coverage[op_id] = {"problems": problems, "untracked_revision": -1}


func _on_inventory_resubmitted(failed_ops: Array, op_id: String) -> void:
	var problems := {}
	for failed_id in failed_ops:
		if _save_problems.get(failed_id, {}).get("kind", "") == "inventory":
			problems[failed_id] = _save_problems[failed_id].duplicate(true)
	if not problems.is_empty():
		_save_retry_coverage[op_id] = {"problems": problems, "untracked_revision": -1}


func _toggle_pause() -> void:
	if _screen not in ["game", "exploring"]:
		return
	_volume_touch_index = -1
	_volume_touch_slider = null
	var paused := not _pause_screen.visible
	if paused:
		_cancel_photo_arrivals()
	_pause_screen.visible = paused
	get_tree().paused = paused
	AudioDirector.set_game_paused(paused)
	if _world != null and _screen == "game":
		_world.input_enabled = not paused
		if paused: _world.cancel_scene_feedback()
	_refresh_texts()
	_sync_notice_visibility()
	_sync_hold_hotbar_visibility()


func _request_destructive_action(action: String) -> void:
	_volume_touch_index = -1
	_volume_touch_slider = null
	_pending_destructive_action = action
	_confirm_screen.visible = true
	_refresh_texts()
	_sync_hold_hotbar_visibility()


func _confirm_destructive_action() -> void:
	if _decor != null and _decor.busy():
		_cancel_destructive_action()
		return
	if _inventory != null and _inventory.busy():
		_cancel_destructive_action()
		return
	if _save_transition: return
	_save_transition = true
	_leave_exploration()
	if _world != null: _world._save_progress()
	if not await SaveStore.flush_pending() or _save_problem_active:
		_save_transition = false
		_confirm_screen.visible = false
		_show_save_pending(false)
		return
	_save_transition = false
	var action := _pending_destructive_action
	_pending_destructive_action = ""
	_confirm_screen.visible = false
	if action == "restart":
		_start_holiday(false)
	elif action == "title":
		_show_title(false)


func _cancel_destructive_action() -> void:
	_pending_destructive_action = ""
	_confirm_screen.visible = false
	_sync_hold_hotbar_visibility()


func _on_weather_pressed() -> void:
	if _world == null:
		return
	_world.toggle_weather()
	_show_notice_key("notice.weather")


func _on_album_updated(collected: PackedStringArray, latest_id: String) -> void:
	var fresh := latest_id not in SaveStore.get_album()
	for item: Dictionary in _pending_photo_saves.values():
		if item.latest_id == latest_id: fresh = false
	var moments: Dictionary = _world.photo_moments.duplicate(true) if _world != null else {}
	var op_id := SaveStore.request_album(collected, moments)
	if op_id.is_empty():
		_show_save_pending()
		return
	_pending_photo_saves[op_id] = {"latest_id": latest_id, "fresh": fresh}
	_refresh_hud()
	if _album_screen.visible: _rebuild_album(collected)


func _on_exploration_save_accepted(op_id: String, kind: String, scope: Dictionary) -> void:
	_save_exploration_sequence += 1
	var accepted := scope.duplicate(true)
	accepted["order"] = _save_exploration_sequence
	accepted["kind"] = kind
	_save_exploration_scopes[op_id] = accepted
	var coverage := {}
	for failed_id in _save_problems:
		var problem: Dictionary = _save_problems[failed_id]
		if _exploration_save_covers(accepted, problem):
			coverage[failed_id] = problem.duplicate(true)
	_save_exploration_coverage[op_id] = {"kind": kind, "problems": coverage}


func _exploration_save_covers(accepted: Dictionary, problem: Dictionary) -> bool:
	var prior: Dictionary = problem.get("scope", {})
	if prior.is_empty() or prior.trip_id != accepted.trip_id or prior.serial != accepted.serial: return false
	if prior.order >= accepted.order or prior.revision > accepted.revision: return false
	if problem.kind == "exploration_trip":
		return accepted.kind == "exploration_trip" and prior.finds == accepted.finds
	return problem.kind == "exploration"


func _on_save_confirmed(op_id: String, kind: String) -> void:
	if _save_exploration_coverage.has(op_id) and _save_exploration_coverage[op_id].kind == kind:
		_clear_covered_save_problems(_save_exploration_coverage[op_id].problems)
		_save_exploration_coverage.erase(op_id)
	_save_exploration_scopes.erase(op_id)
	_save_durable_ops[op_id] = true
	if _save_problems.get(op_id, {}).get("kind", "") == kind:
		_save_problems.erase(op_id)
	if _save_retry_coverage.has(op_id):
		_clear_covered_save_problems(_save_retry_coverage[op_id].problems)
		if _save_untracked_revision == _save_retry_coverage[op_id].untracked_revision:
			_save_untracked_problem = false
		_save_retry_coverage.erase(op_id)
	if not _pending_photo_saves.has(op_id): return
	var pending: Dictionary = _pending_photo_saves[op_id]
	_pending_photo_saves.erase(op_id)
	if pending.fresh:
		_latest_photo = pending.latest_id
		var snapshot := SaveStore.get_photo_moment(pending.latest_id)
		if not snapshot.is_empty() and _photo_arrival != null and _screen == "game":
			_photo_arrival_queue.append(snapshot)
			if not _photo_arrival.visible: _play_next_photo_arrival()
		else:
			_show_notice_key("notice.photo.saved")
	_refresh_hud()


func _on_save_state_changed(state: String) -> void:
	if _save_retry_button != null:
		_save_retry_button.disabled = state in ["writing", "acknowledging", "resolving"]
	if state == "ready" and SaveStore.is_save_idle():
		_clear_covered_save_problems(_save_ack_coverage)
		_save_ack_coverage.clear()
		_save_durable_ops.clear()
		if _save_problems.is_empty() and _pending_photo_saves.is_empty() and not _save_untracked_problem:
			_save_problem_active = false
			if _save_status_panel != null: _save_status_panel.hide()


func _clear_covered_save_problems(coverage: Dictionary) -> void:
	for op_id in coverage:
		if _save_problems.get(op_id) == coverage[op_id]:
			_save_problems.erase(op_id)


func _on_save_rejected(op_id: String, kind: String, code: String) -> void:
	_pending_photo_saves.erase(op_id)
	_save_retry_coverage.erase(op_id)
	_on_save_problem(op_id, kind, code)
	# Cloud may queue its trip after the return record, before that record fails.
	# Only terminal rejection binds this exact failure revision to later accepted ops.
	for pending_id in _save_exploration_scopes:
		if _exploration_save_covers(_save_exploration_scopes[pending_id], _save_problems[op_id]):
			_save_exploration_coverage[pending_id].problems[op_id] = _save_problems[op_id].duplicate(true)
	_save_exploration_scopes.erase(op_id)
	_save_exploration_coverage.erase(op_id)


## 探索收尾清理被拒后宿主重交了同一份冻结请求：只把这次清理此前的失败（原样快照）绑到新编号，
## 新编号确认后按快照精确清掉，面板在队列空闲时照常收起；失败又变了就不清
func _on_exploration_cleanup_resubmitted(failed_ops: Array, op_id: String) -> void:
	var problems := {}
	for failed_id in failed_ops:
		if _save_problems.get(failed_id, {}).get("kind", "") == "exploration_cleanup":
			problems[failed_id] = _save_problems[failed_id].duplicate(true)
	if not problems.is_empty():
		_save_retry_coverage[op_id] = {"problems": problems, "untracked_revision": -1}


func _on_save_problem(op_id: String, kind: String, _code: String) -> void:
	_save_problem_revision += 1
	_save_problems[op_id] = {"kind": kind, "revision": _save_problem_revision, "durable": _save_durable_ops.has(op_id)}
	if _save_exploration_scopes.has(op_id):
		_save_problems[op_id]["scope"] = _save_exploration_scopes[op_id].duplicate(true)
	_show_save_pending(false)


func _build_save_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_save_status_panel = PanelContainer.new()
	_save_status_panel.add_theme_stylebox_override("panel", _flat(PAPER, APRICOT))
	_save_status_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_save_status_panel.offset_left = -170
	_save_status_panel.offset_right = 170
	_save_status_panel.offset_top = SAVE_STATUS_TOP
	layer.add_child(_save_status_panel)
	_save_status_box = BoxContainer.new()
	_save_status_box.vertical = true
	_save_status_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_save_status_panel.add_child(_save_status_box)
	_save_status_message = _label(16, INK)
	_save_status_message.text = I18n.t("notice.save.pending")
	_save_status_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_save_status_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_status_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_save_status_message.custom_minimum_size.x = 320
	_save_status_box.add_child(_save_status_message)
	_save_retry_button = _soft_button()
	_save_retry_button.text = I18n.t("save.retry")
	_save_retry_button.pressed.connect(_retry_save)
	_save_status_box.add_child(_save_retry_button)
	_save_status_panel.hide()
	_fit_save_status()


## REQ-20261006-042：「保存暂时无法继续」纸片原来固定 352px 宽、顶边 y=90、居中，
## 竖屏 360/390 会压住右上「假期第 N 天」，360 英文还压住两行半的目标纸片，360 宽时右边
## 出屏 2px；568×320 短横屏也压住天数。文字左对齐而按钮居中，按钮写死「再确认一次」，
## 切英文后消息和按钮都不跟着换。现在：宽度不超过屏宽减 20；顶边落在与它横向重叠的
## 目标纸片/天数标签下方 8px；短横屏（高 ≤ 360 且横屏）改成文字在左、按钮在右的一行，
## 留白收窄，免得往下压到「翻开手帐/天气」那排按钮；文字居中（横排时左对齐）；按钮与消息走 I18n，
## 切语言即刷新。只改展示，不碰保存状态、重试逻辑和成功条件。
const SAVE_STATUS_TOP := 90.0
const SAVE_STATUS_MAX_WIDTH := 352.0
const SAVE_STATUS_ROW_MAX_WIDTH := 548.0
const SAVE_STATUS_GAP := 8.0
const SAVE_STATUS_ROW_BUTTON := 168.0


func _save_status_row_layout() -> bool:
	return size.y <= 360.0 and size.x > size.y


func _fit_save_status() -> void:
	if _save_status_panel == null or _save_status_box == null:
		return
	var row := _save_status_row_layout()
	var margin_x := 32.0
	var width := minf(SAVE_STATUS_ROW_MAX_WIDTH if row else SAVE_STATUS_MAX_WIDTH, maxf(160.0, size.x - 20.0))
	var inner := width - margin_x
	_save_status_box.vertical = not row
	_save_status_box.add_theme_constant_override("separation", 12 if row else 4)
	# 横排时纸面上下留白收到 4px、文字 15px：640×300 这类更矮的横屏上，夹在天数标签和
	# 底部按钮排之间只有约 56px，原 10px 留白 + 16px 两行会压到「翻开手帐」顶边。
	var paper := _save_status_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if paper != null:
		paper.content_margin_top = 4.0 if row else 10.0
		paper.content_margin_bottom = 4.0 if row else 10.0
	_save_status_message.add_theme_font_size_override("font_size", 15 if row else 16)
	if row:
		_save_retry_button.custom_minimum_size = Vector2(SAVE_STATUS_ROW_BUTTON, 44)
		_save_status_message.custom_minimum_size.x = inner - SAVE_STATUS_ROW_BUTTON - 12.0
		_save_status_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_save_status_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		_save_retry_button.custom_minimum_size = Vector2(minf(260.0, inner), 44)
		_save_status_message.custom_minimum_size.x = inner
		_save_status_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_save_status_message.size_flags_horizontal = Control.SIZE_FILL
	var left := size.x * 0.5 - width * 0.5
	var top := SAVE_STATUS_TOP
	for obstacle: Control in [_hint_panel, _day_label]:
		if obstacle == null or not obstacle.is_visible_in_tree():
			continue
		var rect := obstacle.get_global_rect()
		if rect.position.x < left + width and rect.end.x > left:
			top = maxf(top, ceilf(rect.end.y) + SAVE_STATUS_GAP)
	_save_status_panel.offset_left = -width * 0.5
	_save_status_panel.offset_right = width * 0.5
	_save_status_panel.offset_top = top
	_save_status_panel.offset_bottom = top
	_save_status_panel.reset_size()


func _show_save_pending(untracked := true) -> void:
	if untracked:
		_save_untracked_problem = true
		_save_untracked_revision += 1
	_save_problem_active = true
	if _save_status_panel != null:
		_fit_save_status()
		_save_status_panel.show()


func _retryable_save_problems(include_fish: bool) -> Dictionary:
	var coverage := {}
	for op_id in _save_problems:
		var kind: String = _save_problems[op_id].kind
		if kind in ["yard", "plant", "relationship", "album"] or (include_fish and kind == "fish"):
			coverage[op_id] = _save_problems[op_id].duplicate()
	return coverage


func _retry_save() -> void:
	if _world != null and _world.house != null and _world.house.failed:
		var coverage := {}
		for old_id in _save_problems:
			if _save_problems[old_id].kind == "house-sleep": coverage[old_id] = _save_problems[old_id].duplicate(true)
		var next: String = _world.house.retry()
		if not next.is_empty(): _save_retry_coverage[next] = {"problems":coverage,"untracked_revision":-1}
		return
	if _decor != null and _decor.busy() and _decor.state in ["failed", "unknown"]:
		_decor.retry()
		return
	if _residents != null and _residents.busy() and _residents.state in ["failed", "unknown"]:
		_residents.retry()
		return
	if _inventory != null and _inventory.busy():
		_inventory.retry()
		return
	var before := SaveStore.persistence_state()
	# Capture before retry: a native backend may complete synchronously.
	_save_ack_coverage = {}
	if before == "blocked":
		for op_id in _save_problems:
			if _save_problems[op_id].durable:
				_save_ack_coverage[op_id] = _save_problems[op_id].duplicate()
	if SaveStore.retry_pending(): return
	_save_ack_coverage.clear()
	if SaveStore.is_save_idle() and _world != null:
		var coverage := {"problems": _retryable_save_problems(_world._first_fish_polaroid_done), "untracked_revision": _save_untracked_revision}
		var prior_photos := _pending_photo_saves.keys()
		_world._save_progress()
		SaveStore.request_animal_relationship_memory(_world._relationship_memory)
		if _world._first_fish_polaroid_done: SaveStore.request_first_fish_caught()
		_on_album_updated(_world.collected, "")
		for op_id in _pending_photo_saves:
			if op_id not in prior_photos and _pending_photo_saves[op_id].latest_id == "":
				_save_retry_coverage[op_id] = coverage


func _play_next_photo_arrival() -> void:
	if _photo_arrival_queue.is_empty() or _photo_arrival == null:
		return
	var snapshot: Dictionary = _photo_arrival_queue.pop_front()
	_flash_photo()
	_photo_arrival.play(snapshot, bool(TuningStore.get_value("ui.reduced_motion", false)))


func _cancel_photo_arrivals() -> void:
	_photo_arrival_queue.clear()
	if _photo_arrival != null:
		_photo_arrival.dismiss()


func _on_photo_tucked() -> void:
	if _screen != "game" or _album_screen.visible or _pause_screen.visible:
		_photo_arrival_queue.clear()
		return
	if not _photo_arrival_queue.is_empty():
		_play_next_photo_arrival()


func _show_album() -> void:
	_cancel_photo_arrivals()
	_album_index = 0
	_album_screen.visible = true
	# 打开相册：更强脉冲 + 居中 pivot，让桌面 Web 一次点击就有明确“开了”的反馈
	if _album_chip != null:
		_album_chip.pivot_offset = _album_chip.size * 0.5
	_pulse_button(_album_chip)
	if _screen == "game": _hud.visible = false
	if _world != null:
		_world.input_enabled = false
		_world.cancel_scene_feedback()
		_rebuild_album(_world.collected)
	else:
		_rebuild_album(PackedStringArray(SaveStore.get_album()))
	_refresh_texts()
	_sync_hold_hotbar_visibility()


func _hide_album() -> void:
	_album_screen.visible = false
	_album_touch_origin = Vector2.INF
	if _screen == "game": _hud.visible = true
	if _world != null and not _pause_screen.visible:
		_world.input_enabled = true
	_sync_hold_hotbar_visibility()


func _rebuild_album(collected: PackedStringArray) -> void:
	_album_entries.clear()
	for id: String in collected:
		if not ExpressionCatalog.find_rule(id).is_empty() and id not in _album_entries:
			_album_entries.append(id)
	_render_album_pages()


func _flip_album(direction: int) -> void:
	var stride := 2 if _album_two_pages else 1
	var last := maxi(0, ((_album_entries.size() - 1) / stride) * stride)
	var next_index := clampi(_album_index + direction * stride, 0, last)
	if next_index == _album_index: return
	_album_index = next_index
	_render_album_pages()


func _render_album_pages() -> void:
	if _album_spread == null: return
	var stride := 2 if _album_two_pages else 1
	var last := maxi(0, ((_album_entries.size() - 1) / stride) * stride)
	_album_index = clampi((_album_index / stride) * stride, 0, last)
	for child in _album_spread.get_children():
		_album_spread.remove_child(child)
		child.queue_free()
	_album_spread.add_child(_album_page(_album_index))
	if _album_two_pages:
		var spine := ColorRect.new()
		spine.color = Color("a89078")
		spine.custom_minimum_size = Vector2(10, _album_page_size.y)
		spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_album_spread.add_child(spine)
		_album_spread.add_child(_album_page(_album_index + 1))
	_album_previous_button.disabled = _album_entries.is_empty() or _album_index == 0
	_album_next_button.disabled = _album_entries.is_empty() or _album_index + stride >= _album_entries.size()


func _album_page(index: int) -> Control:
	var page := Control.new()
	page.custom_minimum_size = _album_page_size
	var paper := TextureRect.new()
	var half := AtlasTexture.new()
	half.atlas = TITLE_PAPER
	half.region = Rect2(640 if index % 2 else 0, 0, 640, 720)
	paper.texture = half
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(paper)
	var edge := Panel.new()
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge.add_theme_stylebox_override("panel", _flat(Color(1, 0.99, 0.95, 0.13), Color("d5bea1"), 1, 3))
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(edge)
	if index >= _album_entries.size():
		if _album_entries.is_empty() and index == 0:
			var empty := _label(17, INK)
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			empty.text = I18n.t("album.empty")
			empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			page.add_child(empty)
		return page
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 22
	content.offset_right = -22
	content.offset_top = 15
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 5)
	page.add_child(content)
	var heading := _label(14, MUTED)
	heading.text = I18n.t("album.page_label")
	content.add_child(heading)
	var rule_id := _album_entries[index]
	var rule := ExpressionCatalog.find_rule(rule_id)
	var moment := SaveStore.get_photo_moment(rule_id)
	var caption_text := PhotoDiary.caption(moment, rule_id) if not moment.is_empty() else I18n.t(str(rule.get("title_key", "")))
	var note_text := I18n.t(str(rule.get("note_key", "")))
	# Measure with the same inherited font and line spacing as the final labels.
	# Fixed allowances for two lines fail on the existing longer English notes.
	var text_height := func(text: String, width: float, font_size: int) -> float:
		var paragraph := TextParagraph.new()
		var font := get_theme_font("font", "Label")
		paragraph.width = maxf(1.0, width)
		paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
		paragraph.add_string(text, font, font_size)
		# Label uses the composite font's line height even on Latin-only lines.
		var lines := paragraph.get_line_count()
		return ceilf(font.get_height(font_size) * lines + get_theme_constant("line_spacing", "Label") * maxi(0, lines - 1))
	var text_width := _album_page_size.x - 44.0
	var note_height := maxf(36.0, text_height.call(note_text, text_width, 14))
	var body_height: float = _album_page_size.y - 25.0 - text_height.call(heading.text, text_width, 14) - text_height.call(I18n.t("album.page", {"page": str(index + 1)}), text_width, 12) - 10.0
	var compact_page := _album_page_size.y < 370.0 or body_height - note_height - 5.0 < 300.0
	var wide_page := compact_page and _album_page_size.x > _album_page_size.y * 1.6
	var body: BoxContainer = HBoxContainer.new() if wide_page else VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12 if wide_page else 5)
	content.add_child(body)
	var center := CenterContainer.new()
	if not compact_page: center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(center)
	var card_width := minf(280.0, minf(_album_page_size.x - 52.0, (_album_page_size.y - 138.0) * 0.8))
	if compact_page:
		var photo_height: float = body_height if wide_page else body_height - note_height - text_height.call(caption_text, text_width, 14) - 10.0
		card_width = maxf(1.0, minf(180.0 if wide_page else 140.0, (photo_height - 2.0) * 0.8))
	center.add_child(_photo_card(rule, true, card_width, not compact_page))
	var writing := VBoxContainer.new()
	writing.add_theme_constant_override("separation", 5)
	if wide_page:
		writing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		writing.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_child(writing)
	if compact_page:
		# A tiny frame cannot hold readable text. Keep the original date/caption
		# at normal size beside a landscape photo or below a short narrow page.
		var caption := _label(14, INK)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.text = caption_text
		writing.add_child(caption)
	var note := _label(14, INK)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.y = 36.0
	note.text = note_text
	writing.add_child(note)
	var footer := _label(12, MUTED)
	footer.text = I18n.t("album.page", {"page": str(index + 1)})
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(footer)
	return page


func _photo_card(rule: Dictionary, owned: bool, width: float = 240.0, caption_on_frame: bool = true) -> Control:
	var card_scale := width / 240.0
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(240, 300) * card_scale
	var frame := TextureRect.new()
	frame.texture = POLAROID
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(frame)
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(28, 28) * card_scale
	portrait.size = Vector2(184, 184) * card_scale
	var moment := SaveStore.get_photo_moment(str(rule.get("id",""))) if owned else {}
	if owned and not moment.is_empty():
		var photograph := PhotoMoment.new()
		# PhotoMoment defaults to 184 px. This album instance must follow the
		# card scale; do not change the shared arrival/capture component.
		photograph.custom_minimum_size = portrait.size
		photograph.position = portrait.position
		# Its constructor's minimum-size cache clears on entering the tree.
		photograph.set_deferred("size", portrait.size)
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
	if not caption_on_frame:
		return holder
	var caption := _label(maxi(12, roundi(13.0 * card_scale)), INK if owned else MUTED)
	caption.position = ALBUM_CAPTION_RECT.position * card_scale
	caption.size = ALBUM_CAPTION_RECT.size * card_scale
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.text = (PhotoDiary.caption(moment, str(rule.get("id", "")))
		if owned and not moment.is_empty() else
		I18n.t(str(rule.get("title_key", ""))) if owned else I18n.t("album.empty_slot"))
	_fit_album_caption(caption, card_scale)
	holder.add_child(caption)
	return holder


## REQ-20261007-048: the album polaroid's caption ("Holiday day N" + moment)
## must stay on the frame's bottom paper strip. Captions that fit on their own
## lines keep the original 24,232 192×52 box, size and spacing untouched.
## Otherwise use the whole strip (same 24,227 192×56 as PhotoArrival), centre
## vertically, tighten line spacing, then step the size down to 12px, and
## narrow the box to the same line count so no lone last word is left.
func _fit_album_caption(caption: Label, card_scale: float) -> void:
	var text := caption.text
	var font := get_theme_font("font", "Label")
	var spacing := get_theme_constant("line_spacing", "Label")
	if text.is_empty() or font == null:
		return
	var base_size := caption.get_theme_font_size("font_size")
	var original := ALBUM_CAPTION_RECT.size * card_scale
	var paragraphs := text.split("\n").size()
	var lines := PhotoArrival.caption_line_count(text, font, base_size, original.x)
	if lines <= paragraphs and PhotoArrival.caption_height(font, base_size, spacing, lines) <= original.y:
		return
	var strip := Rect2(ALBUM_CAPTION_STRIP.position * card_scale, ALBUM_CAPTION_STRIP.size * card_scale)
	var font_size := base_size
	var line_spacing := spacing
	for candidate in range(base_size, ALBUM_CAPTION_MIN_FONT_SIZE - 1, -1):
		font_size = candidate
		lines = PhotoArrival.caption_line_count(text, font, font_size, strip.size.x)
		line_spacing = spacing
		if PhotoArrival.caption_height(font, font_size, spacing, lines) <= strip.size.y:
			break
		line_spacing = mini(spacing, ALBUM_CAPTION_TIGHT_LINE_SPACING)
		if PhotoArrival.caption_height(font, font_size, line_spacing, lines) <= strip.size.y:
			break
	var width := strip.size.x
	if lines > paragraphs:
		var lo := minf(strip.size.x, ALBUM_CAPTION_BALANCE_MIN_WIDTH * card_scale)
		var hi := strip.size.x
		if PhotoArrival.caption_line_count(text, font, font_size, lo) <= lines:
			hi = lo
		while hi - lo > 1.0:
			var mid := (lo + hi) * 0.5
			if PhotoArrival.caption_line_count(text, font, font_size, mid) <= lines:
				hi = mid
			else:
				lo = mid
		width = minf(strip.size.x, ceilf(hi) + ALBUM_CAPTION_BALANCE_SLACK)
	if font_size != base_size:
		caption.add_theme_font_size_override("font_size", font_size)
	if line_spacing != spacing:
		caption.add_theme_constant_override("line_spacing", line_spacing)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.position = Vector2(strip.position.x + (strip.size.x - width) * 0.5, strip.position.y)
	# Autowrap minimum height depends on width: set width, refresh, then height.
	caption.size = Vector2(width, strip.size.y)
	caption.update_minimum_size()
	caption.size = Vector2(width, strip.size.y)


## Keep the playable frame inside the painting while retaining player follow.
static func _cover_yard_frame(requested: Vector2, art: Rect2, viewport: Vector2, zoom: float, hud_space: float) -> Vector2:
	if zoom <= 0.0 or not art.has_area(): return requested
	var lower := art.position + viewport * 0.5 / zoom
	var upper := art.end - Vector2(viewport.x * 0.5, viewport.y * 0.5 - hud_space) / zoom
	return Vector2(
		clampf(requested.x, lower.x, upper.x) if lower.x <= upper.x else art.get_center().x,
		clampf(requested.y, lower.y, upper.y) if lower.y <= upper.y else art.get_center().y + hud_space / (2.0 * zoom)
	)


## Quiet focus preserves the baseline's coverage without adding magnification.
static func _bound_quiet_camera(requested: Vector2, baseline: Vector2, art: Rect2, viewport: Vector2, zoom: float, hud_space: float) -> Vector2:
	if zoom <= 0.0 or not art.has_area():
		return baseline
	var playable := Rect2(Vector2.ZERO, Vector2(viewport.x, maxf(0.0, viewport.y - hud_space)))
	var baseline_art := Rect2((art.position - baseline) * zoom + viewport * 0.5, art.size * zoom)
	var covered := baseline_art.intersection(playable)
	if not covered.has_area():
		return baseline
	var lower := art.position + (viewport * 0.5 - covered.position) / zoom
	var upper := art.end + (viewport * 0.5 - covered.end) / zoom
	return Vector2(
		clampf(requested.x, lower.x, upper.x) if lower.x <= upper.x else baseline.x,
		clampf(requested.y, lower.y, upper.y) if lower.y <= upper.y else baseline.y
	)


func _on_focus(world_point: Vector2, zoom: float) -> void:
	# The world sets the encounter phase before emitting its focus, even when
	# quiet's same-tick yield has not run yet. Never infer the source from zoom.
	if _cam_quiet_bounds:
		# The clipped intention was never visible. A new owner must interpolate
		# from the last effective displacement, not reveal that latent offset.
		_cam_offset = _cam_effective_offset
	_cam_quiet_bounds = _world != null and _world.is_quiet_camera_focus()
	_cam_target_zoom = zoom
	var home := YardWorld.WORLD_SIZE * 0.5
	var portrait := size.x < 700.0 and size.y > size.x
	if portrait: home.x = _portrait_camera_x
	_cam_target_offset = (world_point - home) * (1.0 if portrait else 0.35)


func _on_release_focus() -> void:
	# Keep quiet bounds until its return finishes; a new focus replaces them.
	_cam_target_zoom = 1.0
	_cam_target_offset = Vector2.ZERO


func _on_cinematic_view_changed(stage: String) -> void:
	if _cinematic_shade == null:
		return
	var active := not stage.is_empty()
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	_cinematic_shade.color.a = 0.08 if active and stage == "first_person" else 0.0
	var bar_height := 34.0 if reduced else 52.0
	var bar_alpha := 0.94 if active else 0.0
	_cinematic_top_bar.offset_bottom = bar_height if active else 0.0
	_cinematic_bottom_bar.offset_top = -bar_height if active else 0.0
	_cinematic_top_bar.color.a = bar_alpha
	_cinematic_bottom_bar.color.a = bar_alpha



## REQ-20261008-075：底部手持快捷栏挂在 _ui_layer，跟背篓同一份 inventory 视图。
## 开院可见；暂停 / 相册 / 确认 / 背篓 / 布置面板时隐藏。树暂停由那些叠层负责，快捷栏本身不 WHEN_PAUSED。
func _ensure_hold_hotbar() -> void:
	if _hold_hotbar != null or _ui_layer == null:
		return
	_hold_hotbar = load("res://scripts/ui/hold_hotbar.gd").new()
	_hold_hotbar.name = "HoldHotbar"
	_ui_layer.add_child(_hold_hotbar)
	_hold_hotbar.withdraw_requested.connect(_on_hold_withdraw)
	_hold_hotbar.visible = false
	_layout_hold_hotbar()


func _layout_hold_hotbar() -> void:
	if _hold_hotbar == null:
		return
	var Hotbar = load("res://scripts/ui/hold_hotbar.gd")
	var rect: Rect2 = Hotbar.preferred_rect(size, size.x < 700.0)
	_hold_hotbar.position = rect.position
	_hold_hotbar.size = rect.size
	_sync_hold_hotbar_visibility()


func _sync_hold_hotbar_visibility() -> void:
	if _hold_hotbar == null:
		return
	var show: bool = (
		_screen == "game"
		and _hud.visible
		and (_world == null or _world.house == null or not _world.house.busy())
		and not _pause_screen.visible
		and not _album_screen.visible
		and not _confirm_screen.visible
		and (_basket_panel == null or not _basket_panel.visible)
		and (_decor_panel == null or not _decor_panel.visible)
	)
	_hold_hotbar.visible = show


func _on_hold_withdraw(kind: String) -> void:
	if _world != null and _world.house != null and _world.house.busy(): return
	if _inventory == null or kind.is_empty() or _inventory.busy():
		return
	_inventory.request("withdraw", kind)


## 武装点地投放：合法才走既有 drop 事务；非法只提示，不扣数、不改 held。
func _try_hold_place_at(screen_pos: Vector2) -> bool:
	if _hold_hotbar == null or not _hold_hotbar.visible or not _hold_hotbar.is_place_armed():
		return false
	if _inventory == null or _inventory.busy():
		return false
	var inventory: Dictionary = _inventory.view()
	var held := str(inventory.get("held", ""))
	if held.is_empty():
		return false
	# A painted house door is an explicit scene action, never a food drop spot.
	if _world != null and YardSceneHotspots.at_point(_world, _screen_to_world(screen_pos)).get("target", "") == YardSceneHotspots.HOUSE_DOOR:
		return false
	var Intent = load("res://scripts/inventory/hold_place_intent.gd")
	var obstacles: Array = _world.physical_obstacles("player") if _world != null else []
	var intent: Dictionary = Intent.food_drop_at(held, _screen_to_world(screen_pos), obstacles)
	if intent.has("error"):
		_show_notice_key("notice.cannot_walk")
		return true
	_inventory.request(str(intent.get("action", "drop")), str(intent.get("kind", held)), intent.get("details", {}))
	return true


func _screen_to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen


func _dismiss_notice_key(key: String) -> void:
	if _notice_key == key:
		_notice_time = 0.0
		_notice.visible = false


const NOTICE_PAD_X := 14.0
const NOTICE_MIN_HALF := 60.0


func _notice_paper() -> StyleBoxFlat:
	var style := _flat(Color(PAPER, 0.88), Color(APRICOT, 0.55), 1, 14)
	style.content_margin_left = NOTICE_PAD_X
	style.content_margin_right = NOTICE_PAD_X
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


## 纸片宽度贴合当前文字（含后设的大字号），最宽仍是原来的 ±220 / 屏宽减 20，超出照旧换行。
func _fit_notice() -> void:
	if _notice == null:
		return
	var limit := minf(220.0, size.x * 0.5 - 20.0)
	var font := _notice.get_theme_font("font")
	var font_size := _notice.get_theme_font_size("font_size")
	var text_width := 0.0
	if font != null:
		text_width = font.get_string_size(_notice.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var half := clampf(ceilf(text_width * 0.5) + NOTICE_PAD_X + 2.0, minf(NOTICE_MIN_HALF, limit), limit)
	_notice.offset_left = -half
	_notice.offset_right = half


func _can_show_notice() -> bool:
	return _screen == "game" and not _pause_screen.visible and not _album_screen.visible and not _confirm_screen.visible and not _basket_panel.visible and (_decor_panel == null or not _decor_panel.visible)


func _sync_notice_visibility() -> void:
	_notice.visible = _notice_time > 0.0 and _can_show_notice()
	# Keep growing/wrapped notices above the actual hotbar, not behind its slots.
	var bottom := -130.0 if size.x < 700.0 else -70.0
	if _hold_hotbar != null and _hold_hotbar.visible:
		bottom = _hold_hotbar.position.y - size.y - 8.0
	_notice.offset_top = bottom - 40.0
	_notice.offset_bottom = bottom


func _show_notice_key(key: String, params: Dictionary = {}) -> void:
	_notice_key = key
	_notice.text = I18n.t(key, params)
	_notice_time = 3.2
	# 每次普通通知都重置字体大小（钓到鱼/空闲提示会在后续覆盖为更大字号）
	_notice.add_theme_font_size_override("font_size", 16)
	_fit_notice()
	_sync_notice_visibility()


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
	tween.tween_property(_photo_flash, "color:a", 0.23, 0.06)
	tween.tween_property(_photo_flash, "color:a", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 收杆成功时的全屏水蓝闪光：快速淡入淡蓝色（水/鱼质感），比拍立得闪光轻柔，不喧宾夺主
## 旧实现已弃用（_photo_flash 会与拍立得奶白闪光复用同一节点，竞态问题）
## 新实现请看 _on_fish_caught()，使用独立 _fish_flash 节点
func _flash_catch() -> void:
	if _photo_flash == null:
		return
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		return
	# 将 _photo_flash 临时变为淡蓝色系（收杆后复原），避免与拍立得奶白色混淆
	var prev_color := _photo_flash.color
	_photo_flash.color = Color(0.62, 0.86, 0.96, 0.0)  # 水蓝，alpha=0 起点
	var tween := create_tween()
	tween.tween_property(_photo_flash, "color:a", 0.28, 0.07)   # 快速淡入
	tween.tween_property(_photo_flash, "color:a", 0.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 动画结束后把颜色还原到奶油白（供下次拍照用）
	tween.tween_callback(func() -> void: _photo_flash.color = Color(CREAM, 0.0))


## REQ-20261006-034: on short landscape screens (usable height 360 or less,
## e.g. 568x320 or a 640x300 phone browser with its bars showing) the album's
## fixed chrome left a one-page book only 146-166 px tall, so the page number
## and longer notes ran off the paper and into the buttons. Screens in this
## tight band now trim the outer margin, paper padding, title size, spacing and
## button height so the page gets the room; taller screens keep the original
## numbers.
func _fit_album_frame() -> void:
	var tight := size.y <= ALBUM_TIGHT_MAX_HEIGHT
	var album_width := minf(860.0,size.x-32.0)
	var album_height := minf(560.0,size.y-(16.0 if tight else 32.0))
	_album_panel.custom_minimum_size = Vector2(album_width,album_height)
	_album_panel.offset_left = -album_width*0.5
	_album_panel.offset_right = album_width*0.5
	_album_panel.offset_top = -album_height*0.5
	_album_panel.offset_bottom = album_height*0.5
	var separation := 4 if tight else 8
	var button_height := 40.0 if tight else 42.0
	var title_size := 18 if tight else 24
	var padding := 6.0 if tight else 10.0
	var frame_style := _album_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if frame_style != null:
		frame_style.content_margin_top = padding
		frame_style.content_margin_bottom = padding
	(_album_title.get_parent() as VBoxContainer).add_theme_constant_override("separation", separation)
	_album_title.add_theme_font_size_override("font_size", title_size)
	for button: Button in [_album_previous_button, _album_next_button, _album_back_button]:
		button.custom_minimum_size.y = button_height
	var was_two_pages := _album_two_pages
	_album_two_pages = album_width >= 670.0 and size.y >= 460.0
	var book_width := album_width - 32.0
	var book_height := album_height - 122.0
	if tight:
		# Panel padding + title line + two gaps + buttons + 4 px slack.
		var title_height := ceilf(_album_title.get_theme_font("font").get_height(title_size))
		book_height = floorf(album_height - padding * 2.0 - title_height - separation * 2.0 - button_height - 4.0)
	_album_spread.custom_minimum_size = Vector2(book_width, book_height)
	_album_previous_button.get_parent().custom_minimum_size = Vector2(book_width, button_height)
	_album_page_size = Vector2((book_width - 10.0) * 0.5 if _album_two_pages else book_width, book_height)
	if _album_screen.visible or was_two_pages != _album_two_pages:
		_render_album_pages()


func _layout() -> void:
	var pad := 20.0
	if _album_chip == null: return
	var compact := size.x < 700.0
	_fit_title_column()
	_fit_album_frame()
	_fit_notice()
	_notice.offset_top = -170 if compact else -110
	_notice.offset_bottom = -130 if compact else -70
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var chip_width := (size.x - pad * 4.0) / 3.0 if compact else minf(188.0, (size.x - pad * 5.0) / 4.0)
	_refresh_yard_chip_labels()
	for button in [_album_chip,_weather_chip,_basket_chip]:
		button.custom_minimum_size = Vector2(chip_width,48)
		button.size = Vector2(chip_width,48)
	_action_button.custom_minimum_size = Vector2(size.x-pad*2.0 if compact else chip_width,48)
	_action_button.size = _action_button.custom_minimum_size
	_pause_button.custom_minimum_size = Vector2(120.0 if compact else 188.0,48)
	_pause_button.size = _pause_button.custom_minimum_size
	_pause_button.position = Vector2(size.x-_pause_button.size.x-pad,pad)
	_hint_label.position = Vector2(pad,16)
	_hint_label.size = Vector2(minf(520.0,maxf(120.0,size.x-_pause_button.size.x-pad*3.0)), HINT_MIN_TEXT_HEIGHT)
	_hint_panel.position = Vector2(pad-9.0, 9.0)
	_fit_hint_panel()
	# 天数标签：与暂停按钮同宽，紧贴其下方；横竖屏都不进入目标纸片（#338）
	if _day_label != null:
		_day_label.size = Vector2(_pause_button.size.x, 28)
		_day_label.position = Vector2(_pause_button.position.x, _pause_button.position.y + _pause_button.size.y + 8.0)
	_fit_save_status()
	var row := size.y-124.0 if compact else size.y-68.0
	_album_chip.position = Vector2(pad,row)
	_weather_chip.position = Vector2(pad * 2.0 + chip_width,row)
	_basket_chip.position = Vector2(pad * 3.0 + chip_width * 2.0,row)
	_action_button.position = Vector2(pad if compact else size.x-_action_button.size.x-pad,size.y-68.0)
	_fit_pause_panel()
	_fit_confirm_panel()
	_layout_hold_hotbar()


## 目标纸片按目标文字的实际行数伸缩（REQ-20261005-029）：
## 短横屏单行不再留半截空纸压住远山，窄屏英文三四行也不再溢出纸外压到院景。
## 最少保留与按钮同高的 48px 纸面，文字在纸上垂直居中。
func _fit_hint_panel() -> void:
	if _hint_label == null or _hint_panel == null:
		return
	_hug_hint_width()
	var lines := maxi(1, _hint_label.get_line_count())
	var spacing := float(_hint_label.get_theme_constant("line_spacing"))
	var text_height := lines * float(_hint_label.get_line_height()) + (lines - 1) * spacing
	_hint_label.size = Vector2(_hint_label.size.x, maxf(HINT_MIN_TEXT_HEIGHT, ceilf(text_height)))
	_hint_panel.size = _hint_label.size + Vector2(18.0, 16.0)


## 目标纸片贴合文字宽度（REQ-20261006-045）：纸片原来总撑到最大宽度（最多 520px）。
## 844×390 上一行目标只占左半，右边约 250px 空纸压住远山；640×360 / 568×320 的两行
## 短目标（文案自带换行）每行一百多像素，纸却有 478 / 406px 宽。现在每一行（按文案里的
## 换行分段）都能在最大宽度内放下时，纸宽 = 最长那一行的实际宽度（左缘不动，最窄 120px）；
## 有任何一段放不下、需要自动换行时仍用原来的最大宽度。只在文字、可用宽度、字号或可见性
## 变化时重新测量，不每帧排版。
const HINT_HUG_MIN_WIDTH := 120.0
var _hint_fit_key := ""
var _hint_fit_width := 0.0


func _hint_max_width() -> float:
	var pad := 20.0
	var pause_width := _pause_button.size.x if _pause_button != null else 188.0
	return minf(520.0, maxf(120.0, size.x - pause_width - pad * 3.0))


func _hug_hint_width() -> void:
	var max_width := _hint_max_width()
	var font_size := _hint_label.get_theme_font_size("font_size")
	var key := "%s|%.2f|%d|%s" % [_hint_label.text, max_width, font_size, str(_hint_label.is_visible_in_tree())]
	if key != _hint_fit_key:
		_hint_fit_key = key
		_hint_fit_width = max_width
		_hint_label.size = Vector2(max_width, _hint_label.size.y)
		var lines_at_max := _hint_label.get_line_count()
		var font := _hint_label.get_theme_font("font")
		var widest := 0.0
		for segment: String in _hint_label.text.split("\n"):
			widest = maxf(widest, font.get_string_size(segment, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		if not _hint_label.text.is_empty() and ceilf(widest) + 2.0 <= max_width:
			var hugged := clampf(ceilf(widest) + 2.0, minf(HINT_HUG_MIN_WIDTH, max_width), max_width)
			_hint_label.size = Vector2(hugged, _hint_label.size.y)
			if _hint_label.get_line_count() == lines_at_max:
				_hint_fit_width = hugged
	_hint_label.size = Vector2(_hint_fit_width, _hint_label.size.y)


func _refresh_hud() -> void:
	_sync_hold_hotbar_visibility()
	if _world == null:
		return
	_hud.modulate.a = float(TuningStore.get_value("ui.hud.opacity", 0.94))
	_refresh_yard_chip_labels()
	_weather_chip.text = I18n.t("hud.weather.%s" % _world.weather)
	_basket_chip.text = "Basket" if I18n.get_locale() == "en" else "大背篓"
	_pause_button.text = I18n.t("hud.pause")
	# 显示与空格/行动按钮完全相同的实时目标和动作；橙色说明对应脚边标记。
	var action := _world.primary_action()
	var verb := I18n.t(str(action.get("label", "action.grass")))
	var target_key := _world.action_target_key(action)
	if not target_key.is_empty():
		var marked := str(action.get("target", "")).begins_with("pet:")
		var hint_key := "hud.hint.marked_target" if marked else "hud.hint.action_target"
		if size.x < 700.0:
			hint_key += ".compact"
		_hint_label.text = I18n.t(hint_key, {
			"target": I18n.t(target_key), "action": verb,
		})
		_hint_label.add_theme_color_override("font_color", Color("9a540f") if marked else INK)
	else:
		_hint_label.text = I18n.t(_world.hint_context())
		_hint_label.add_theme_color_override("font_color", INK)
	_action_button.text = verb
	_fit_hint_panel()
	if _save_status_panel != null and _save_status_panel.visible:
		_fit_save_status()
	# 更新假期天数标签
	if _day_label != null:
		_day_label.text = I18n.t("hud.day", {"n": str(_world.holiday_day)})


func _refresh_yard_chip_labels() -> void:
	_album_chip.text = "Journal" if I18n.get_locale() == "en" and size.x < 400.0 else I18n.t("hud.album")


func _on_day_advanced(day: int) -> void:
	# 翻天时刷新 HUD，并显示带天数的氛围通知
	_refresh_hud()
	# 重置空闲提示计时（新一天开始，给玩家一段呼吸时间）
	_idle_hint_timer = 50.0
	# 选取带天数的通知文字（轮换三条，保持新鲜感）
	var day_notices: Array[String] = [
		"notice.new_day.a",
		"notice.new_day.b",
		"notice.new_day.c",
	]
	_show_notice_key(day_notices[(day - 1) % day_notices.size()])


## 收杆成功：独立蓝色闪光层 + 行动按钮双弹脉冲 + 大字通知
## playtest #4：通知优先于 reduced_motion；闪光峰值抬高并提到 UI 层最前。
func _on_fish_caught(carry_type: String) -> void:
	if _inventory != null:
		_inventory.request("catch", carry_type)
	# 钓到通知：无论是否减动效都拉长可读时间（拍立得可能抢通知，YardWorld 会重发）
	_notice_time = maxf(_notice_time, 6.5)
	_notice.add_theme_font_size_override("font_size", 22)
	_sync_notice_visibility()
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		return
	# 独立蓝色屏幕闪光（提到 UI 层最前，峰值更高，桌面 Web 不可错过）
	if _fish_flash != null:
		_ui_layer.move_child(_fish_flash, _ui_layer.get_child_count() - 1)
		var flash_color: Color
		match carry_type:
			"medium": flash_color = Color(0.28, 0.58, 0.95, 0.0)
			"odd":    flash_color = Color(0.55, 0.40, 0.92, 0.0)
			_:        flash_color = Color(0.35, 0.78, 0.95, 0.0)
		_fish_flash.color = flash_color
		var ft := create_tween()
		ft.tween_property(_fish_flash, "color:a", 0.78, 0.08).set_trans(Tween.TRANS_QUAD)
		ft.tween_property(_fish_flash, "color:a", 0.55, 0.18)
		ft.tween_property(_fish_flash, "color:a", 0.0, 1.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 行动按钮双弹脉冲（峰值 1.75）
	if _action_button != null:
		_action_button.pivot_offset = _action_button.size * 0.5
		var tween := create_tween()
		tween.tween_property(_action_button, "modulate", Color(1.75, 1.35, 0.70, 1.0), 0.06).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(_action_button, "modulate", Color(0.88, 0.88, 0.88, 1.0), 0.09).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(_action_button, "modulate", Color(1.55, 1.22, 0.78, 1.0), 0.07).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(_action_button, "modulate", Color.WHITE, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## 第1天进院且相册为空时，延迟 4.5 秒发送柔性引导提示（淡出后已看不到 arrive 通知）
func _show_delayed_soft_hint() -> void:
	await get_tree().create_timer(4.5).timeout
	if _screen != "game" or _world == null:
		return
	_first_hint_shown = true
	_show_notice_key("notice.first_hint")


## 轮播空闲提示：从候选列表里依次取出一条，针对玩家当前状态过滤。
## playtest #3 修复：提示字号升至 18px，时长延至 8s；首条不跳索引，从 [0] 开始。
func _show_idle_hint() -> void:
	if _screen != "game" or _world == null:
		return
	if _pause_screen.visible or _album_screen.visible:
		return
	# 如果相册是空的且还没给过综合引导，优先发一次
	if not _first_hint_shown and _world.collected_count() == 0:
		_first_hint_shown = true
		_show_notice_key("notice.first_hint")
		_notice_time = 8.0
		_notice.add_theme_font_size_override("font_size", 18)
		return
	var player := _world.get_player()
	var pos := player.position if player != null else Vector2(640, 500)
	# 根据玩家当前位置动态构建候选列表
	var candidates: Array[String] = []
	# 离钓鱼点远（>220px）时提示去钓鱼
	if pos.distance_to(Vector2(700, 535)) > 220.0:
		candidates.append("notice.hint.go_fish")
	candidates.append("notice.hint.go_plant")
	candidates.append("notice.hint.go_pet")
	candidates.append("notice.hint.go_explore")
	if player == null or not player.carrying_grass:
		candidates.append("notice.hint.go_grass")
	if candidates.is_empty():
		return
	# 循环取下一条（首次 index=0，不跳过第一个候选）
	_idle_hint_index = _idle_hint_index % candidates.size()
	_show_notice_key(candidates[_idle_hint_index])
	_idle_hint_index = (_idle_hint_index + 1) % candidates.size()
	# 延长时长 + 加大字号（比普通通知更醒目，帮助玩家在安静状态下发现活动）
	_notice_time = 8.0
	_notice.add_theme_font_size_override("font_size", 18)


## 将 tod_fraction 映射到日段名称（用于 TOD 相位变化通知）
func _tod_phase_name(t: float) -> String:
	return preload("res://scripts/game/world_daylight.gd").phase(t)


## 行动按钮按下时触发短暂视觉脉冲：暖光闪亮再消散，给触控/鼠标点击明确反馈
## scale 弹跳提到 1.16，modulate 更亮；调用方应先设 pivot_offset=size/2
func _pulse_button(btn: Button) -> void:
	if btn == null:
		return
	if bool(TuningStore.get_value("ui.reduced_motion", false)):
		return
	if btn.pivot_offset == Vector2.ZERO and btn.size != Vector2.ZERO:
		btn.pivot_offset = btn.size * 0.5
	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(btn, "modulate", Color(1.70, 1.28, 0.78, 1.0), 0.07).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(btn, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# 同步 scale 弹跳（独立 tween，避免与 modulate 链冲突）
	var st := create_tween()
	st.tween_property(btn, "scale", Vector2(1.16, 1.16), 0.07).set_trans(Tween.TRANS_QUAD)
	st.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## 根据假期天数计算并应用季节底色（叠加在昼夜层之下）
## alpha 适当加强，使季节感更明显，配合昼夜层共同营造"假期很长"的感觉
func _update_season_tint(day: int) -> void:
	if _season_rect == null:
		return
	var sc: Color
	var alpha: float
	# REQ-005：压缩季节节奏，让新档在约一小时游玩内就能看见明显色调变化。
	# 一天仍是 600s 模拟；不引入任务或离席惩罚。
	if day <= 2:
		# 第 1-2 天：春意淡出
		sc = SEASON_COLORS.spring
		alpha = lerpf(0.02, 0.06, float(maxi(day, 1) - 1) / 1.0)
	elif day <= 4:
		# 第 3-4 天：盛夏，轻微暖绿
		sc = SEASON_COLORS.summer
		alpha = 0.03
	elif day <= 6:
		# 第 5-6 天：仲夏末，暖琥珀已可读
		sc = SEASON_COLORS.late_summer
		alpha = lerpf(0.06, 0.10, float(day - 5) / 1.0)
	else:
		# 第 7 天起：金秋，上限 0.14
		sc = SEASON_COLORS.autumn
		alpha = minf(0.14, 0.10 + float(day - 7) * 0.01)
	_season_rect.color = Color(sc.r, sc.g, sc.b, alpha)


## One persisted day starts at 06:00. Blend continuously through midnight
## and the 06:00 save-day boundary; phase and clouds use the same clock.
func _update_tod_tint(t: float) -> void:
	if _tod_rect != null:
		_tod_rect.color = preload("res://scripts/game/world_daylight.gd").tint(t, TOD_COLORS)


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	_on_inventory_changed()
	if _photo_arrival != null:
		_photo_arrival.refresh_locale()
	if _album_screen != null and _album_screen.visible:
		_rebuild_album(_world.collected if _world != null else PackedStringArray(SaveStore.get_album()))


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
	_music_toggle.text = I18n.t("pause.music_off" if AudioDirector.music_enabled() else "pause.music_on")
	_ambience_toggle.text = I18n.t("pause.ambience_off" if AudioDirector.ambience_enabled() else "pause.ambience_on")
	_mute_toggle.text = I18n.t("pause.mute_on" if bool(TuningStore.get_value("audio.master.muted", false)) else "pause.mute_off")
	_refresh_volume_labels()
	_confirm_title.text = I18n.t("confirm.heading")
	_confirm_message.text = I18n.t("confirm.title" if _pending_destructive_action == "title" else "confirm.restart")
	_confirm_accept_button.text = I18n.t("confirm.accept")
	_confirm_cancel_button.text = I18n.t("confirm.cancel")
	_album_title.text = I18n.t("album.title")
	_album_previous_button.text = I18n.t("album.previous")
	_album_next_button.text = I18n.t("album.next")
	_album_back_button.text = I18n.t("album.back")
	# P0.2: locale 切换时同步更新相册 tooltip。
	if _album_chip != null:
		_album_chip.tooltip_text = I18n.t("hud.album.tooltip")
	if _save_status_message != null:
		_save_status_message.text = I18n.t("notice.save.pending")
		_save_retry_button.text = I18n.t("save.retry")
	if _world != null:
		_refresh_hud()
	_fit_save_status()


func _label(size_px: int, color: Color) -> Label:
	var result := Label.new()
	result.add_theme_font_size_override("font_size", size_px)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## 暖纸主按钮（标题、暂停、确认、相册、存档重试共用）。原来只设了普通/悬停字色，
## 键盘焦点和按下落回 Godot 默认近白字（对 CREAM 约 1.1:1），点过「音乐开着 · 关掉」等
## 留在原页的按钮后鼠标移开，字就几乎看不见；焦点框是盖住底色的 3px 淡紫（约 1.8:1）。
## 现在焦点/按下都用深墨字（≥4.5:1），焦点改为不填底、外扩 2px 的 TITLE_ACCENT 描边
## （≥3:1），原有底色与杏色边保持可见（REQ-20261006-036）。
## 禁用态（相册首/末页的翻页、存档确认中的「再确认一次」、备份恢复页处理中）原来也落回
## Godot 默认：灰褐实心块（#aa9d8b）上半透明浅字，约 1.4:1，像一块没字的灰砖，和暖纸界面
## 不搭。现在用淡一档的暖纸底、1px 浅棕边、柔墨字（≥4.5:1，仍比可点时浅），一看就是「暂时
## 不能点」但字照样读得出（REQ-20261006-038）。
const SOFT_DISABLED_FILL := Color("f3e9db")
const SOFT_DISABLED_EDGE := Color("bfa588")
const SOFT_DISABLED_TEXT := Color("7a6152")


func _soft_button() -> Button:
	var result := Button.new()
	result.custom_minimum_size = Vector2(260, 44)
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_size_override("font_size", 16)
	result.add_theme_color_override("font_color", INK)
	result.add_theme_color_override("font_hover_color", TEXT_LINK_HOVER)
	result.add_theme_color_override("font_focus_color", INK)
	result.add_theme_color_override("font_pressed_color", INK)
	result.add_theme_color_override("font_hover_pressed_color", TEXT_LINK_HOVER)
	result.add_theme_stylebox_override("normal", _flat(CREAM, APRICOT))
	result.add_theme_stylebox_override("hover", _flat(Color("ffe7c8"), SAGE))
	result.add_theme_stylebox_override("pressed", _flat(Color("f3d3ae"), INK))
	result.add_theme_stylebox_override("focus", _soft_focus_ring())
	result.add_theme_color_override("font_disabled_color", SOFT_DISABLED_TEXT)
	result.add_theme_stylebox_override("disabled", _flat(SOFT_DISABLED_FILL, SOFT_DISABLED_EDGE, 1))
	return result


func _soft_focus_ring() -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.set_border_width_all(2)
	ring.border_color = TITLE_ACCENT
	ring.set_corner_radius_all(18)
	ring.set_expand_margin_all(2.0)
	return ring


func _chip_button() -> Button:
	var result := _soft_button()
	result.custom_minimum_size = Vector2(188, 40)
	result.mouse_filter = Control.MOUSE_FILTER_STOP
	return result


## 标题页「开源软件声明」等纸卡上的文字链接。原来只设了 font_color（MUTED，在 PAPER 上约 4.3:1），
## 悬停/键盘焦点/按下都落回 Godot 默认的近白字和近白焦点框，在浅色纸卡上几乎看不见（#413）。
## 各态都改用深墨色：在纯 PAPER 和 84% 纸卡叠黑底两端都 ≥4.5:1；悬停更深；焦点画 2px TITLE_ACCENT 描边、不填底（REQ-20261006-035）。
func _text_button() -> Button:
	var result := Button.new()
	result.flat = true
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_color_override("font_color", TEXT_LINK)
	result.add_theme_color_override("font_focus_color", INK)
	result.add_theme_color_override("font_hover_color", TEXT_LINK_HOVER)
	result.add_theme_color_override("font_pressed_color", INK)
	result.add_theme_color_override("font_hover_pressed_color", TEXT_LINK_HOVER)
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.set_border_width_all(2)
	ring.border_color = TITLE_ACCENT
	ring.set_corner_radius_all(8)
	result.add_theme_stylebox_override("focus", ring)
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
