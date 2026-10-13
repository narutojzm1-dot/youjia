class_name CookingSmoke
extends Node2D
## GROK #705: local chimney watercolor smoke while cooking is active.
## Leaf presentation only. Leader supplies real cooking start/end + roof anchor.
## Does not infer mealtime, does not touch house door / sleep / brush directors.

## 晴天院子原画烟囱帽顶（世界 1280×720，背景 1920×1080 按 2/3 映射）。
## Leader 公布正式屋顶点后仍用 set_chimney_anchor 覆盖，本默认只给叶子和隔离演示。
const DEFAULT_CHIMNEY_ANCHOR := Vector2(286.0, 122.0)

## 比天空略深的暖灰，短时间做饭能在淡蓝天上读出一缕；不是铺满屋顶的雾。
## 夜色 r 仍低于白天，套件用这个差值确认渐变被重刷。
const SMOKE_DAY := Color(0.55, 0.52, 0.48, 0.72)
const SMOKE_NIGHT := Color(0.46, 0.48, 0.52, 0.64)

## MotionPreference 写入的真实键。隔离套件里不能把自动加载名写成裸标识符。
const REDUCED_MOTION_ID := "ui.reduced_motion"

const PUFF_AMOUNT := 14
const PUFF_LIFETIME := 2.8
const PUFF_SIZE := 64

var _emitter: CPUParticles2D
var _cooking := false
var _paused := false
var _built := false
var _night_tint := false
var _puff_texture: ImageTexture
var _tuning_hooked := false
var _seen_reduced := false
var _seen_reduced_valid := false


func _ready() -> void:
	_ensure_emitter()
	_hook_tuning()
	if position == Vector2.ZERO:
		position = DEFAULT_CHIMNEY_ANCHOR
	_apply_emission()


func _process(_delta: float) -> void:
	# 自动加载晚于本节点出现时，下一帧再订一次；订上之后仍比对当前值，避免只靠一次信号。
	if not _tuning_hooked:
		_hook_tuning()
	var reduced := _reduced_motion()
	if _seen_reduced_valid and reduced == _seen_reduced:
		return
	_apply_emission()


## World-space chimney mouth. Safe to call before or after set_cooking.
func set_chimney_anchor(world_pos: Vector2) -> void:
	position = world_pos


## Optional day/night tint hint from Leader (does not own the weather/night systems).
func set_night_tint(night: bool) -> void:
	if _night_tint == night:
		return
	_night_tint = night
	# 做饭标志不变，夜色变了也要重刷渐变，不能只改一个恒定色。
	_apply_emission()


## Start or stop cooking smoke. Same value is a no-op (no restart, no extra nodes).
func set_cooking(active: bool) -> void:
	if _cooking == active:
		return
	_cooking = active
	_apply_emission()


## Pause freezes new emission; existing wisps fade out. Cooking flag is unchanged.
func set_paused(paused: bool) -> void:
	if _paused == paused:
		return
	_paused = paused
	_apply_emission()


func is_cooking() -> bool:
	return _cooking


func is_paused() -> bool:
	return _paused


func is_emitting() -> bool:
	return _emitter != null and _emitter.emitting


func debug_snapshot() -> Dictionary:
	var wash := _wash()
	var ramp_peak := 0.0
	var ramp_end := 1.0
	var center_a := 0.0
	var corner_a := 1.0
	var has_texture := false
	if _emitter != null and _emitter.color_ramp is Gradient:
		var ramp: Gradient = _emitter.color_ramp
		var peak: Color = ramp.sample(0.12)
		wash = peak
		ramp_peak = peak.a
		ramp_end = ramp.sample(1.0).a
	if _emitter != null and _emitter.texture is ImageTexture:
		has_texture = true
		var image := (_emitter.texture as ImageTexture).get_image()
		if image != null and image.get_width() > 1 and image.get_height() > 1:
			center_a = image.get_pixel(image.get_width() / 2, image.get_height() / 2).a
			corner_a = image.get_pixel(0, 0).a
	return {
		"cooking": _cooking,
		"paused": _paused,
		"emitting": is_emitting(),
		"child_count": get_child_count(),
		"anchor": position,
		"night_tint": _night_tint,
		"reduced_motion": _reduced_motion(),
		"tuning_hooked": _tuning_hooked,
		"has_soft_texture": has_texture,
		"ramp_peak_alpha": ramp_peak,
		"ramp_end_alpha": ramp_end,
		"texture_center_alpha": center_a,
		"texture_corner_alpha": corner_a,
		"wash": wash,
	}


