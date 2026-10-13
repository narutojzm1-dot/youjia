extends Control
## One selected original group; the action always follows confirmed storage.
signal close_requested
const BasketStyle := preload("res://scripts/ui/yard_basket_panel.gd")
var controller: RefCounted
var area := ""
var paper: PanelContainer
var heading: Label
var note: Label
var action_button: Button
var close_button: Button
var _focus_input: Node
var _scroll: ScrollContainer
var _column: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_focus_input = preload("res://scripts/ui/pointer_focus.gd").new()
	add_child(_focus_input)
	var shade := ColorRect.new()
	shade.color = Color(0.10,0.08,0.06,0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	paper = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff7e8")
	style.border_color = Color("cfab79")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	paper.add_theme_stylebox_override("panel",style)
	add_child(paper)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paper.add_child(_scroll)
	preload("res://scripts/ui/paper_scrollbar_style.gd").apply(_scroll.get_v_scroll_bar())
	_column = VBoxContainer.new()
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation",10)
	_scroll.add_child(_column)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",23)
	heading.add_theme_color_override("font_color",Color("5b4637"))
	_column.add_child(heading)
	note = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color",Color("5b4637"))
	_column.add_child(note)
	action_button = _button(_request)
	close_button = _button(func() -> void: close_requested.emit(),true)
	resized.connect(_fit)
	I18n.locale_changed.connect(func(_locale: String) -> void: refresh())
	refresh()

func _button(callback: Callable, cancel_cue: bool = false) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0,46)
	button.add_theme_font_size_override("font_size",17)
	for mode: String in BasketStyle.BUTTON_STATES:
		button.add_theme_stylebox_override(mode,BasketStyle.state_style(mode))
		button.add_theme_color_override("font_"+("" if mode == "normal" else mode+"_")+"color",Color("5b4637"))
	button.add_theme_stylebox_override("focus",BasketStyle.focus_style())
	button.add_theme_color_override("font_focus_color",Color("5b4637"))
	button.pressed.connect(callback)
	AudioDirector.register_button(button,cancel_cue)
	_column.add_child(button)
	return button

func open(selected_area: String) -> void:
	area = selected_area
	visible = true
	refresh()
	_focus_input.grab(action_button if not action_button.disabled else close_button)

func refresh() -> void:
	if heading == null: return
	heading.text = I18n.t("action.original_plants" if area.is_empty() else "garden.area."+area)
	close_button.text = I18n.t("garden.close")
	var state: Dictionary = controller.view() if controller != null else {}
	var busy: bool = controller != null and controller.busy()
	var retry: bool = busy and controller.state in ["failed","unknown"]
	close_button.disabled = busy
	action_button.disabled = state.is_empty() or (busy and not retry)
	if state.is_empty():
		note.text = I18n.t("garden.invalid")
		action_button.text = I18n.t("garden.remove")
	elif retry:
		note.text = I18n.t("garden.retry_note")
		action_button.text = I18n.t("garden.retry")
	elif busy:
		note.text = I18n.t("garden.saving")
		action_button.text = I18n.t("garden.saving")
	else:
		var removed: bool = area in state.removed
		note.text = I18n.t("garden.away" if removed else "garden.present")
		action_button.text = I18n.t("garden.restore" if removed else "garden.remove")
	# Keep keyboard traversal on this paper, including a single retry/close button.
	var action_next := action_button if close_button.disabled else close_button
	var close_next := close_button if action_button.disabled else action_button
	action_button.focus_next = action_next.get_path()
	action_button.focus_previous = action_next.get_path()
	close_button.focus_next = close_next.get_path()
	close_button.focus_previous = close_next.get_path()
	call_deferred("_fit")

func _request() -> void:
	if controller == null: return
	if controller.state in ["failed","unknown"]:
		controller.retry()
	elif not controller.busy():
		var state: Dictionary = controller.view()
		if not state.is_empty(): controller.request("restore" if area in state.removed else "remove",area)

func _fit() -> void:
	if paper == null: return
	var width := minf(400.0,maxf(200.0,size.x-32.0))
	note.custom_minimum_size.x = width - 52.0
	_scroll.custom_minimum_size = Vector2(width-36.0,minf(maxf(100.0,size.y-68.0),_column.get_combined_minimum_size().y))
	paper.size = Vector2(width,_scroll.custom_minimum_size.y+36.0)
	paper.position = (size-paper.size)*0.5
