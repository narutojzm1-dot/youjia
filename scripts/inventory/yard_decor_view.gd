extends Node2D
const Model := preload("res://scripts/inventory/yard_decor.gd")
const SettleRing := preload("res://scripts/inventory/yard_decor_settle_ring.gd")
var visuals: Dictionary = {}
## REQ-20261008-069：某处新摆上（或换了另一样）小物、存档确认后，脚下泛一圈落定圈（spot → 圈）。
## 第一次 sync 是读档重建，不算“刚放好”；同一处只微调偏移也不泛圈。
var settle_rings: Dictionary = {}
var _synced := false
var preview: YardPropVisual
var confirmed: Dictionary = {}
var _occluding_actors: Dictionary = {}

func sync(value: Dictionary) -> void:
	var before: Dictionary = confirmed.get("places", {})
	var announce := _synced
	_synced = true
	confirmed = value.duplicate(true)
	for child: Node in get_children():
		if child != preview and not child is SettleRing:
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
		if announce and str(before.get(spot, {}).get("find_id", "")) != str(entry.find_id):
			_settle(spot, prop)
	for spot: String in settle_rings.keys():
		if not visuals.has(spot) or not is_instance_valid(settle_rings[spot]):
			_drop_ring(spot)

func _settle(spot: String, prop: YardPropVisual) -> void:
	_drop_ring(spot)
	var ring := SettleRing.new()
	ring.reduced = ScreenFactory.reduced_motion()
	ring.position = prop.position
	ring.scale = prop.scale
	ring.z_as_relative = false
	ring.z_index = prop.z_index - 1
	add_child(ring)
	settle_rings[spot] = ring

func _drop_ring(spot: String) -> void:
	var ring: Variant = settle_rings.get(spot)
	settle_rings.erase(spot)
	if is_instance_valid(ring):
		ring.visible = false
		ring.queue_free()

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
