extends Node2D
## Cosmetic director: the durable morning has already committed. The actual
## player stays occluded indoors until this proxy has returned through the door.
const Walker := preload("res://scripts/entities/sequence_resident.gd")
const SUNNY := preload("res://assets/holiday/environment/yard_sunny.png")
const ACTIONS := preload("res://assets/holiday/characters/resident_balcony_v1/actions.png")
const ROOM := preload("res://assets/holiday/environment/house_open.png")
const DOOR := Vector2(285, 294)
const SPOT := Vector2(248, 299)
const RAIL := Rect2(221, 267, 142, 52)
const OPENING := Rect2(267, 227, 34, 48)
const ACTIVITIES := ["stretch", "doze", "coffee", "look", "brush"]
var stage := ""
var seconds := 0.0
var activity := ""
var door_amount := 0.0
var walker: AnimatedSprite2D
var pose: Sprite2D
var world: Node2D
var cancelled := false
class Foreground extends Node2D:
	var director: Node2D
	func _draw() -> void: director.draw_rail(self)
var foreground: Node2D
var frames: Array[AtlasTexture] = []

static func plan(day: int, weather: String) -> String:
	if day < 1 or weather == "rain": return ""
	# One randomly selected morning per three-day block. A rotating bag gives
	# five different events before repeating, without a new persistent counter.
	var block: int = (day - 1) / 3
	var rng := RandomNumberGenerator.new()
	rng.seed = 641031 + block * 7919
	if (day - 1) % 3 != rng.randi_range(0, 2): return ""
	return ACTIVITIES[block % ACTIVITIES.size()]

func _init(owner_world: Node2D) -> void:
	world = owner_world
	z_index = 2
	walker = Walker.new()
	add_child(walker)
	pose = Sprite2D.new()
	pose.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pose.centered = false
	pose.scale = Vector2.ONE * 0.14
	pose.position = SPOT
	add_child(pose)
	for row: int in 2:
		for column: int in 5:
			var frame := AtlasTexture.new()
			frame.atlas = ACTIONS
			frame.region = Rect2(column * 323.8, row * 485.5, 323.8, 485.5)
			frame.filter_clip = true
			frames.append(frame)
	foreground = Foreground.new()
	foreground.director = self
	foreground.z_index = 1
	add_child(foreground)
	visible = false

func begin(kind: String) -> void:
	assert(kind in ACTIVITIES)
	activity = kind
	cancelled = false
	visible = true
	walker.position = DOOR
	walker.visible = true
	walker.modulate.a = 0.0
	pose.visible = false
	_enter("open")

func busy() -> bool: return not stage.is_empty()

func skip() -> void:
	if not busy(): return
	cancelled = true
	if stage == "open":
		walker.visible = false
		_enter("close")
		return
	if stage in ["open", "emerge", "walk", "activity"]:
		pose.visible = false
		walker.visible = true
		_enter("return")

func _enter(next: String) -> void:
	stage = next
	seconds = 0.0

func tick(delta: float, reduced: bool) -> void:
	if not busy(): return
	seconds += delta
	match stage:
		"open":
			door_amount = minf(seconds / 0.7, 1.0)
			if seconds >= 0.9: _enter("emerge")
		"emerge":
			walker.modulate.a = minf(seconds / 0.5, 1.0)
			if seconds >= 0.5: _enter("walk")
		"walk":
			if _walk(delta, SPOT, reduced):
				walker.visible = false
				pose.visible = true
				_enter("activity")
				_show_pose(reduced)
		"activity":
			_show_pose(reduced)
			if seconds >= 6.5:
				pose.visible = false
				walker.visible = true
				_enter("return")
		"return":
			if _walk(delta, DOOR, reduced): _enter("inside")
		"inside":
			walker.modulate.a = move_toward(walker.modulate.a, 0.0, delta / 0.5)
			if seconds >= 0.5:
				walker.visible = false
				_enter("close")
		"close":
			door_amount = move_toward(door_amount, 0.0, delta / 0.7)
			if seconds >= 0.9:
				stage = ""
				visible = false
	queue_redraw()
	foreground.queue_redraw()

func _walk(delta: float, destination: Vector2, reduced: bool) -> bool:
	var before := walker.position
	walker.position = before.move_toward(destination, 24.0 * delta)
	var moved := walker.position - before
	walker.advance(delta, moved, 0.7, -1.0 if destination.x < before.x else 1.0, reduced)
	return walker.position.is_equal_approx(destination)

func _show_pose(reduced: bool) -> void:
	var column := ACTIVITIES.find(activity)
	# These are two distinct painted keys, never a stretched/rotated full body.
	# Hold quiet keys; brushing has a quicker hand stroke. Low motion holds A.
	var interval := 0.65 if activity == "brush" else 1.35
	var row := 0 if reduced else int(seconds / interval) % 2
	pose.texture = frames[row * 5 + column]
	var foot_x: float = [190.0, 520.0, 827.0, 1140.0, 1450.0][column]
	pose.offset = -Vector2(foot_x - column * 323.8, 479.0 if row == 0 else 469.0)

func _draw() -> void:
	if not visible: return
	# Swing the original painted halves, rather than replacing the house art.
	var tint: Color = world._backdrop.modulate
	# Reuse the accepted room painting (books, bed and warm plaster), not a
	# flat black rectangle. Only the interior is visible behind the hinged art.
	var room_tint := tint
	room_tint.a *= door_amount
	draw_texture_rect_region(ROOM, OPENING, Rect2(440, 440, 260, 530), room_tint)
	for half: int in 2:
		var source := Rect2(OPENING.position * 1.5 + Vector2(half * 25.5, 0), Vector2(25.5, 72))
		var width := 17.0 * (1.0 - 0.88 * door_amount)
		var left := OPENING.position.x if half == 0 else OPENING.end.x - width
		var destination := Rect2(left, OPENING.position.y, width, OPENING.size.y)
		draw_texture_rect_region(SUNNY, destination, source, tint)
		var blend = world._weather_backdrop_blend
		if blend.visible and blend.modulate.a > 0.0:
			draw_texture_rect_region(blend.texture, destination, source, blend.modulate)

func draw_rail(canvas: CanvasItem) -> void:
	if not visible: return
	var source := Rect2(RAIL.position * 1.5, RAIL.size * 1.5)
	canvas.draw_texture_rect_region(SUNNY, RAIL, source, world._backdrop.modulate)
	var blend = world._weather_backdrop_blend
	if blend.visible and blend.modulate.a > 0.0:
		canvas.draw_texture_rect_region(blend.texture, RAIL, source, blend.modulate)
