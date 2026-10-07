extends Node2D
const Model := preload("res://scripts/inventory/yard_decor.gd")
var visuals: Dictionary = {}
var preview: YardPropVisual
var confirmed: Dictionary = {}

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
	if confirmed.get("places", {}).get(spot, {}) == entry: return
	preview = YardPropVisual.new()
	preview.configure("keepsake", {"find_id": entry.find_id})
	preview.position = Model.position_for(spot, entry)
	preview.scale = Vector2.ONE * YardGround.depth_at(preview.position.y)
	preview.modulate.a = 0.55
	preview.z_as_relative = false
	preview.z_index = roundi(preview.position.y)
	add_child(preview)
	if visuals.has(spot): visuals[spot].visible = false

func clear_preview() -> void:
	if is_instance_valid(preview):
		preview.visible = false
		preview.queue_free()
	preview = null
	for visual: Node2D in visuals.values(): visual.visible = true
