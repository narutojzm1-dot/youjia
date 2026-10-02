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
var _hint_panel: Panel
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
var _latest_photo := ""
var _last_touch_ms := -1000
# 假期天数标签
var _day_label: Label
# 昼夜色调覆盖层
var _tod_canvas: CanvasLayer
var _tod_rect: ColorRect
# 季节底色（渲染在昼夜层之下，随假期天数推进）
var _season_rect: ColorRect
# 拍立得入账时短暂亮一次屏，提示照片已捕获。
var _photo_flash: ColorRect
var _photo_arrival: PhotoArrival
var _photo_arrival_queue: Array[Dictionary] = []
## 钓到鱼时的蓝色庆祝闪光（独立于拍立得闪光，更冷更蓝）
var _fish_flash: ColorRect
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
	_photo_arrival = PhotoArrival.new()
	_photo_arrival.name = "PhotoArrival"
	_ui_layer.add_child(_photo_arrival)
	_photo_arrival.tucked_away.connect(_on_photo_tucked)
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
	_camera.position = home + _cam_offset + player_follow + Vector2(0,hud_space/(2.0*zoom))
	if _screen == "game":
		_refresh_hud()
		# 更新昼夜色调覆盖层与季节底色
		if _world != null:
			var tod := _world.tod_fraction()
			_update_tod_tint(tod)
			_update_season_tint(_world.holiday_day)
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
		elif _screen == "game":
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
		buttons = [_resume_button, _restart_button, _pause_title_button]
	elif _album_screen.visible:
		buttons = [_album_previous_button, _album_next_button, _album_back_button]
	elif _screen == "title":
		buttons = [_play_button, _album_button, _licenses_button]
	else:
		buttons = [_action_button, _album_chip, _weather_chip, _pause_button]
	# get_global_rect() 在 web 导出的 CanvasLayer 中比 get_global_transform_with_canvas() 更可靠
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled and button.get_global_rect().has_point(event_pos):
			_last_touch_ms = Time.get_ticks_msec()
			button.pressed.emit()
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
	# 触屏和鼠标世界点击：触屏已在 _input() 中更新 _last_touch_ms，此处只处理
	# 真正落到世界画布上的点击（HUD 命中测试未拦截的情况）。
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec() - _last_touch_ms > 400:
			_world.request_pointer_action(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		# 触屏已在 _input() 中标记时间戳；此分支只处理落到世界的触点
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
	_hint_panel = Panel.new()
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.add_theme_stylebox_override("panel", _flat(Color(PAPER, 0.90), Color(APRICOT, 0.65), 1, 12))
	_hud.add_child(_hint_panel)
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
	# _show_album() 内部已调用 _pulse_button，此处直接连接即可
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
	_world.fish_caught.connect(_on_fish_caught)
	_camera.enabled = true
	_portrait_camera_x = _world.get_player().position.x
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
	# HUD 可见后立即重算布局，确保相册等按钮落在正确点击区域（同帧 + 延迟各执行一次）
	_layout()
	call_deferred("_layout")
	_idle_hint_timer = 55.0  # 进院后55秒内不显示空闲提示，让玩家先看看
	_first_hint_shown = false
	_last_tod_phase = ""
	_show_notice_key("notice.arrive")
	_refresh_hud()
	# 首次进院（第1天且相册为空）时，延迟发送柔性引导提示
	if _world.holiday_day == 1 and SaveStore.get_album().is_empty():
		_show_delayed_soft_hint()


func _clear_world() -> void:
	_cancel_photo_arrivals()
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
	if paused:
		_cancel_photo_arrivals()
	_pause_screen.visible = paused
	get_tree().paused = paused
	AudioDirector.set_game_paused(paused)
	if _world != null:
		_world.input_enabled = not paused
		if paused: _world.cancel_scene_feedback()
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
	var saved := SaveStore.set_album(collected,_world.photo_moments if _world != null else {})
	if fresh and saved:
		_latest_photo = latest_id
		var snapshot := SaveStore.get_photo_moment(latest_id)
		if not snapshot.is_empty() and _photo_arrival != null and _screen == "game":
			_photo_arrival_queue.append(snapshot)
			if not _photo_arrival.visible:
				_play_next_photo_arrival()
		else:
			_show_notice_key("notice.photo.saved")
	_refresh_hud()
	if _album_screen.visible: _rebuild_album(collected)


func _play_next_photo_arrival() -> void:
	if _photo_arrival_queue.is_empty() or _photo_arrival == null:
		return
	var snapshot: Dictionary = _photo_arrival_queue.pop_front()
	_flash_photo()
	_photo_arrival.play(snapshot, _album_chip.get_global_rect().get_center(),
		bool(TuningStore.get_value("ui.reduced_motion", false)))


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
		return
	_show_notice_key("notice.photo.saved")
	_pulse_button(_album_chip)


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


func _hide_album() -> void:
	_album_screen.visible = false
	_album_touch_origin = Vector2.INF
	if _screen == "game": _hud.visible = true
	if _world != null and not _pause_screen.visible:
		_world.input_enabled = true


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
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	var card_width := minf(280.0, minf(_album_page_size.x - 52.0, (_album_page_size.y - 138.0) * 0.8))
	center.add_child(_photo_card(rule, true, card_width))
	var note := _label(14, INK)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.y = 36.0
	note.text = I18n.t(str(rule.get("note_key", "")))
	content.add_child(note)
	var footer := _label(12, MUTED)
	footer.text = I18n.t("album.page", {"page": str(index + 1)})
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(footer)
	return page


func _photo_card(rule: Dictionary, owned: bool, width: float = 240.0) -> Control:
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
	var caption := _label(maxi(12, roundi(13.0 * card_scale)), INK if owned else MUTED)
	caption.position = Vector2(24, 232) * card_scale
	caption.size = Vector2(192, 52) * card_scale
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.text = (PhotoDiary.caption(moment, str(rule.get("id", "")))
		if owned and not moment.is_empty() else
		I18n.t(str(rule.get("title_key", ""))) if owned else I18n.t("album.empty_slot"))
	holder.add_child(caption)
	return holder


func _on_focus(world_point: Vector2, zoom: float) -> void:
	_cam_target_zoom = zoom
	var home := YardWorld.WORLD_SIZE * 0.5
	var portrait := size.x < 700.0 and size.y > size.x
	if portrait: home.x = _portrait_camera_x
	_cam_target_offset = (world_point - home) * (1.0 if portrait else 0.35)


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
	# 每次普通通知都重置字体大小（钓到鱼/空闲提示会在后续覆盖为更大字号）
	_notice.add_theme_font_size_override("font_size", 16)


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
	var was_two_pages := _album_two_pages
	_album_two_pages = album_width >= 670.0 and size.y >= 460.0
	var book_width := album_width - 32.0
	var book_height := album_height - 122.0
	_album_spread.custom_minimum_size = Vector2(book_width, book_height)
	_album_previous_button.get_parent().custom_minimum_size = Vector2(book_width, 42)
	_album_page_size = Vector2((book_width - 10.0) * 0.5 if _album_two_pages else book_width, book_height)
	if _album_screen.visible or was_two_pages != _album_two_pages:
		_render_album_pages()
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
	_hint_label.size = Vector2(minf(520.0,maxf(120.0,size.x-_pause_button.size.x-pad*3.0)), 64 if compact else 48)
	_hint_panel.position = Vector2(pad-9.0, 9.0)
	_hint_panel.size = _hint_label.size + Vector2(18.0, 16.0)
	# 天数标签居中顶部
	if _day_label != null:
		_day_label.size = Vector2(160, 28)
		_day_label.position = Vector2(pad, pad + 80.0) if compact else Vector2(size.x * 0.5 - 80.0, pad)
	var row := size.y-124.0 if compact else size.y-68.0
	_album_chip.position = Vector2(pad,row)
	_weather_chip.position = Vector2(size.x-half-pad if compact else pad+210.0,row)
	_action_button.position = Vector2(pad if compact else size.x-_action_button.size.x-pad,size.y-68.0)


func _refresh_hud() -> void:
	if _world == null:
		return
	_hud.modulate.a = float(TuningStore.get_value("ui.hud.opacity", 0.94))
	_album_chip.text = I18n.t("hud.album")
	_weather_chip.text = I18n.t("hud.weather.%s" % _world.weather)
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
	# 更新假期天数标签
	if _day_label != null:
		_day_label.text = I18n.t("hud.day", {"n": str(_world.holiday_day)})


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
	# 钓到通知：无论是否减动效都拉长可读时间（拍立得可能抢通知，YardWorld 会重发）
	_notice_time = maxf(_notice_time, 6.5)
	_notice.add_theme_font_size_override("font_size", 22)
	_notice.visible = true
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
	if t < 0.10: return "dawn"
	if t < 0.30: return "morning"
	if t < 0.55: return "noon"
	if t < 0.72: return "afternoon"
	if t < 0.87: return "evening"
	return "night"


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


## 根据 tod_fraction (0.0-1.0) 计算并应用昼夜渐变覆盖色
## 0.0 = 日出, 0.5 = 正午, 0.85 = 黄昏, 1.0 = 深夜
## alpha 加强约 1.5x，让昼夜变化肉眼可见，假期"很长"的感觉更明显
func _update_tod_tint(t: float) -> void:
	if _tod_rect == null:
		return
	var base_color: Color
	var alpha: float
	if t < 0.10:
		# 日出：金橙暖光（更明显）
		base_color = TOD_COLORS.dawn
		alpha = lerpf(0.14, 0.08, t / 0.10)
	elif t < 0.25:
		# 早晨：淡金渐隐
		base_color = TOD_COLORS.morning
		alpha = lerpf(0.08, 0.02, (t - 0.10) / 0.15)
	elif t < 0.55:
		# 正午：几乎无色
		base_color = TOD_COLORS.noon
		alpha = 0.0
	elif t < 0.72:
		# 下午：暖琥珀渐强（加深约50%）
		base_color = TOD_COLORS.afternoon
		alpha = lerpf(0.0, 0.14, (t - 0.55) / 0.17)
	elif t < 0.87:
		# 傍晚/黄昏：桃橙（更浓郁）
		var frac := (t - 0.72) / 0.15
		base_color = TOD_COLORS.afternoon.lerp(TOD_COLORS.evening, frac)
		alpha = lerpf(0.14, 0.24, frac)
	else:
		# 夜晚：蓝紫（更深沉）
		var frac := (t - 0.87) / 0.13
		base_color = TOD_COLORS.evening.lerp(TOD_COLORS.night, frac)
		alpha = lerpf(0.24, 0.32, frac)
	_tod_rect.color = Color(base_color.r, base_color.g, base_color.b, alpha)


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
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
