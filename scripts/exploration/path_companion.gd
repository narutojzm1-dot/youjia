class_name PathCompanion
extends Node2D
## A scene representation of an existing resident, not a second persistent animal.
const L := preload("res://scripts/exploration/near_path_layout.gd")
var choice: Dictionary = {}
var actor: FeltActor
var spot: Dictionary = {}
var rope: Line2D

func setup(value: Dictionary, leader_spot: Dictionary) -> void:
	choice = value.duplicate(true)
	var species: String = AnimalCompanions.SPECIES[choice.actor_id]
	actor = FeltActor.new()
	add_child(actor)
	actor.setup(CastArt.configure({"id": choice.actor_id, "species": species, "scale": CastArt.LEGACY_SCALE[species], "textures": {"idle": CastArt.texture_path(species)}}))
	actor.facing = -1.0
	spot = {"arm": leader_spot.arm, "d": minf(float(leader_spot.d) + 65.0, L.arm_length(leader_spot.arm))}
	actor.position = feet()
	actor.advance_path(0.0, Vector2.ZERO, L.depth(actor.position.y), true)
	rope = Line2D.new()
	rope.width = 2.0
	rope.default_color = Color(0.38, 0.25, 0.13, 0.9)
	rope.antialiased = true
	rope.begin_cap_mode = Line2D.LINE_CAP_ROUND
	rope.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(rope)
	rope.visible = choice.mode == "rope"

func feet() -> Vector2:
	var point := L.point(spot.arm, spot.d)
	# A small shoulder-to-shoulder clearance stays inside the painted lane.
	return point - L.tangent(spot.arm, spot.d).orthogonal() * 14.0 * L.depth(point.y)

func advance(delta: float, leader_spot: Dictionary, walker: SequenceResident, reduced: bool) -> void:
	var before := actor.position
	var gap := L.route_length(spot, leader_spot)
	var spacing := 60.0 * L.depth(walker.position.y)
	if gap > spacing:
		spot = L.step_toward(spot, leader_spot, minf(gap - spacing, L.WALK_SPEED * 1.25 * delta))
	actor.position = feet()
	actor.advance_path(delta, actor.position - before, L.depth(actor.position.y), reduced)
	if rope.visible:
		var palm := Vector2(242, 253)
		if walker.animation == &"walk": palm = Vacationer.GRASS_SEQUENCE_HAND[walker.frame % Vacationer.GRASS_SEQUENCE_HAND.size()]
		var hand := to_local(walker.to_global(walker.offset + palm))
		var collar := to_local(actor.to_global(Vector2(875, 665) - actor._ground_anchor))
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
	var radius := actor.body_radius * Vector2(1.0, 0.42) * L.depth(actor.position.y)
	draw_set_transform(actor.position + Vector2(0, 1), 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, Color(0.29, 0.25, 0.16, 0.12))
	draw_set_transform(Vector2.ZERO)
