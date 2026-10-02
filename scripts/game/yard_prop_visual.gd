class_name YardPropVisual
extends Node2D

# Live props and album props render the same inert, bounded state.
const PLANT_EMPTY := 0
const PLANT_PLANTED := 1
const PLANT_SPROUTING := 2
const PLANT_BLOOMED := 3
const FISH_IDLE := 0
const FISH_CASTING := 1
const FISH_BITE := 2
const FISH_CAUGHT := 3
var subject := ""
var state: Dictionary = {}

func configure(next_subject: String, next_state: Dictionary) -> void:
	subject = next_subject
	state = sanitize_state(subject, next_state)
	queue_redraw()

static func sanitize_state(kind: String, raw: Variant) -> Dictionary:
	if not raw is Dictionary or kind not in ["plant", "fishing"]:
		return {}
	if not raw.get("nearby") is bool or not _number(raw.get("phase"), 0.0, TAU * 10.0):
		return {}
	var result := {"nearby": raw.nearby, "phase": float(raw.phase)}
	if kind == "plant":
		if not _integer(raw.get("plant_state"), 0, 3) or not _number(raw.get("soil_reveal"), 0, 1) or not _number(raw.get("harvest_flash"), 0, 1.8):
			return {}
		result.merge({"plant_state": int(raw.plant_state), "soil_reveal": float(raw.soil_reveal), "harvest_flash": float(raw.harvest_flash)})
	else:
		if not _integer(raw.get("fish_state"), 0, 3) or raw.get("fish_type") not in ["", "small", "medium", "odd"]:
			return {}
		result.merge({"fish_state": int(raw.fish_state), "fish_type": raw.fish_type})
	return result

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value, minimum, maximum) and float(value) == floorf(float(value))

static func bounds(kind: String) -> Rect2:
	return Rect2(-36, -28, 72, 48) if kind == "plant" else Rect2(-8, -40, 52, 68)

func _draw() -> void:
	if state.is_empty(): return
	if subject == "plant": _draw_plant_bed()
	elif subject == "fishing": _draw_fishing_spot()

