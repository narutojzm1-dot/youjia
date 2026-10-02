extends Node2D
## YardWorld places this layer above the actual maximum foot-Y depth each tick.
## Target selection is shared with the HUD and keyboard action resolver.

# ── 宠物目标弧（可抚摸动物的橙色选中指示）─────────────────────────────────────
## Vector2.INF = 无目标（跳过绘制）
var pet_pos: Vector2 = Vector2.INF
var pet_alpha: float = 0.0
var pet_day_t: float = 0.0

# ── 钓鱼庆祝扩散环（收杆成功时的金色+主色同心环）──────────────────────────────
## > 0 时绘制并倒计时；= 0 时跳过
var fish_ring_time: float = 0.0
var fish_ring_type: String = ""        # "small" / "medium" / "odd"
var fish_ring_pos: Vector2 = Vector2.ZERO


func _draw() -> void:
	_draw_pet_arc()
	_draw_fish_rings()


## 宠物目标弧：地面光晕 + 上方橙色半圆弧 + 向下箭头，在动物脚部正上方绘制
func _draw_pet_arc() -> void:
	if pet_pos == Vector2.INF or pet_alpha < 0.05:
		return
	var pt := pet_pos
	# 地面柔光环（软橙色填充 + 实心轮廓圆环）
	var gr := 22.0 + 3.0 * absf(sin(pet_day_t * 2.4))
	draw_circle(pt, gr, Color(0.95, 0.68, 0.32, pet_alpha * 0.30))
	draw_arc(pt, 20.0, 0.0, TAU, 28, Color(1.0, 0.55, 0.08, pet_alpha * 0.75), 2.8, true)
	# 上方半圆弧（暗色光晕衬底让橙色弧更突出，类似描边效果）
	draw_arc(pt, 42.0, -PI * 0.90, -PI * 0.10, 36, Color(0.55, 0.26, 0.0, pet_alpha * 0.35), 9.0, true)
	draw_arc(pt, 42.0, -PI * 0.90, -PI * 0.10, 36, Color(1.0, 0.55, 0.08, pet_alpha), 5.5, true)
	# 内圈辅助弧（层次感）
	draw_arc(pt, 31.0, -PI * 0.82, -PI * 0.18, 26, Color(1.0, 0.80, 0.45, pet_alpha * 0.58), 2.2, true)
	# 向下三角箭头（↓）：5px 粗线 + 尖端实心圆，确保在水彩背景上清晰辨认
	var tip := pt + Vector2(0.0, -33.0)
	var wl  := tip + Vector2(-13.0, -13.0)
	var wr  := tip + Vector2(13.0, -13.0)
	draw_line(wl, tip, Color(1.0, 0.55, 0.08, pet_alpha * 1.15), 5.0, true)
	draw_line(wr, tip, Color(1.0, 0.55, 0.08, pet_alpha * 1.15), 5.0, true)
	draw_line(wl, wr,  Color(1.0, 0.55, 0.08, pet_alpha * 0.55), 2.2, true)
	draw_circle(tip, 3.5, Color(1.0, 0.80, 0.45, pet_alpha * 0.92))


## 钓鱼庆祝扩散环：金色最外圈 + 主色外圈 + 白内圈 + 8方向粒子，约 2.6 秒
## Layer depth follows the yard residents, including ducks and geese.
func _draw_fish_rings() -> void:
	if fish_ring_time <= 0.0:
		return
	var fp := fish_ring_pos
	const TOTAL := 2.6
	var t := 1.0 - clampf(fish_ring_time / TOTAL, 0.0, 1.0)
	# 根据鱼种选取主色（小鱼=水蓝，中等=深蓝，奇怪=紫）
	var mc: Color
	match fish_ring_type:
		"medium": mc = Color(0.32, 0.60, 0.92)
		"odd":    mc = Color(0.50, 0.42, 0.88)
		_:        mc = Color(0.42, 0.72, 0.88)
	# ── 金色最外圈（先声夺人，扩散最快）
	draw_arc(fp, lerpf(12.0, 80.0, t), 0.0, TAU, 48,
		Color(0.96, 0.82, 0.42, (1.0 - t) * 0.75), 4.5, true)
	# ── 主色外圈
	var ro := lerpf(8.0, 55.0, minf(t * 1.3, 1.0))
	var ao := maxf(0.0, 1.0 - t * 1.3) * 0.90
	draw_circle(fp, ro, Color(mc.r, mc.g, mc.b, ao * 0.18))
	draw_arc(fp, ro, 0.0, TAU, 36, Color(mc.r, mc.g + 0.12, mc.b + 0.06, ao), 3.8, true)
	# ── 白内圈（持续较久，让余辉感更长）
	var ri := lerpf(4.0, 34.0, minf(t * 1.8, 1.0))
	var ai := maxf(0.0, 1.0 - t * 1.8)
	draw_arc(fp, ri, 0.0, TAU, 28, Color(0.80, 0.95, 1.0, ai), 3.0, true)
	# ── 中心亮核（金色衬底 + 白核）
	var cr := 10.0 * maxf(0.0, 1.0 - t * 2.5)
	if cr > 0.5:
		draw_circle(fp, cr * 1.5, Color(0.98, 0.88, 0.55, ai * 0.80))
		draw_circle(fp, cr,       Color(0.98, 1.00, 1.00, ai * 1.15))
	# ── 8 方向粒子爆射（仅前 0.6s，增强瞬间冲击感）
	if t < 0.6:
		var pt2 := t / 0.6
		var pa  := (1.0 - pt2) * 0.85
		for i: int in 8:
			var angle := float(i) * TAU / 8.0
			var px := fp + Vector2(cos(angle), sin(angle) * 0.6) * lerpf(8.0, 46.0, pt2)
			draw_circle(px, lerpf(4.5, 1.5, pt2), Color(mc.r, mc.g + 0.20, 1.0, pa))
