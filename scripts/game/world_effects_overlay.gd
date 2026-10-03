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

# Success feedback belongs to the one bird that received the fish. A weak
# reference keeps this visual-only cue out of snapshots and save data.
const BIRD_FEEDBACK_DURATION := 1.8
var _bird_feedback_actor: WeakRef
var _bird_feedback_time := 0.0

# New feedback cels keep the transient response in the same painted world as
# the animals. These timers, unlike watering/plant state, never enter a save.
const PET_CEL := preload("res://assets/holiday/fx/pet_heart_watercolor.png")
const WATER_CEL := preload("res://assets/holiday/fx/water_splash_watercolor.png")
const OBJECT_FEEDBACK_DURATION := 1.6
var _pet_feedback_actor: WeakRef
var _pet_feedback_time := 0.0
var _plant_feedback_pos := Vector2.ZERO
var _plant_feedback_time := 0.0


func play_pet_feedback(animal: FeltActor) -> void:
	if animal == null or animal.species not in ["cow", "sheep", "horse"]:
		return
	_pet_feedback_actor = weakref(animal)
	_pet_feedback_time = OBJECT_FEEDBACK_DURATION
	queue_redraw()


func play_plant_water_feedback(point: Vector2) -> void:
	_plant_feedback_pos = point
	_plant_feedback_time = OBJECT_FEEDBACK_DURATION
	queue_redraw()


func advance_object_feedback(delta: float) -> void:
	_pet_feedback_time = maxf(0.0, _pet_feedback_time - delta)
	_plant_feedback_time = maxf(0.0, _plant_feedback_time - delta)
	if _pet_feedback_time <= 0.0:
		_pet_feedback_actor = null


func pet_feedback_snapshot() -> Dictionary:
	if _pet_feedback_time <= 0.0 or _pet_feedback_actor == null:
		return {}
	var animal := _pet_feedback_actor.get_ref() as FeltActor
	if animal == null:
		return {}
	return {"actor_id": animal.actor_id, "position": animal.position,
		"remaining": _pet_feedback_time,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false))}


func plant_feedback_snapshot() -> Dictionary:
	if _plant_feedback_time <= 0.0:
		return {}
	return {"position": _plant_feedback_pos, "remaining": _plant_feedback_time,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false))}


func play_fish_feed_feedback(bird: FeltActor) -> void:
	if bird == null or bird.species not in ["duck", "goose"]:
		return
	_bird_feedback_actor = weakref(bird)
	_bird_feedback_time = BIRD_FEEDBACK_DURATION
	queue_redraw()


func advance_bird_feedback(delta: float) -> void:
	if _bird_feedback_time <= 0.0:
		return
	_bird_feedback_time = maxf(0.0, _bird_feedback_time - delta)
	if _bird_feedback_time <= 0.0:
		_bird_feedback_actor = null


func bird_feedback_snapshot() -> Dictionary:
	if _bird_feedback_time <= 0.0 or _bird_feedback_actor == null:
		return {}
	var bird := _bird_feedback_actor.get_ref() as FeltActor
	if bird == null:
		return {}
	return {
		"actor_id": bird.actor_id,
		"position": bird.position,
		"remaining": _bird_feedback_time,
		"reduced_motion": bool(TuningStore.get_value("ui.reduced_motion", false)),
	}




# Low motion keeps the orange target and the catch rings readable without a pulse or flying specks.
static func celebration_pose(kind: String, t: float, reduced_motion: bool) -> Dictionary:
	if kind == "target":
		var radius := 18.0 if reduced_motion else 18.0 + 2.5 * absf(sin(t * 2.4))
		# REQ-019: brightness/alpha pulse was left out of REQ-018; freeze it under low motion.
		var alpha_pulse := 1.0 if reduced_motion else 0.75 + 0.25 * absf(sin(t * 2.4))
		return {"glow_radius": radius, "alpha_pulse": alpha_pulse}
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



# REQ-022: one-shot pet/plant/bird cues stay readable under low motion — no mid-cue fade or float.
static func object_feedback_pose(kind: String, progress: float, remaining: float, reduced_motion: bool) -> Dictionary:
	progress = clampf(progress, 0.0, 1.0)
	if kind == "bird":
		if reduced_motion:
			return {
				"rise": 0.0,
				"ring_radius": 18.0,
				"ring_alpha": 0.55,
				"heart_alpha": 0.92,
			}
		var alpha := clampf(remaining / 0.45, 0.0, 1.0)
		return {
			"rise": 20.0 * progress,
			"ring_radius": lerpf(13.0, 30.0, progress),
			"ring_alpha": alpha * maxf(0.0, 1.0 - progress * 1.3) * 0.68,
			"heart_alpha": alpha,
		}
	# pet heart / plant water splash share duration and fade timing.
	if reduced_motion:
		return {"rise": 0.0, "opacity": 1.0}
	var rise_cap := 10.0 if kind == "pet" else 5.0
	return {
		"rise": rise_cap * progress,
		"opacity": clampf(remaining / 0.38, 0.0, 1.0),
	}


func _draw() -> void:
	_draw_pet_arc()
	_draw_fish_rings()
	_draw_bird_feedback()
	_draw_pet_feedback()
	_draw_plant_water_feedback()


func _draw_pet_feedback() -> void:
	var feedback := pet_feedback_snapshot()
	if feedback.is_empty():
		return
	var animal := _pet_feedback_actor.get_ref() as FeltActor
	var progress := 1.0 - _pet_feedback_time / OBJECT_FEEDBACK_DURATION
	var reduced := bool(feedback.reduced_motion)
	var pose := object_feedback_pose("pet", progress, _pet_feedback_time, reduced)
	var crown := animal.position + Vector2(0.0, -animal.marker_crown_lift() - 25.0 - float(pose.rise))
	# A full painted cel, not a polygonal UI heart; low motion holds opacity steady.
	draw_texture_rect(PET_CEL, Rect2(crown - Vector2(24.0, 24.0), Vector2(48.0, 48.0)),
		false, Color(1.0, 1.0, 1.0, float(pose.opacity)))


