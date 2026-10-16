extends Node2D
## Ordinary sprite children are frozen by PhotoMoment, including the atlas cell.
## Only confirmed receipts advance art. Working material/callout is temporary.
const Ledger := preload("res://scripts/game/yard_stove.gd")
const ART := preload("res://assets/holiday/props/stove_v1/stove-stages-watercolor-v1.png")
## Foreground lawn keeps the work surface out of the basket/resident cluster.
const ANCHOR := Vector2(365,558)
const APPROACH := Vector2(410,565)
const WORK_POINT := Vector2(395,538)
const RADIUS := Vector2(29,10)
const WIDTH := 86.0
var store: Node
var art: Sprite2D
var intent: Label
var confirmed := {}
var working := false

func _init(save_store: Node = null) -> void:
	store = save_store
	name = "YardStove"
	position = ANCHOR
	z_as_relative = false
	z_index = roundi(position.y)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art = Sprite2D.new()
	art.name = "ConfirmedStoveStage"
	art.centered = false
	var cell := float(ART.get_width()) / 3.0
	art.offset = Vector2(-cell/2.0,-float(ART.get_height())*0.83)
	art.scale = Vector2.ONE * WIDTH / cell
	art.hide()
	add_child(art)
	intent = Label.new()
	intent.name = "ConstructionIntent"
	intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent.add_theme_font_size_override("font_size",15)
	intent.add_theme_color_override("font_color",Color(0.22,0.19,0.13))
	intent.add_theme_color_override("font_shadow_color",Color(1.0,0.96,0.84,0.95))
	intent.add_theme_constant_override("shadow_outline_size",4)
	intent.position = Vector2(-58,-78)
	intent.hide()
	add_child(intent)

func _ready() -> void:
	if store == null: store = get_node("/root/SaveStore")
	store.commit_confirmed.connect(_confirmed)
	refresh()

func _exit_tree() -> void:
	if is_instance_valid(store) and store.commit_confirmed.is_connected(_confirmed): store.commit_confirmed.disconnect(_confirmed)

func _confirmed(_id: String, kind: String) -> void:
	if kind == "growth": refresh()

func refresh() -> bool:
	return sync(store.get_yard_stove())

func sync(value: Dictionary) -> bool:
	var valid := Ledger.read({"holiday_day":2147483647,Ledger.FIELD:value})
	if valid.is_empty(): return false
	if valid == confirmed: return true
	confirmed = valid.duplicate(true)
	art.visible = int(valid.revision) > 0
	if art.visible:
		var cell := float(ART.get_width())/3.0
		var frame := AtlasTexture.new()
		frame.atlas = ART
		frame.region = Rect2((int(valid.revision)-1)*cell,0,cell,ART.get_height())
		frame.filter_clip = true
		art.texture = frame
	return true

func sync_work(active: bool, phase: String = "") -> void:
	working = active
	intent.visible = active and phase in ["fetching","taking","walking","working"]
	if not intent.visible: return
	var chinese := TranslationServer.get_locale().begins_with("zh")
	var index := int(confirmed.get("revision",0))
	var lines := ["搬些圆石，垒个小灶台", "把灶身垒起来", "给小灶台安上炉面"] if chinese else ["Stones for a little stove", "Building the stove body", "Fitting the cooking plate"]
	intent.text = lines[clampi(index,0,2)]

func sync_environment(mix: float, sun: Color, rain: Color) -> void:
	modulate = sun.lerp(rain,clampf(mix,0.0,1.0))
	art.modulate = Color.WHITE.lerp(Color(0.83,0.87,0.92),clampf(mix,0.0,1.0))