func _ensure_emitter() -> void:
	if _built and _emitter != null and is_instance_valid(_emitter):
		return
	# Tear down any accidental extras so repeated ensure never accumulates.
	for child in get_children():
		if child is CPUParticles2D:
			child.queue_free()
	_emitter = CPUParticles2D.new()
	_emitter.name = "ChimneyWisp"
	_emitter.emitting = false
	_emitter.one_shot = false
	_emitter.explosiveness = 0.0
	_emitter.randomness = 0.45
	_emitter.lifetime = PUFF_LIFETIME
	_emitter.preprocess = 0.0
	_emitter.amount = PUFF_AMOUNT
	_emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_emitter.emission_sphere_radius = 3.5
	_emitter.direction = Vector2(0.08, -1.0).normalized()
	_emitter.spread = 12.0
	_emitter.gravity = Vector2(3.0, -10.0)
	_emitter.initial_velocity_min = 18.0
	_emitter.initial_velocity_max = 34.0
	_emitter.angular_velocity_min = -8.0
	_emitter.angular_velocity_max = 8.0
	_emitter.scale_amount_min = 0.55
	_emitter.scale_amount_max = 1.0
	var grow := _grow_curve()
	_emitter.scale_curve_x = grow
	_emitter.scale_curve_y = grow
	_emitter.texture = _soft_puff_texture()
	_emitter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_emitter.color = Color(1, 1, 1, 1)
	_emitter.color_ramp = _fade_ramp(_wash())
	# Local roof puff sits above yard props but below HUD/UI.
	_emitter.z_index = 6
	_emitter.local_coords = true
	add_child(_emitter)
	_built = true


func _apply_emission() -> void:
	_ensure_emitter()
	var reduced := _reduced_motion()
	_seen_reduced = reduced
	_seen_reduced_valid = true
	# 纹理与寿命渐变每次都按当前昼夜重刷；已经在冒的时候不 restart()。
	_emitter.texture = _soft_puff_texture()
	_emitter.color = Color(1, 1, 1, 1)
	_emitter.color_ramp = _fade_ramp(_wash())
	var should_emit := _cooking and not _paused and not reduced
	if should_emit:
		if _emitter.amount != PUFF_AMOUNT:
			_emitter.amount = PUFF_AMOUNT
		if not is_equal_approx(_emitter.lifetime, PUFF_LIFETIME):
			_emitter.lifetime = PUFF_LIFETIME
		if not _emitter.emitting:
			_emitter.emitting = true
	else:
		# 停发后已出生的粒子仍走 color_ramp，末尾 alpha 为 0。
		_emitter.emitting = false


func _wash() -> Color:
	return SMOKE_NIGHT if _night_tint else SMOKE_DAY


func _fade_ramp(wash: Color) -> Gradient:
	# 寿命颜色：刚出烟囱几乎看不见，中段是淡水粉，结尾散尽。
	## 停发本身不负责变淡，渐变才让一缕烟自己消失。
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.12, 0.50, 1.0])
	ramp.colors = PackedColorArray([
		Color(wash.r, wash.g, wash.b, 0.0),
		Color(wash.r, wash.g, wash.b, wash.a),
		Color(wash.r, wash.g, wash.b, wash.a * 0.55),
		Color(wash.r, wash.g, wash.b, 0.0),
	])
	return ramp


func _grow_curve() -> Curve:
	var curve := Curve.new()
	curve.min_value = 0.0
	curve.max_value = 1.6
	curve.add_point(Vector2(0.0, 0.55))
	curve.add_point(Vector2(1.0, 1.15))
	return curve


func _soft_puff_texture() -> ImageTexture:
	if _puff_texture != null:
		return _puff_texture
	# 程序生成的软圆，归本切片，不另做一套设置或雾层。
	var image := Image.create(PUFF_SIZE, PUFF_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 0))
	var center := Vector2((PUFF_SIZE - 1) * 0.5, (PUFF_SIZE - 1) * 0.5)
	var radius := (PUFF_SIZE - 1) * 0.5
	for y in PUFF_SIZE:
		for x in PUFF_SIZE:
			var remain := 1.0 - Vector2(x, y).distance_to(center) / radius
			if remain <= 0.0:
				continue
			# 一次 smoothstep：中心仍是实的，身体比再平方后的针尖更看得清，四角保持全透明。
			var soft := remain * remain * (3.0 - 2.0 * remain)
			image.set_pixel(x, y, Color(1, 1, 1, soft))
	_puff_texture = ImageTexture.create_from_image(image)
	return _puff_texture


func _tuning_store() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("/root/TuningStore")


func _hook_tuning() -> void:
	if _tuning_hooked:
		return
	var store := _tuning_store()
	if store == null or not store.has_signal("value_changed"):
		return
	if not store.value_changed.is_connected(_on_tuning_value_changed):
		store.value_changed.connect(_on_tuning_value_changed)
	_tuning_hooked = true


func _on_tuning_value_changed(id: String, _requested: Variant, _active: Variant) -> void:
	if id != REDUCED_MOTION_ID:
		return
	# 做饭仍为 true 时，减少动态变化也要重刷发射，且不新增节点。
	_apply_emission()


func _reduced_motion() -> bool:
	var store := _tuning_store()
	if store == null or not store.has_method("get_value"):
		return false
	return bool(store.get_value(REDUCED_MOTION_ID, false))