func _draw_plant_water_feedback() -> void:
	var feedback := plant_feedback_snapshot()
	if feedback.is_empty():
		return
	var progress := 1.0 - _plant_feedback_time / OBJECT_FEEDBACK_DURATION
	var reduced := bool(feedback.reduced_motion)
	var pose := object_feedback_pose("plant", progress, _plant_feedback_time, reduced)
	var top_left := _plant_feedback_pos + Vector2(-30.0, -54.0 - float(pose.rise))
	draw_texture_rect(WATER_CEL, Rect2(top_left, Vector2(60.0, 60.0)),
		false, Color(1.0, 1.0, 1.0, float(pose.opacity)))


## 宠物目标：脚底柔光 + 明确画在头顶上方的半圆弧与向下箭头
func _draw_pet_arc() -> void:
	if pet_pos == Vector2.INF or pet_alpha < 0.05:
		return
	var feet := pet_pos
	var lift := maxf(48.0, pet_lift)
	# 冠顶中心：脚底向上 lift，再上移一点让弧离开耳朵
	var crown := feet + Vector2(0.0, -(lift + 18.0))
	var reduced := bool(TuningStore.get_value("ui.reduced_motion", false))
	var pose := celebration_pose("target", pet_day_t, reduced)
	# YardWorld still multiplies proximity by a live pulse; under low motion undo that pulse and use the fixed alpha_pulse.
	var alpha := pet_alpha
	if reduced:
		var live_pulse := 0.75 + 0.25 * absf(sin(pet_day_t * 2.4))
		if live_pulse > 0.01:
			alpha = pet_alpha / live_pulse * float(pose.alpha_pulse)
	# ── 脚底柔光（次要线索，不抢头顶主信号）
	var gr := float(pose.glow_radius)
	draw_circle(feet, gr, Color(0.95, 0.68, 0.32, alpha * 0.22))
	draw_arc(feet, 16.0, 0.0, TAU, 24, Color(1.0, 0.55, 0.08, alpha * 0.55), 2.2, true)
	# ── 头顶主弧（半径更大，明确“在动物上方”）
	draw_arc(crown, 28.0, -PI * 0.95, -PI * 0.05, 36, Color(0.45, 0.20, 0.0, alpha * 0.40), 10.0, true)
	draw_arc(crown, 28.0, -PI * 0.95, -PI * 0.05, 36, Color(1.0, 0.52, 0.06, alpha), 6.0, true)
	draw_arc(crown, 18.0, -PI * 0.88, -PI * 0.12, 28, Color(1.0, 0.82, 0.45, alpha * 0.70), 2.6, true)
	# ── 向下箭头：尖端指向冠顶，整体完全在精灵轮廓之上
	var tip := crown + Vector2(0.0, -10.0)
	var wl := tip + Vector2(-16.0, -16.0)
	var wr := tip + Vector2(16.0, -16.0)
	draw_line(wl, tip, Color(1.0, 0.52, 0.06, minf(1.0, alpha * 1.20)), 6.0, true)
	draw_line(wr, tip, Color(1.0, 0.52, 0.06, minf(1.0, alpha * 1.20)), 6.0, true)
	draw_line(wl, wr, Color(1.0, 0.52, 0.06, alpha * 0.60), 2.6, true)
	draw_circle(tip, 4.5, Color(1.0, 0.88, 0.50, alpha * 0.95))


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


func _draw_bird_feedback() -> void:
	var feedback := bird_feedback_snapshot()
	if feedback.is_empty():
		return
	var bird := _bird_feedback_actor.get_ref() as FeltActor
	var elapsed := 1.0 - _bird_feedback_time / BIRD_FEEDBACK_DURATION
	var reduced := bool(feedback.reduced_motion)
	var pose := object_feedback_pose("bird", elapsed, _bird_feedback_time, reduced)
	draw_arc(bird.position, float(pose.ring_radius), 0.0, TAU, 32,
		Color(0.95, 0.51, 0.57, float(pose.ring_alpha)), 2.2, true)
	# Anchor near the live bird's crown; the bubbles follow a wandering duck.
	var origin := bird.position + Vector2(8.0, -minf(bird.marker_crown_lift(), 68.0) - 8.0 - float(pose.rise))
	var heart_a := float(pose.heart_alpha)
	_draw_heart(origin + Vector2(-8.0, 0.0), 18.0, heart_a)
	_draw_heart(origin + Vector2(18.0, -14.0), 9.0, heart_a * 0.78)


func _draw_heart(center: Vector2, radius: float, alpha: float) -> void:
	var outline := PackedVector2Array()
	for i: int in 32:
		var angle := float(i) * TAU / 32.0
		var x := 16.0 * pow(sin(angle), 3.0)
		var y := -(13.0 * cos(angle) - 5.0 * cos(2.0 * angle) - 2.0 * cos(3.0 * angle) - cos(4.0 * angle))
		outline.append(center + Vector2(x, y) * (radius / 18.0))
	draw_colored_polygon(outline, Color(0.97, 0.53, 0.57, alpha * 0.92))
	outline.append(outline[0])
	draw_polyline(outline, Color(0.58, 0.26, 0.31, alpha * 0.75), 1.3, true)
	draw_circle(center + Vector2(-radius * 0.35, -radius * 0.35), radius * 0.14, Color(1.0, 0.91, 0.78, alpha * 0.86))
