class_name NearPathWindowLight
extends RefCounted
## Original near-scene panes only. No new clock or indoor state.
const RULE := preload("res://scripts/game/house_lights.gd")
const EFFECT := preload("res://shaders/near_path_window_light.gdshader")
const MASK := preload("res://assets/holiday/exploration/near_path_window_mask.svg")
const BOUNDS := Rect2(1345, 312, 170, 112)
var amount := 0.0
var target := 0.0
var _enabled := true
var _reduced := false
var _painting: Sprite2D
var _layer: CanvasLayer
var _glow: Sprite2D
var _ink: ShaderMaterial

func bind(painting: Sprite2D, reduced: bool) -> void:
	_painting = painting
	_layer = CanvasLayer.new()
	_layer.name = "NearWindowLight"
	_layer.layer = 6 # After the shared daylight multiplier (5), before nearby HUD (8).
	_layer.follow_viewport_enabled = true
	_layer.custom_viewport = painting.get_viewport()
	painting.get_parent().add_child(_layer)
	_glow = Sprite2D.new()
	_glow.centered = false
	_glow.region_enabled = true
	_glow.region_rect = BOUNDS
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_ink = ShaderMaterial.new()
	_ink.shader = EFFECT
	_ink.set_shader_parameter("pane_mask", MASK)
	_ink.set_shader_parameter("pane_bounds", Vector4(BOUNDS.position.x, BOUNDS.position.y, BOUNDS.size.x, BOUNDS.size.y))
	_glow.material = _ink
	_layer.add_child(_glow)
	apply(true, reduced)

func sync_environment(state: Dictionary, snap: bool = false) -> void:
	if not state.has("day_fraction"): return
	# Being in this scene means the traveller is outdoors. Use the public rule.
	target = 1.0 if RULE.wants_light(float(state.day_fraction), false) else 0.0
	if snap or _reduced: amount = target
	_refresh()

func apply(enabled: bool, reduced: bool) -> void:
	if enabled and not _enabled: amount = target
	_enabled = enabled
	_reduced = reduced
	if reduced: amount = target
	_refresh()

func advance(delta: float, reduced: bool) -> void:
	if reduced != _reduced: apply(_enabled, reduced)
	if not _enabled: return
	if not reduced: amount = lerpf(amount, target, 1.0 - exp(-maxf(delta, 0.0) * 2.0))
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_layer) or not is_instance_valid(_painting): return
	_layer.visible = _enabled and amount > 0.001 and _painting.is_visible_in_tree()
	_layer.transform = _painting.get_global_transform()
	_glow.texture = _painting.texture
	_glow.position = _painting.get_rect().position + BOUNDS.position
	if _glow.texture != null: _ink.set_shader_parameter("source_size", _glow.texture.get_size())
	_ink.set_shader_parameter("amount", amount)

func release() -> void:
	if is_instance_valid(_layer): _layer.queue_free()
	_layer = null
	_glow = null
	_painting = null
	_ink = null
