extends Node2D
## YardWorld 每帧把本层 z_index 推到「所有角色脚底深度 + 1」之上。
## 切勿写死 z_index=50：FeltActor 使用 z_index = roundi(position.y)（约 400–600），
## 固定 50 会整层画在动物脚下——这正是 playtest #3 / game-8280e92 的真根因。

# ── 宠物目标弧（可抚摸动物的橙色选中指示）─────────────────────────────────────
## Vector2.INF = 无目标（跳过绘制）
var pet_pos: Vector2 = Vector2.INF
var pet_alpha: float = 0.0
var pet_day_t: float = 0.0
## 脚底到冠顶的抬升量（世界像素）；弧与箭头画在冠顶上方，地面环仍留在脚底
var pet_lift: float = 64.0

# ── 钓鱼庆祝扩散环（收杆成功时的金色+主色同心环）──────────────────────────────
## > 0 时绘制并倒计时；= 0 时跳过
var fish_ring_time: float = 0.0
var fish_ring_type: String = ""        # "small" / "medium" / "odd"
var fish_ring_pos: Vector2 = Vector2.ZERO


func _draw() -> void:
	_draw_pet_arc()
	_draw_fish_rings()


## 宠物目标：脚底柔光 + 明确画在头顶上方的半圆弧与向下箭头
func _draw_pet_arc() -> void:
	if pet_pos == Vector2.INF or pet_alpha < 0.05:
		return
	var feet := pet_pos
	var lift := maxf(48.0, pet_lift)
	# 冠顶中心：脚底向上 lift，再上移一点让弧离开耳朵
	var crown := feet + Vector2(0.0, -(lift + 18.0))
	# ── 脚底柔光（次要线索，不抢头顶主信号）
	var gr := 18.0 + 2.5 * absf(sin(pet_day_t * 2.4))
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
	var mc: Color
	match fish_ring_type:
		"medium": mc = Color(0.28, 0.58, 0.95)
		"odd":    mc = Color(0.55, 0.40, 0.92)
		_:        mc = Color(0.35, 0.78, 0.95)
	# ── 金色最外圈
	draw_arc(fp, lerpf(16.0, 110.0, t), 0.0, TAU, 56,
		Color(1.0, 0.86, 0.35, (1.0 - t) * 0.95), 6.0, true)
	# ── 主色外圈 + 填充
	var ro := lerpf(10.0, 72.0, minf(t * 1.25, 1.0))
	var ao := maxf(0.0, 1.0 - t * 1.25) * 1.0
	draw_circle(fp, ro, Color(mc.r, mc.g, mc.b, ao * 0.28))
	draw_arc(fp, ro, 0.0, TAU, 40, Color(mc.r, mc.g + 0.10, mc.b + 0.08, ao), 5.0, true)
	# ── 白内圈
	var ri := lerpf(6.0, 44.0, minf(t * 1.7, 1.0))
	var ai := maxf(0.0, 1.0 - t * 1.7)
	draw_arc(fp, ri, 0.0, TAU, 32, Color(0.85, 0.98, 1.0, ai), 4.0, true)
	# ── 中心亮核
	var cr := 14.0 * maxf(0.0, 1.0 - t * 2.2)
	if cr > 0.5:
		draw_circle(fp, cr * 1.6, Color(1.0, 0.90, 0.45, ai * 0.90))
		draw_circle(fp, cr, Color(1.0, 1.0, 1.0, ai * 1.25))
	# ── 12 方向粒子（前 0.7s）
	if t < 0.7:
		var pt2 := t / 0.7
		var pa := (1.0 - pt2) * 0.95
		for i: int in 12:
			var angle := float(i) * TAU / 12.0
			var px := fp + Vector2(cos(angle), sin(angle) * 0.55) * lerpf(10.0, 64.0, pt2)
			draw_circle(px, lerpf(6.0, 1.5, pt2), Color(mc.r, mc.g + 0.18, 1.0, pa))
	# ── 短时大字提示环心上方（前 1.2s），不依赖 HUD 通知也能看见“钓到了”
	if t < 0.55:
		var banner_a := (1.0 - t / 0.55) * 0.95
		var bp := fp + Vector2(0.0, -48.0)
		draw_circle(bp, 22.0, Color(0.12, 0.22, 0.38, banner_a * 0.55))
		draw_arc(bp, 22.0, 0.0, TAU, 28, Color(1.0, 0.92, 0.55, banner_a), 3.0, true)
