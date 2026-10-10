class_name ResidentIdleRest
extends Node2D

# Cosmetic outdoor rest only. HouseSleep remains the sole sleep/day-skip owner.
const ATLAS := preload("res://assets/holiday/characters/resident_idle_rest_v1/poses.png")
const SIT_AFTER := 45.0
const NAP_AFTER := 90.0
const REGIONS := [Rect2(108,33,223,515), Rect2(523,195,248,357), Rect2(959,209,317,338), Rect2(1353,218,374,328), Rect2(36,621,409,238), Rect2(478,672,407,175), Rect2(922,672,409,175), Rect2(1460,546,241,331)]
# Contacts are authored per cel, not inferred from uniform atlas cells.
const CONTACTS := [Vector2(219,540), Vector2(646,540), Vector2(1097,538), Vector2(1515,538), Vector2(233,844), Vector2(679,834), Vector2(1124,834), Vector2(1580,858)]
const SCALES := [0.210,0.180,0.180,0.180,0.180,0.180,0.180,0.180]
var stage := ""
var idle_seconds := 0.0
var elapsed := 0.0
var pose: Sprite2D
var textures: Array[AtlasTexture] = []
var cel := 0
var ground_scale := 1.0

func _ready() -> void:
	pose = Sprite2D.new()
	pose.centered = false
	pose.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(pose)
	for region: Rect2 in REGIONS:
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = region
		texture.filter_clip = true
		textures.append(texture)
	visible = false

func active() -> bool: return not stage.is_empty()
func getting_up() -> bool: return stage == "rise"

func clear() -> void:
	stage = ""
	idle_seconds = 0.0
	elapsed = 0.0
	visible = false

func wake(reduced: bool = false) -> void:
	idle_seconds = 0.0
	if not active(): return
	if reduced:
		clear()
	elif stage != "rise":
		stage = "rise"
		elapsed = 0.0

func advance(delta: float, allowed: bool, depth: float, face: float, reduced: bool, visual_scale: float) -> void:
	if not allowed:
		wake(reduced)
	if not active():
		if allowed:
			idle_seconds += delta
			if idle_seconds >= SIT_AFTER:
				stage = "sit" if reduced else "lower"
				elapsed = 0.0
	else:
		elapsed += delta
		match stage:
			"lower":
				if elapsed >= 0.75: stage = "sit"; elapsed = 0.0
			"sit":
				if elapsed >= NAP_AFTER: stage = "nap" if reduced else "recline"; elapsed = 0.0
			"recline":
				if elapsed >= 1.4: stage = "nap"; elapsed = 0.0
			"rise":
				if elapsed >= 0.36: clear()
	visible = active()
	if not visible: return
	match stage:
		"lower": cel = 0 if elapsed < 0.12 else (1 if elapsed < 0.52 else 2)
		"sit": cel = 2
		"recline": cel = 3 if elapsed < 0.45 else (4 if elapsed < 0.95 else 5)
		"nap": cel = 6
		"rise": cel = 7 if elapsed < 0.24 else 0
	ground_scale = depth * visual_scale
	pose.texture = textures[cel]
	pose.offset = REGIONS[cel].position - CONTACTS[cel]
	pose.scale = Vector2(face, 1.0) * SCALES[cel] * depth * visual_scale
	queue_redraw()

func _draw() -> void:
	if not active(): return
	# Soft contact ink stays on the ground; the painted body is never stretched.
	var width := 32.0 if stage in ["recline", "nap"] else 19.0
	draw_set_transform(Vector2(0,-1),0,Vector2(width,3.0) * ground_scale)
	draw_circle(Vector2.ZERO,1.0,Color(0.20,0.22,0.14,0.12))
