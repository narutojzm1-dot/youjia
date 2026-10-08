extends Node2D
const Model := preload("res://scripts/inventory/yard_decor.gd")
var visuals: Dictionary = {}
var preview: YardPropVisual
var confirmed: Dictionary = {}
var _occluding_actors: Dictionary = {}

func sync(value: Dictionary) -> void:
	confirmed = value.duplicate(true)
	for child: Node in get_children():
		if child != preview:
			child.visible = false
			child.queue_free()
	visuals.clear()
	for spot: String in value.get("places", {}):
		var entry: Dictionary = value.places[spot]
		var prop := YardPropVisual.new()
		prop.configure("keepsake", {"find_id": entry.find_id})
		prop.position = Model.position_for(spot, entry)
		prop.scale = Vector2.ONE * YardGround.depth_at(prop.position.y)
		prop.z_as_relative = false
		prop.z_index = roundi(prop.position.y)
		add_child(prop)
		visuals[spot] = prop

func show_preview(spot: String, entry: Dictionary) -> void:
	clear_preview()
	if entry.is_empty(): return
	if confirmed.get("places", {}).get(spot, {}) == entry:
		if visuals.has(spot): _reveal_for_editing(visuals[spot])
		return
	preview = YardPropVisual.new()
	preview.configure("keepsake", {"find_id": entry.find_id})
	preview.position = Model.position_for(spot, entry)
	preview.scale = Vector2.ONE * YardGround.depth_at(preview.position.y)
	preview.modulate.a = 0.55
	preview.z_as_relative = false
	preview.z_index = roundi(preview.position.y)
	add_child(preview)
	if visuals.has(spot): visuals[spot].visible = false
	_reveal_for_editing(preview)

func _reveal_for_editing(prop: YardPropVisual) -> void:
	# The editor pauses the yard. Keep an animal's place in the composition,
	# but let the selected keepsake show through until editing ends.
	var yard := get_parent()
	var prop_rect: Rect2 = yard.global_transform.affine_inverse() * prop.global_transform * YardPropVisual.bounds("keepsake")
	for child: Node in yard.get_children():
		if child is FeltActor and child.is_visible_in_tree() and child.z_index >= prop.z_index and child.visual_hit_rect().intersects(prop_rect):
			_occluding_actors[child] = child.modulate
			child.modulate.a *= 0.12

func _restore_actors() -> void:
	for actor: Node2D in _occluding_actors:
		if is_instance_valid(actor): actor.modulate = _occluding_actors[actor]
	_occluding_actors.clear()

func _exit_tree() -> void:
	_restore_actors()

func clear_preview() -> void:
	_restore_actors()
	if is_instance_valid(preview):
		preview.visible = false
		preview.queue_free()
	preview = null
	for visual: Node2D in visuals.values(): visual.visible = true

func placed(spot: String) -> Dictionary:
	var entry: Variant = confirmed.get("places", {}).get(spot, {})
	if not entry is Dictionary or entry.is_empty():
		return {}
	return {"spot": spot, "point": Model.position_for(spot, entry), "find_id": str(entry.get("find_id", ""))}

func hit_spot(point: Vector2) -> Dictionary:
	var spot := Model.spot_at(confirmed, point)
	if spot.is_empty():
		return {}
	return placed(spot)
