class_name PathCompanion
extends Node2D
## A scene representation of an existing resident, not a second persistent animal.
const L := preload("res://scripts/exploration/near_path_layout.gd")
var layout: PaintedPath = L.geometry()
var choice: Dictionary = {}
var actor: FeltActor
var spot: Dictionary = {}
var rope: Line2D
var search_cel: Sprite2D
var search_spot: Dictionary = {}
var search_elapsed := 0.0
var return_to_side := false
const SEARCH_SECONDS := 2.4
const SEARCH_ANCHOR := Vector2(475, 1063)
const SEARCH_SCALE := 0.91 # Match back-to-hoof height and hoof span, not lowered head height.

func start_search(stop: Dictionary) -> void:
	if choice.get("actor_id", "") != "llama": return
	return_to_side = false
	search_spot = {"arm": stop.arm, "d": stop.d}
	search_elapsed = 0.0

func cancel_search() -> void:
	if not search_spot.is_empty(): return_to_side = true
	search_spot = {}
	search_elapsed = 0.0
	actor.visible = true
	if search_cel != null: search_cel.visible = false

func search_complete() -> bool:
	return not search_spot.is_empty() and search_elapsed >= SEARCH_SECONDS

func setup(value: Dictionary, leader_spot: Dictionary, page: PaintedPath = null, resident_stage: String = "grown") -> void:
	if page != null: layout = page
	choice = value.duplicate(true)
	var species: String = AnimalCompanions.SPECIES[choice.actor_id]
	actor = FeltActor.new()
	add_child(actor)
	if choice.actor_id == "beibei":
		actor.setup(BeibeiArt.configure(resident_stage))
	else:
		actor.setup(CastArt.configure({"id": choice.actor_id, "species": species, "scale": CastArt.LEGACY_SCALE[species], "textures": {"idle": CastArt.texture_path(species)}}))
	actor.facing = -1.0
	spot = {"arm": leader_spot.arm, "d": minf(float(leader_spot.d) + 65.0, layout.arm_length(leader_spot.arm))}
	actor.position = feet()
	actor.advance_path(0.0, Vector2.ZERO, layout.depth(actor.position.y), true)
	rope = Line2D.new()
	rope.width = 2.0
	rope.default_color = Color(0.38, 0.25, 0.13, 0.9)
	rope.antialiased = true
	rope.begin_cap_mode = Line2D.LINE_CAP_ROUND
	rope.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(rope)
	rope.visible = choice.mode == "rope"
	if choice.actor_id == "llama":
		search_cel = Sprite2D.new()
		search_cel.texture = load("res://assets/holiday/characters/cast_v2/llama_search.png")
		search_cel.centered = false
		search_cel.offset = -SEARCH_ANCHOR
		search_cel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		search_cel.visible = false
		add_child(search_cel)

func feet() -> Vector2:
	var point := layout.point(spot.arm, spot.d)
	# A small shoulder-to-shoulder clearance stays inside the painted lane.
	var side := 30.0 if choice.get("actor_id", "") == "beibei" else -14.0
	return point + layout.tangent(spot.arm, spot.d).orthogonal() * side * layout.depth(point.y)

func advance(delta: float, leader_spot: Dictionary, walker: SequenceResident, reduced: bool) -> void:
	var before := actor.position
	var target := leader_spot if search_spot.is_empty() else search_spot
	if return_to_side and search_spot.is_empty():
		target = {"arm": leader_spot.arm, "d": minf(float(leader_spot.d) + 80.0, layout.arm_length(leader_spot.arm))}
	var gap := layout.route_length(spot, target)
	var spacing := (80.0 if choice.actor_id == "beibei" else 60.0) * layout.depth(walker.position.y) if search_spot.is_empty() else 0.0
	if return_to_side: spacing = 0.0
	if gap > spacing:
		spot = layout.step_toward(spot, target, minf(gap - spacing, layout.WALK_SPEED * 1.25 * delta))
	actor.position = feet()
	actor.advance_path(delta, actor.position - before, layout.depth(actor.position.y), reduced)
	if return_to_side and layout.route_length(spot, target) < 1.0: return_to_side = false
	if not search_spot.is_empty() and layout.route_length(spot, target) < 1.0:
		search_elapsed += delta
		actor.visible = false
		search_cel.visible = true
		search_cel.position = actor.position
		search_cel.scale = Vector2.ONE * actor._base_scale * layout.depth(actor.position.y) * SEARCH_SCALE
		search_cel.z_index = actor.z_index
	if rope.visible:
		var palm := Vector2(242, 253)
		if walker.animation == &"walk": palm = Vacationer.GRASS_SEQUENCE_HAND[walker.frame % Vacationer.GRASS_SEQUENCE_HAND.size()]
		var hand := to_local(walker.to_global(walker.offset + palm))
		var collar := to_local(actor.to_global(Vector2(875, 665) - actor._ground_anchor))
		if search_cel != null and search_cel.visible:
			collar = search_cel.position + (Vector2(837, 737) - SEARCH_ANCHOR) * search_cel.scale
		var middle := (hand + collar) * 0.5 + Vector2(0, 8)
		var points := PackedVector2Array()
		for i in 17:
			var t := float(i) / 16.0
			points.append(hand.lerp(middle, t).lerp(middle.lerp(collar, t), t))
		rope.points = points
		rope.z_index = maxi(actor.z_index, walker.z_index) + 2
	queue_redraw()

func _draw() -> void:
	if actor == null: return
	var radius := actor.body_radius * Vector2(1.0, 0.42) * layout.depth(actor.position.y)
	draw_set_transform(actor.position + Vector2(0, 1), 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(0.29, 0.25, 0.16, 0.12))
	draw_set_transform(Vector2.ZERO)
