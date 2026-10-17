extends Node2D
## Sprite-only confirmed garden; PhotoMoment freezes the atlas cell and tint.
const Ledger := preload("res://scripts/game/yard_garden.gd")
const Schedule := preload("res://scripts/game/growth_schedule.gd")
const ART_PATH := "res://assets/holiday/props/garden_v1/flower-garden-atlas-v1.png"
const ANCHOR := Vector2(450,535)
const APPROACH := Vector2(430,550)
const WIDTH := 64.0
var store: Node
var art: Sprite2D
var intent: Label
var confirmed := {}

func _init(save_store: Node = null) -> void:
	store = save_store
	name = "YardGarden"
	position = ANCHOR
	z_as_relative = false
	z_index = roundi(position.y)
	art = Sprite2D.new()
	art.name = "ConfirmedFlowerBed"
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.hide()
	add_child(art)
	intent = Label.new()
	intent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent.add_theme_font_size_override("font_size",15)
	intent.add_theme_color_override("font_color",Color(0.22,0.19,0.13))
	intent.add_theme_color_override("font_shadow_color",Color(1.0,0.96,0.84,0.95))
	intent.add_theme_constant_override("shadow_outline_size",4)
	intent.position = Vector2(-65,-62)
	intent.hide()
	add_child(intent)

static func texture(cell: int) -> Texture2D:
	if not ResourceLoader.exists(ART_PATH): return null
	var atlas := load(ART_PATH) as Texture2D
	var frame := AtlasTexture.new()
	frame.atlas = atlas
	frame.region = Rect2(clampi(cell,0,2)*atlas.get_width()/3.0,0,atlas.get_width()/3.0,atlas.get_height())
	frame.filter_clip = true
	return frame

func _ready() -> void:
	store.commit_confirmed.connect(_confirmed)
	refresh()

func _exit_tree() -> void:
	if is_instance_valid(store) and store.commit_confirmed.is_connected(_confirmed): store.commit_confirmed.disconnect(_confirmed)

func _confirmed(_id: String, _kind: String) -> void: refresh()

func refresh() -> void:
	confirmed = store.get_yard_garden()
	sync_day(store.get_holiday_day())

func sync_day(day: int) -> void:
	art.visible = not confirmed.is_empty() and confirmed.revision == 1
	if not art.visible: return
	var cell := 2 if day >= int(confirmed.receipts[0].day)+Schedule.GARDEN_BLOOM_DAYS else 1
	if art.get_meta("garden_cell",-1) == cell: return
	var frame := texture(cell)
	if frame == null:
		art.hide()
		return
	art.set_meta("garden_cell",cell)
	art.texture = frame
	art.scale = Vector2.ONE * WIDTH / frame.get_width()
	# Artwork uses a low earth contact line, independent of its taller flowers.
	art.offset = Vector2(0,-frame.get_height()*0.28)

func sync_work(active: bool, phase: String) -> void:
	intent.visible = active and phase in ["fetching","taking","walking","working"]
	intent.text = "取些花种，种下一小畦花" if TranslationServer.get_locale().begins_with("zh") else "Seeds for a little flower bed"

func sync_environment(mix: float, sun: Color, rain: Color) -> void:
	modulate = sun.lerp(rain,clampf(mix,0.0,1.0))
