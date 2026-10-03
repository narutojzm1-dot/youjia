extends "res://scripts/game/world_effects_overlay.gd"
## REQ-20261003-018: still orange target glow + catch rings under ui.reduced_motion.

# Low motion keeps the orange target and the catch rings readable without a pulse or flying specks.
static func celebration_pose(kind: String, t: float, reduced_motion: bool) -> Dictionary:
	if kind == "target":
		var radius := 18.0 if reduced_motion else 18.0 + 2.5 * absf(sin(t * 2.4))
		return {"glow_radius": radius}
	var progress := clampf(t, 0.0, 1.0)
	if reduced_motion:
		return {
			"outer_radius": 64.0,
			"outer_alpha": 0.78,
			"mid_radius": 42.0,
			"mid_alpha": 0.62,
			"inner_radius": 24.0,
			"inner_alpha": 0.70,
			"core_radius": 8.0,
			"particle_count": 0,
			"show_banner": true,
		}
	return {
		"outer_radius": lerpf(16.0, 110.0, progress),
		"outer_alpha": (1.0 - progress) * 0.95,
		"mid_radius": lerpf(10.0, 72.0, minf(progress * 1.25, 1.0)),
		"mid_alpha": maxf(0.0, 1.0 - progress * 1.25),
		"inner_radius": lerpf(6.0, 44.0, minf(progress * 1.7, 1.0)),
		"inner_alpha": maxf(0.0, 1.0 - progress * 1.7),
		"core_radius": 14.0 * maxf(0.0, 1.0 - progress * 2.2),
		"particle_count": 12 if progress < 0.7 else 0,
		"show_banner": progress < 0.55,
	}


## 宠物目标：脚底柔光 + 明确画在头顶上方的半圆弧与向下箭头
func _draw_pet_arc() -> void:
	if pet_pos == Vector2.INF or pet_alpha < 0.05:
		return
	var feet := pet_pos
	var lift := maxf(48.0, pet_lift)
	# 冠顶中心：脚底向上 lift，再上移一点让弧离开耳朵
	var crown := feet + Vector2(0.0, -(lift + 18.0))
	# ── 脚底柔光（次要线索，不抢头顶主信号）
	var gr := float(celebration_pose("target", pet_day_t, bool(TuningStore.get_value("ui.reduced_motion", false))).glow_radius)
	draw_circle(feet, gr, Color(0.95, 0.68, 0.32, pet_alpha * 0.22))
	draw_arc(feet, 16.0, 0.0, TAU, 24, Color(1.0, 0.55, 0.08, pet_alpha * 0.55), 2.2, true)
	# ── 头顶主弧（半径更大，明确“在动物上方”）
	draw_arc(crown, 28.0, -PI * 0.95, -PI * 0.05, 36, Color(0.45, 0.20, 0.0, pet_alpha * 0.40), 10.0, true)
	draw_arc(crown, 28.0, -PI * 0.95, -PI * 0.05, 36, Color(1.0, 0.52, 0.06, pet_alpha), 6.0, true)
	draw_arc(crown, 18.0, -PI * 0.88, -PI * 0.12, 28, Color(1.0, 0.82, 0.45, pet_alpha * 0.70), 2.6, true)
	# ── 向下箭头：尖端指向冠顶，整体完全在精灵轮廓之上
	var tip := crown + Vector2(0.0, -10.0)
	var wl := tip + Vector2(-16.0, -16.0)
	var wr := tip + Vector2(16.0, -16.0)
	draw_line(wl, tip, Color(1.0, 0.52, 0.06, minf(1.0, pet_alpha * 1.20)), 6.0, true)
	draw_line(wr, tip, Color(1.0, 0.52, 0.06, minf(1.0, pet_alpha * 1.20)), 6.0, true)
	draw_line(wl, wr, Color(1.0, 0.52, 0.06, pet_alpha * 0.60), 2.6, true)
	draw_circle(tip, 4.5, Color(1.0, 0.88, 0.50, pet_alpha * 0.95))


## 钓鱼庆祝扩散环：更大、更久、更亮，保证桌面 Web 一眼可见
func _draw_fish_rings() -> void:
	if fish_ring_time <= 0.0:
		return
	var fp := fish_ring_pos
	const TOTAL := 3.2
	var t := 1.0 - clampf(fish_ring_time / TOTAL, 0.0, 1.0)
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var pose := celebration_pose("catch", t, reduced)
	var mc: Color
	match fish_ring_type:
		"medium": mc = Color(0.28, 0.58, 0.95)
		"odd":    mc = Color(0.55, 0.40, 0.92)
		_:        mc = Color(0.35, 0.78, 0.95)
	var outer_a := float(pose.outer_alpha)
	draw_arc(fp, float(pose.outer_radius), 0.0, TAU, 56,
		Color(1.0, 0.86, 0.35, outer_a), 6.0, true)
	var ro := float(pose.mid_radius)
	var ao := float(pose.mid_alpha)
	draw_circle(fp, ro, Color(mc.r, mc.g, mc.b, ao * 0.28))
	draw_arc(fp, ro, 0.0, TAU, 40, Color(mc.r, mc.g + 0.10, mc.b + 0.08, ao), 5.0, true)
	var ri := float(pose.inner_radius)
	var ai := float(pose.inner_alpha)
	draw_arc(fp, ri, 0.0, TAU, 32, Color(0.85, 0.98, 1.0, ai), 4.0, true)
	var cr := float(pose.core_radius)
	if cr > 0.5:
		draw_circle(fp, cr * 1.6, Color(1.0, 0.90, 0.45, ai * 0.90))
		draw_circle(fp, cr, Color(1.0, 1.0, 1.0, ai * 1.25))
	var specks := int(pose.particle_count)
	if specks > 0:
		var pt2 := t / 0.7
		var pa := (1.0 - pt2) * 0.95
		for i: int in specks:
			var angle := float(i) * TAU / float(specks)
			var px := fp + Vector2(cos(angle), sin(angle) * 0.55) * lerpf(10.0, 64.0, pt2)
			draw_circle(px, lerpf(6.0, 1.5, pt2), Color(mc.r, mc.g + 0.18, 1.0, pa))
	if bool(pose.show_banner):
		var banner_a := 0.95 if reduced else (1.0 - t / 0.55) * 0.95
		var bp := fp + Vector2(0.0, -48.0)
		draw_circle(bp, 22.0, Color(0.12, 0.22, 0.38, banner_a * 0.55))
		draw_arc(bp, 22.0, 0.0, TAU, 28, Color(1.0, 0.92, 0.55, banner_a), 3.0, true)