func _draw_plant_bed() -> void:
	var pt := Vector2.ZERO
	# 土壤可见度：随玩家距离平滑渐隐，消除远处"棕色贴纸"感。
	## 80px 以内：完全可见；80-200px：线性衰减（平方使靠近时揭示更自然）；>200px：完全隐藏。
	var soil_reveal := float(state.soil_reveal)
	# ── 步骤 1：最外层软阴影椭圆（随距离渐显）
	if soil_reveal > 0.02:
		draw_set_transform(pt + Vector2(0, 4), 0.0, Vector2(32.0, 8.0))
		draw_circle(Vector2.ZERO, 1.0, Color(0.16, 0.11, 0.07, 0.30 * soil_reveal))
		draw_set_transform(Vector2.ZERO)
		# ── 步骤 2：土壤主体（三层同心椭圆：深→中→浅）
		draw_set_transform(pt, 0.0, Vector2(26.0, 7.0))
		draw_circle(Vector2.ZERO, 1.0, Color(0.38, 0.25, 0.14, 0.85 * soil_reveal))
		draw_set_transform(Vector2.ZERO)
		draw_set_transform(pt + Vector2(0, -1), 0.0, Vector2(21.0, 5.5))
		draw_circle(Vector2.ZERO, 1.0, Color(0.54, 0.38, 0.24, 0.80 * soil_reveal))
		draw_set_transform(Vector2.ZERO)
		draw_set_transform(pt + Vector2(0, -2.5), 0.0, Vector2(14.0, 3.5))
		draw_circle(Vector2.ZERO, 1.0, Color(0.68, 0.50, 0.32, 0.60 * soil_reveal))
		draw_set_transform(Vector2.ZERO)
	# ── 步骤 3：状态相关内容
	match int(state.plant_state):
		PLANT_EMPTY:
			# 空槽：两个小暗椭圆（凹坑），随土壤一起淡隐
			if soil_reveal > 0.05:
				for sx: float in [-9.0, 9.0]:
					draw_set_transform(pt + Vector2(sx, 0), 0.0, Vector2(5.5, 2.0))
					draw_circle(Vector2.ZERO, 1.0, Color(0.22, 0.14, 0.08, 0.65 * soil_reveal))
					draw_set_transform(Vector2.ZERO)
		PLANT_PLANTED:
			# 种子：小鼓包随土壤渐显；远处不强迫玩家关注未种植的床
			if soil_reveal > 0.05:
				for sx: float in [-9.0, 9.0]:
					var seed_pt := pt + Vector2(sx, 0)
					draw_set_transform(seed_pt, 0.0, Vector2(3.8, 2.0))
					draw_circle(Vector2.ZERO, 1.0, Color(0.36, 0.23, 0.13, 0.95 * soil_reveal))
					draw_set_transform(Vector2.ZERO)
					draw_circle(seed_pt + Vector2(-0.8, -0.8), 1.0, Color(0.62, 0.46, 0.30, 0.55 * soil_reveal))
		PLANT_SPROUTING:
			# 嫩芽：茎/叶始终显示（绿色嫩芽在草地上自然），土壤底色随距离渐显
			var lean := sin(float(state.phase) * 0.9) * 1.2
			var base := pt + Vector2(0, -3)
			var sprout_tip := base + Vector2(lean, -11)
			if soil_reveal > 0.05:
				draw_circle(base + Vector2(0, 1), 2.8, Color(0.20, 0.14, 0.08, 0.40 * soil_reveal))
			draw_line(base, sprout_tip, Color(0.38, 0.62, 0.32, 0.95), 2.2, true)
			draw_line(base + Vector2(lean * 0.4, -3), sprout_tip + Vector2(-6, 0), Color(0.44, 0.68, 0.36, 0.88), 2.0, true)
			draw_line(base + Vector2(lean * 0.5, -5), sprout_tip + Vector2(6, -1), Color(0.44, 0.68, 0.36, 0.88), 2.0, true)
		PLANT_BLOOMED:
			# 花朵：始终显示（花朵是亮眼功能，不随距离隐藏）；茎基阴影随土壤渐显
			var sway := sin(float(state.phase) * 1.2) * 1.8
			var base := pt + Vector2(0, -3)
			var bloom_tip := base + Vector2(sway, -15)
			if soil_reveal > 0.05:
				draw_circle(base + Vector2(0, 2), 4.0, Color(0.18, 0.12, 0.07, 0.38 * soil_reveal))
			draw_line(base, bloom_tip, Color(0.38, 0.62, 0.32, 0.92), 2.2, true)
			for i: int in 5:
				var angle := float(i) / 5.0 * TAU - PI * 0.5
				draw_circle(bloom_tip + Vector2(0, -1) + Vector2(cos(angle), sin(angle)) * 5.5, 3.2, Color(0.92, 0.68, 0.76, 0.90))
			draw_circle(bloom_tip + Vector2(0, -1), 3.0, Color(0.98, 0.90, 0.55, 0.95))
	# 收获庆祝：花瓣爆散动画（float(state.harvest_flash) > 0 时激活）
	if float(state.harvest_flash) > 0.0:
		var t := 1.0 - clampf(float(state.harvest_flash) / 1.8, 0.0, 1.0)
		var burst_a := maxf(0.0, 1.0 - t * 1.5) * 0.90
		for i: int in 6:
			var angle := float(i) * TAU / 6.0 - PI * 0.5
			var dist := lerpf(5.0, 36.0, t)
			var px := pt + Vector2(cos(angle), sin(angle)) * dist
			draw_circle(px, lerpf(4.0, 1.5, t), Color(0.92, 0.68, 0.76, burst_a))
		draw_circle(pt, lerpf(8.0, 1.0, t), Color(0.98, 0.90, 0.55, burst_a * 0.80))
	# 植物床指示圆：开花时使用明显的粉色脉冲圆，提示玩家可以收获
	# 交互指示：椭圆轮廓（与土壤形状一致，融入透视，不用圆弧）
	var _ellipse_pts := PackedVector2Array()
	const _ELLIPSE_SEGS := 24
	if int(state.plant_state) == PLANT_BLOOMED:
		var bloom_pulse := 0.30 + 0.25 * absf(sin(float(state.phase) * 2.2))
		for _ei: int in _ELLIPSE_SEGS + 1:
			var _a := float(_ei) / float(_ELLIPSE_SEGS) * TAU
			_ellipse_pts.append(pt + Vector2(cos(_a) * 34.0, sin(_a) * 12.0))
		draw_polyline(_ellipse_pts, Color(0.92, 0.68, 0.76, bloom_pulse), 2.8, true)
	else:
		var near_plant := bool(state.nearby)
		var indicator_alpha := 0.22 if near_plant else 0.04
		for _ei: int in _ELLIPSE_SEGS + 1:
			var _a := float(_ei) / float(_ELLIPSE_SEGS) * TAU
			_ellipse_pts.append(pt + Vector2(cos(_a) * 30.0, sin(_a) * 10.0))
		draw_polyline(_ellipse_pts, Color(0.58, 0.42, 0.26, indicator_alpha), 1.4, true)


