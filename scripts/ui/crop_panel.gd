extends Control
## Modal view over authoritative SaveStore data. No optimistic crop/seed update.
signal close_requested
signal flower_requested
const Model := preload("res://scripts/game/yard_crops.gd")
const Art := preload("res://scripts/game/crop_art.gd")
var paper: PanelContainer
var heading: Label
var note: Label
var actions: VBoxContainer
var close_button: Button
var scroll: ScrollContainer
var column: VBoxContainer
var _op := ""
var _error := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.1,0.08,0.06,0.35)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	paper = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff7e8")
	style.border_color = Color("cfab79")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(20)
	paper.add_theme_stylebox_override("panel",style)
	add_child(paper)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroll.add_child(column)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",23)
	heading.add_theme_color_override("font_color",Color("5b4637"))
	column.add_child(heading)
	note = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color",Color("5b4637"))
	column.add_child(note)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	column.add_child(actions)
	close_button = _button("",func() -> void: close_requested.emit())
	column.add_child(close_button)
	resized.connect(_fit)
	SaveStore.commit_confirmed.connect(_confirmed)
	SaveStore.commit_rejected.connect(_rejected)
	SaveStore.commit_unknown.connect(_rejected)
	refresh()

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0,46)
	button.add_theme_font_size_override("font_size",17)
	for mode: String in preload("res://scripts/ui/yard_basket_panel.gd").BUTTON_STATES:
		button.add_theme_stylebox_override(mode,preload("res://scripts/ui/yard_basket_panel.gd").state_style(mode))
		button.add_theme_color_override("font_"+("" if mode == "normal" else mode+"_")+"color",Color("5b4637"))
	button.add_theme_color_override("font_focus_color",Color("5b4637"))
	button.pressed.connect(callback)
	return button

func _fit() -> void:
	if paper == null: return
	var width := minf(420.0,maxf(240.0,size.x-32.0))
	note.custom_minimum_size.x = width - 64.0
	scroll.custom_minimum_size = Vector2(width-40.0,minf(maxf(160.0,size.y-72.0),column.get_combined_minimum_size().y))
	paper.size = Vector2(width,scroll.custom_minimum_size.y+40.0)
	paper.position = (size-paper.size)*0.5

func refresh() -> void:
	if heading == null: return
	close_button.disabled = not _op.is_empty()
	var en := I18n.get_locale() == "en"
	heading.text = "A little growing patch" if en else "小小种植地"
	close_button.text = "Back to the yard" if en else "回到院子"
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	var bed := SaveStore.get_yard_crops()
	var inventory := SaveStore.get_yard_inventory()
	if bed.is_empty() or inventory.is_empty():
		note.text = "Save data needs attention." if en else "存档需要先处理一下。"
	elif not _op.is_empty():
		note.text = "Saving…" if en else "正在保存……"
	elif not _error.is_empty():
		note.text = "The patch has changed or could not be saved. Close and try again." if en else "地块有了变化，或这次还没保存好。请关上后再试一次。"
	elif bed.kind.is_empty():
		note.text = "Grains can be planted or fed to chickens. Keep one for planting." if en else "麦粒和玉米粒既能播种，也能喂鸡。留一把，来年还有。"
		for kind: String in Model.KINDS:
			var name := _name(kind,en)
			var count := int(inventory.get(kind,0))
			var label := ("Grow " if en else "种下")+name+("" if kind == "grass" else " · %d" % count)
			var button := _button(label,func() -> void: _request("plant",kind))
			button.icon = Art.texture(kind)
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width",36)
			button.disabled = kind != "grass" and count < 1
			actions.add_child(button)
		actions.add_child(_button("Grow flowers" if en else "种下小花",func() -> void: flower_requested.emit()))
	else:
		var day := SaveStore.get_holiday_day()
		var ripe := Model.mature(bed,day)
		note.text = (_name(bed.kind,en)+(" is ready to gather." if en else "已经可以收获了。")) if ripe else (_name(bed.kind,en)+(" is growing. Water once; it can wait for you." if en else "正在长。浇过水就慢慢等，不会枯萎。"))
		if not ripe:
			var remaining := maxi(0,int(bed.planted_day)+int(Model.DAYS[bed.kind])-day)
			note.text += (" Ready in %d day(s), after watering." if en else " 浇水后，再过%d天就能收。") % remaining
		var button := _button("Harvest into the basket" if en else "收获到背篓",func() -> void: _request("harvest")) if ripe else _button("Water" if en else "浇一浇水",func() -> void: _request("water"))
		button.disabled = not ripe and int(bed.watered_day) >= day
		if button.disabled: button.text = "Watered today" if en else "今天已经浇过水了"
		actions.add_child(button)
	call_deferred("_fit")

static func _name(kind: String, en: bool) -> String:
	return {"grass":"Grass","wheat":"Wheat","corn":"Corn"}.get(kind,kind) if en else {"grass":"青草","wheat":"麦子","corn":"玉米"}.get(kind,kind)

func _request(action: String, kind: String = "") -> void:
	if not _op.is_empty(): return
	var bed := SaveStore.get_yard_crops()
	var inventory := SaveStore.get_yard_inventory()
	if bed.is_empty() or inventory.is_empty(): return
	_op = SaveStore.request_crop_action(int(bed.revision),int(inventory.revision),action,kind)
	if _op.is_empty(): _error = "SAVE_UNAVAILABLE"
	refresh()

func open() -> void:
	_error = ""
	visible = true
	refresh()
	close_button.grab_focus()

func is_saving() -> bool:
	return not _op.is_empty()

func _confirmed(op_id: String, _kind: String) -> void:
	if op_id == _op: _op = ""
	refresh()

func _rejected(op_id: String, _kind: String, code: String) -> void:
	if op_id != _op: return
	# Unknown remains pending until resolved by the production save recovery UI.
	if SaveStore.persistence_state() != "unknown": _op = ""
	_error = code
	refresh()