func _draw_fishing_spot() -> void:
	var fp := Vector2.ZERO
	var player_near := bool(state.nearby)
	# 水塘常驻波纹：三圈相位错开的扩散涟漪，给水面带来生气
	var ripple_t := float(state.phase)
	for i: int in 3:
		var phase := fmod(ripple_t * 0.4 + float(i) / 3.0, 1.0)
		var r := lerpf(6.0, 30.0, phase)
		var a := (1.0 - phase) * 0.22
		draw_arc(fp + Vector2(10, 12), r, 0.0, TAU, 20, Color(0.42, 0.68, 0.88, a), 1.8, true)
	if not player_near and int(state.fish_state) == FISH_IDLE:
		return
	# 指示圆（靠近时才显示）
	if player_near and int(state.fish_state) == FISH_IDLE:
		draw_arc(fp, 22.0, 0.0, TAU, 24, Color(0.48, 0.60, 0.75, 0.30), 1.2, true)
	# 鱼竿（总是显示，玩家在附近时）
	if player_near or int(state.fish_state) != FISH_IDLE:
		var rod_base := fp + Vector2(-4, -2)
		var rod_tip := fp + Vector2(20, -32)
		draw_line(rod_base, rod_tip, Color(0.40, 0.28, 0.18, 0.82), 2.5, true)
		# 钓鱼中：画鱼线和浮标
		if int(state.fish_state) == FISH_CASTING or int(state.fish_state) == FISH_BITE:
			var float_target := fp + Vector2(28, 18)
			draw_line(rod_tip, float_target, Color(0.38, 0.28, 0.18, 0.65), 1.2, true)
			# 浮标颜色：有咬钩时变红
			var bob_color := Color(0.90, 0.32, 0.25, 0.92) if int(state.fish_state) == FISH_BITE else Color(0.80, 0.88, 0.96, 0.85)
			draw_circle(float_target, 3.8, bob_color)
			# 有咬钩时浮标加闪烁提示（两段脉冲，速度加快，更难错过）
			if int(state.fish_state) == FISH_BITE:
				var pulse1 := 0.5 + 0.5 * sin(float(state.phase) * 12.0)
				draw_circle(float_target, 7.5, Color(0.90, 0.32, 0.25, pulse1 * 0.55))
				draw_arc(float_target, 10.0, 0.0, TAU, 16, Color(0.95, 0.50, 0.38, pulse1 * 0.40), 2.2, true)
		if int(state.fish_state) == FISH_CAUGHT:
			# 钓上来！画一条小鱼（此状态极短，主要由 _fish_catch_flash 提供视觉反馈）
			var fish_pos := fp + Vector2(28, 8)
			draw_line(rod_tip, fish_pos, Color(0.38, 0.28, 0.18, 0.65), 1.2, true)
			draw_circle(fish_pos, 4.0, {"small":Color(0.55,0.75,0.82,0.90),"medium":Color(0.32,0.60,0.92,0.90),"odd":Color(0.50,0.42,0.88,0.90)}.get(str(state.fish_type),Color(0.55,0.75,0.82,0.90)))
			draw_arc(fish_pos + Vector2(4, 0), 3.0, PI * 0.6, PI * 1.4, 8, Color(0.45, 0.65, 0.72, 0.88), 2.0, true)
