class_name YardWorld
extends Node2D

signal album_updated(collected: PackedStringArray, latest_id: String)
signal weather_changed(weather: String)
signal notice_requested(key: String)
signal notice_dismiss_requested(key: String)
signal camera_focus_requested(world_point: Vector2, zoom: float)
signal camera_release_requested
signal day_advanced(day: int)
## 钓到鱼时触发，带上鱼种类字符串，供 HUD 做更强的收杆反馈动画
signal fish_caught(carry_type: String)

const SUNNY := preload("res://assets/holiday/environment/yard_sunny.png")
const OVERCAST := preload("res://assets/holiday/environment/yard_overcast.png")
const GrassPatchType := preload("res://scripts/entities/grass_patch.gd")
const FeltActorType := preload("res://scripts/entities/felt_actor.gd")
const VacationerType := preload("res://scripts/entities/vacationer.gd")
## 世界特效覆盖层（z_index=50），解决宠物目标弧和钓鱼庆祝环被动物精灵遮挡的根因
const WorldEffectsOverlayType := preload("res://scripts/game/world_effects_overlay.gd")
const WORLD_SIZE := Vector2(1280, 720)
# 人只站在画里已经对上地面的几个位置。圆点是可以走过去的下一处。
const PICTURE_SPOTS := {
	"door": {"position": Vector2(250, 508), "depth": 1.0, "facing": 1.0, "neighbors": ["grass"]},
	"grass": {"position": Vector2(420, 548), "depth": 1.1, "facing": 1.0, "neighbors": ["door", "by_llama", "pond"]},
	"by_llama": {"position": Vector2(578, 478), "depth": 0.88, "facing": 1.0, "neighbors": ["grass", "by_cow", "by_goose"]},
	"by_cow": {"position": Vector2(545, 508), "depth": 1.02, "facing": -1.0, "neighbors": ["by_llama", "grass"]},
	"pond": {"position": Vector2(620, 575), "depth": 1.16, "facing": -1.0, "neighbors": ["grass"]},
	"by_goose": {"position": Vector2(760, 500), "depth": 0.96, "facing": -1.0, "neighbors": ["by_llama", "pen"]},
	"pen": {"position": Vector2(980, 488), "depth": 0.9, "facing": -1.0, "neighbors": ["by_goose", "shed"]},
	"shed": {"position": Vector2(1100, 536), "depth": 1.06, "facing": -1.0, "neighbors": ["pen"]},
}

var weather := "sun"
var season := "late_summer"
var collected: PackedStringArray = []
var last_photo := ""
var photo_moments: Dictionary = {}
var simulation_active := true
var input_enabled := true

# ── 假期天数 / 昼夜 ───────────────────────────────────────────────────────────
## 每 DAY_DURATION_SECONDS 真实游玩秒数 = 1个假期天
const DAY_DURATION_SECONDS := 600.0
var holiday_day := 1
var _day_elapsed := 0.0       # 本天内已流逝的秒数
var _save_interval := 60.0    # 每隔60秒自动存档一次

# ── 植物床状态 ─────────────────────────────────────────────────────────────────
## 0=空, 1=已种, 2=发芽, 3=开花
const PLANT_EMPTY := 0
const PLANT_PLANTED := 1
const PLANT_SPROUTING := 2
const PLANT_BLOOMED := 3
var _plant_state := 0
var _plant_day_planted := 0
var _plant_watered_day := -1

# ── 钓鱼状态 ──────────────────────────────────────────────────────────────────
## 0=空闲, 1=已抛竿（等待）, 2=有反应！, 3=钓到了
const FISH_IDLE := 0
const FISH_CASTING := 1
const FISH_BITE := 2
const FISH_CAUGHT := 3
var _fish_state := 0
var _fish_timer := 0.0
var _fish_caught_total := 0
var _first_fish_polaroid_done := false
## 钓到后的携带状态："small"/"medium"/"odd"，空=无
var _fish_carry_type: String = ""
## 携带倒计时（秒），归零后鱼自动溜走
var _fish_carry_timer: float = 0.0
## 咬钩提醒计时器：BITE 期间每隔一段时间重发通知，防止玩家错过
var _fish_bite_nudge: float = 0.0
## 钓到鱼后的视觉庆祝闪光计时（秒）；> 0 时绘制扩散环动画
var _fish_catch_flash: float = 0.0
## 上次钓到时记录的鱼种（用于绘制时区分颜色）
var _fish_catch_type: String = ""
## 收获花朵庆祝动画计时（秒）
var _plant_harvest_flash: float = 0.0
## 最近一次抚摸的动物物种名，防止跨物种拍立得误触发
var _just_petted_species: String = ""

var _backdrop: Sprite2D
var _player: Vacationer
var _actors: Dictionary = {}
var _zones: Dictionary = {}
var _pulse := 0.0
var _weather_timer := 0.0
var _cooldowns: Dictionary = {}
var _held: Dictionary = {}
var _focus_seconds := 0.0
var _leading := false
var _day_seconds := 0.0
var _grass_patch: GrassPatch
var _lead_rope: Line2D
## 世界特效覆盖层节点（z_index=50）
var _effects_overlay: Node2D
var _spot := "door"
var _move_held := false
var _has_walk_goal := false
var _walk_goal := Vector2.ZERO
var _pending_interaction := ""
var _walk_path: Array[Vector2] = []
var _body_repath := 0.0
var _rejected_point := Vector2.ZERO
var _rejected_seconds := 0.0
## 当前被软选中（鼠标/最近）的可抚摸动物，用于绘制瞄准指示点
var _target_animal: FeltActor = null


func setup(
	saved_photos: Array = [],
	saved_moments: Dictionary = {},
	saved_day: int = 1,
	saved_day_elapsed: float = 0.0,
	saved_plant: Dictionary = {},
	saved_fish_caught: bool = false
) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collected = PackedStringArray()
	photo_moments.clear()
	for item: Variant in saved_photos:
		var photo_id := str(item)
		if photo_id not in collected:
			collected.append(photo_id)
		var moment := PhotoMoment.sanitize(saved_moments.get(photo_id,{}))
		if not moment.is_empty() and str(moment.get("rule_id","")) == photo_id:
			photo_moments[photo_id] = moment
	# 读取假期天数进度
	holiday_day = maxi(1, saved_day)
	_day_elapsed = maxf(0.0, saved_day_elapsed)
	# 读取植物床进度
	_plant_state = clampi(int(saved_plant.get("state", 0)), 0, 3)
	_plant_day_planted = maxi(0, int(saved_plant.get("day_planted", 0)))
	_plant_watered_day = int(saved_plant.get("watered_day", -1))
	# 读取钓鱼记录
	_first_fish_polaroid_done = saved_fish_caught
	_backdrop = Sprite2D.new()
	_backdrop.centered = false
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backdrop.z_index = -1
	add_child(_backdrop)
	_apply_weather_art()
	_define_zones()
	_spawn_grass()
	_spawn_cast()
	_bind_grounds()
	_lead_rope = Line2D.new()
	_lead_rope.width = 2.2
	_lead_rope.default_color = Color(0.38,0.25,0.13,0.90)
	_lead_rope.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_lead_rope.end_cap_mode = Line2D.LINE_CAP_ROUND
	_lead_rope.antialiased = true
	add_child(_lead_rope)
	_lead_rope.visible = false
	# 特效覆盖层：z_index=50，渲染在所有动物精灵之上（动物默认 z_index=0）
	## 这是宠物目标弧和钓鱼庆祝环不可见的根本修复——之前在 _draw() 绘制时
	## 因同处 z_index=0 但场景树顺序靠前，被动物子节点精灵完全遮挡。
	_effects_overlay = WorldEffectsOverlayType.new()
	_effects_overlay.z_index = 50
	add_child(_effects_overlay)
	_weather_timer = randf_range(42.0, 78.0)
	queue_redraw()


func get_player() -> Vacationer:
	return _player


func get_world_size() -> Vector2:
	return WORLD_SIZE


## 当天已流逝比例（0.0=天刚亮, 1.0=接近夜末），用于昼夜渐变
func tod_fraction() -> float:
	return _day_elapsed / DAY_DURATION_SECONDS


## 根据玩家当前位置返回合适的上下文提示键
## 牵行/持草/持鱼时优先显示操作提示，其余按位置决定
func hint_context() -> String:
	if _player == null:
		return "hud.hint.default"
	# 高优先级：牵行、持草、持鱼状态的操作提示
	if _leading:
		return "hud.hint.leading"
	if not _fish_carry_type.is_empty():
		return "hud.hint.carrying_fish"
	if _player.carrying_grass:
		return "hud.hint.carrying"
	var pos := _player.position
	# 钓鱼区域
	if pos.distance_to(_fishing_point()) < 90.0:
		if _fish_state == FISH_IDLE:
			return "hud.hint.near_pond"
		if _fish_state == FISH_CASTING:
			return "hud.hint.fishing"
		if _fish_state == FISH_BITE:
			return "hud.hint.fish_bite"
	# 植物床区域
	if pos.distance_to(_plant_point()) < 80.0:
		match _plant_state:
			PLANT_EMPTY:
				return "hud.hint.plant_empty"
			PLANT_PLANTED:
				return "hud.hint.plant_water"
			PLANT_SPROUTING:
				return "hud.hint.plant_water"
			PLANT_BLOOMED:
				# 开花后可收获，提示更新
				return "hud.hint.plant_bloomed"
	# 可抚摸动物
	for pet_id: String in ["cow", "sheep_a", "sheep_b", "horse"]:
		var pet_actor := actor_named(pet_id)
		if pet_actor != null and pos.distance_to(pet_actor.position) < 85.0:
			return "hud.hint.near_animal"
	# 草泥马附近
	var llama := actor_named("llama")
	if llama != null and pos.distance_to(llama.position) < 90.0:
		return "hud.hint.near_llama"
	# 草堆附近
	if pos.distance_to(_grass_point()) < 90.0:
		return "hud.hint.near_grass"
	return "hud.hint.default"


func collected_count() -> int:
	return collected.size()


func collectible_total() -> int:
	return ExpressionCatalog.all_ids().size()


# P0.1: 供 HUD 读取当前是否正在牵行，用来显示上下文提示文字。
func is_leading() -> bool:
	return _leading


# P1.3: 供 HUD 读取玩家是否正在持草，用来切换上下文提示文字。
func is_player_carrying_grass() -> bool:
	return _player != null and _player.carrying_grass


# P1.3: 供 HUD 读取玩家是否靠近草堆（距离 < 78px），不用于现在但保留供后续 HUD 逻辑。
func is_near_grass() -> bool:
	return _player != null and not _player.carrying_grass and _player.position.distance_to(_grass_point()) < 78.0


func is_mainline_complete() -> bool:
	for rule_id: String in ExpressionCatalog.llama_mainline_ids():
		if rule_id not in collected:
			return false
	return true


func set_weather(next_weather: String) -> void:
	if next_weather == weather:
		return
	weather = next_weather
	_apply_weather_art()
	TuningStore.apply_boundary("NEXT_STAGE")
	weather_changed.emit(weather)


func toggle_weather() -> void:
	set_weather("overcast" if weather == "sun" else "sun")


func debug_force_rule(rule_id: String) -> bool:
	var rule := ExpressionCatalog.find_rule(rule_id)
	if rule.is_empty():
		return false
	_apply_rule(rule, true)
	return true


func actor_named(actor_id: String) -> FeltActor:
	return _actors.get(actor_id) as FeltActor


func debug_place_actor(actor_id: String, point: Vector2) -> void:
	var actor: FeltActor = actor_named(actor_id)
	if actor == null:
		return
	actor.position = point
	if actor._rig != null:
		actor._rig.reset_contacts()
	actor._velocity=Vector2.ZERO
	actor.current_zone = _zone_at(point)
	actor.end_lead()


func debug_place_player(point: Vector2) -> void:
	if _player == null:
		return
	_player.position = point
	_player.reset_locomotion()


func tick(delta: float, move: Vector2) -> void:
	if not simulation_active:
		return
	_rejected_seconds = maxf(0.0, _rejected_seconds - delta)
	_day_seconds += delta
	# 推进假期天数（每 DAY_DURATION_SECONDS 秒 = 1天）
	_day_elapsed += delta
	if _day_elapsed >= DAY_DURATION_SECONDS:
		_day_elapsed -= DAY_DURATION_SECONDS
		holiday_day += 1
		_on_new_day()
	# 定时自动存档
	_save_interval -= delta
	if _save_interval <= 0.0:
		_save_interval = 60.0
		_save_progress()
	# 钓鱼计时
	_tick_fishing(delta)
	# 收获花朵庆祝动画计时
	if _plant_harvest_flash > 0.0:
		_plant_harvest_flash -= delta
		queue_redraw()
	# 钓到鱼后的携带倒计时：超时自动放回水里
	if _fish_carry_timer > 0.0:
		_fish_carry_timer -= delta
		if _fish_carry_timer <= 0.0 and not _fish_carry_type.is_empty():
			_fish_carry_type = ""
			notice_requested.emit("notice.fishing.release")
			queue_redraw()
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		toggle_weather()
		_weather_timer = randf_range(48.0, 90.0)
	if _player == null:
		return
	_player.body_obstacles = physical_obstacles("player")
	_body_repath = maxf(0.0,_body_repath-delta)
	if input_enabled:
		if move.length() > 0.2:
			_rejected_seconds = 0.0
			notice_dismiss_requested.emit("notice.cannot_walk")
			_has_walk_goal = false
			_pending_interaction = ""
			_walk_path.clear()
		elif _has_walk_goal:
			if _pending_interaction == "llama":
				_walk_goal = actor_named("llama").position
			if not _pending_interaction.is_empty() and _player.position.distance_to(_walk_goal) < 64.0:
				_has_walk_goal = false
				_walk_path.clear()
				var target := _pending_interaction
				_pending_interaction = ""
				_interact_with_target(target)
			var obstacles := _routing_obstacles()
			if _has_walk_goal and _body_repath <= 0.0 and (_walk_path.is_empty() or not YardBodies.clear_segment(_player.position,_walk_path[0],_player.body_radius*YardGround.depth_at(_player.position.y),obstacles)):
				_walk_path = YardBodies.route(_player.position,_walk_goal,_player.body_radius*YardGround.depth_at(_player.position.y),obstacles,YardGround.lawn())
				_body_repath = 0.7
				# A moving animal may occupy the destination briefly. Keep intent
				# and retry while standing; never silently abandon the tap.
			var destination := _walk_path[0] if not _walk_path.is_empty() else _walk_goal
			if not _walk_path.is_empty() and _player.position.distance_to(destination) < (12.0 if _walk_path.size()==1 else 4.0):
				_walk_path.pop_front()
				destination = _walk_path[0] if not _walk_path.is_empty() else _walk_goal
			var to_goal := destination - _player.position
			if not _has_walk_goal or (to_goal.length() < 12.0 and _walk_path.is_empty()):
				_has_walk_goal = false
				move = Vector2.ZERO
			elif _walk_path.is_empty():
				move = Vector2.ZERO
			else:
				move = to_goal.normalized() * (1.0 if _walk_path.size() > 1 else minf(1.0, to_goal.length() / 44.0))
		_player.tick(delta, move, WORLD_SIZE)
	else:
		_player.tick(delta, Vector2.ZERO, WORLD_SIZE)
	if _grass_patch != null: _grass_patch.tick(delta)
	var animal_scale := float(TuningStore.get_value("enemies.visual.scale", 1.0))
	var animal_speed := float(TuningStore.get_value("enemies.move.speed_multiplier", 1.0))
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		actor.speed = actor.get_meta("base_speed", actor.speed) * animal_speed
		actor.set_meta("visual_scale", animal_scale)
		if _leading and actor_id == "llama":
			actor.begin_lead(_player)
		elif actor.state == "lead" and actor_id == "llama":
			actor.end_lead()
		if actor_id == "llama" and _pending_interaction == "llama" and not _leading:
			actor.state = "graze"
			actor._idle_time = maxf(actor._idle_time, 0.5)
		actor.body_obstacles = physical_obstacles(actor_id)
		actor.tick(delta, WORLD_SIZE)
		actor.current_zone = _zone_at(actor.position)
		# 生态扫视：可抚摸动物偶尔朝玩家转头，草泥马/鸭/大鹅除外
		if _player != null and actor.species in ["cow", "sheep", "horse"]:
			actor.tick_glance(delta, _player.position)
	_update_lead_rope()
	_player.player_state = _player.snapshot_state()
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = float(_cooldowns[key]) - delta
		if float(_cooldowns[key]) <= 0.0:
			_cooldowns.erase(key)
	for key: Variant in _held.keys():
		_held[key] = float(_held[key]) - delta
		if float(_held[key]) <= 0.0:
			_held.erase(key)
	_pulse += delta
	var interval := float(TuningStore.get_value("gameplay.expression.pulse", 1.6))
	if _pulse >= interval:
		_pulse = 0.0
		_evaluate_expressions()
	if _focus_seconds > 0.0:
		_focus_seconds -= delta
		if _focus_seconds <= 0.0:
			camera_release_requested.emit()
	# 更新当前软选中动物（最近可抚摸动物，无光标坐标）
	_target_animal = _nearest_pettable_actor(85.0)
	# 更新特效覆盖层：宠物目标弧（alpha 修正：线性衰减，不再平方，确保在感应边缘也可见）
	_update_effects_overlay(delta)
	# P1.3: 玩家靠近草堆时，草堆缓慢呼吸发亮；远离时保持极轻微的呼吸感暗示互动性。
	if _grass_patch != null and _player != null:
		var near_grass := not _player.carrying_grass and _player.position.distance_to(_grass_point()) < 78.0
		if near_grass:
			# 靠近：明显呼吸
			var glow := 1.0 + 0.14 * sin(_day_seconds * 3.4)
			_grass_patch.modulate = Color(glow, glow, glow, 1.0)
		else:
			# 远离：极轻微常驻呼吸，提示此处有东西
			var ambient := 1.0 + 0.03 * sin(_day_seconds * 0.9)
			_grass_patch.modulate = Color(ambient, ambient, ambient, 1.0)
	queue_redraw()


# Space is intentionally contextual. Pointer/HUD commands keep their selected target.
func try_interact() -> void:
	if not input_enabled or _player == null:
		return
	var pos := _player.position
	# 手持鱼时：优先投喂附近的鸭/鹅（扩大感应范围至 110px，更易命中）
	if not _fish_carry_type.is_empty():
		for toss_id: String in ["duck_a", "duck_b", "duck_c", "goose"]:
			var toss_target := actor_named(toss_id)
			if toss_target != null and pos.distance_to(toss_target.position) < 110.0:
				_interact_with_target("toss_fish_%s" % toss_target.species)
				return
	# 钓鱼
	if pos.distance_to(_fishing_point()) < 85.0:
		_interact_with_target("fishing")
		return
	# 植物床
	if pos.distance_to(_plant_point()) < 75.0:
		_interact_with_target("plant")
		return
	# 拿草
	if pos.distance_to(_grass_point()) < 78.0 and not _player.carrying_grass:
		_interact_with_target("grass")
		return
	# 可抚摸动物：选最近的（Space/Enter 不带光标坐标，只按玩家距离排序）
	var nearest_pet := _nearest_pettable_actor(80.0)
	if nearest_pet != null:
		_interact_with_target("pet_%s" % nearest_pet.species)
		return
	# 默认：草泥马
	_interact_with_target("llama")


func _consume_pending_action() -> void:
	_pending_interaction = ""
	_has_walk_goal = false
	_walk_path.clear()


func _interact_with_target(target: String) -> void:
	if not input_enabled or _player == null:
		return
	TuningStore.apply_boundary("NEXT_ACTION")
	if target == "grass":
		if _player.position.distance_to(_grass_point()) < 78.0 and not _player.carrying_grass:
			_consume_pending_action()
			_grass_patch.harvest(_player)
			notice_requested.emit("notice.picked_grass")
		return
	var llama: FeltActor = _actors.get("llama")
	if target == "llama" and llama != null and _player.position.distance_to(llama.position) < 88.0:
		_consume_pending_action()
		if _player.carrying_grass:
			_player.consume_grass()
			llama.hold_expression("happy", 4.0)
			notice_requested.emit("notice.fed_llama")
			_evaluate_expressions()
			return
		_leading = not _leading
		_player.leading = _leading
		if _leading:
			llama.begin_lead(_player)
			notice_requested.emit("notice.lead_start")
		else:
			llama.end_lead()
			notice_requested.emit("notice.lead_stop")
		return
	# 投喂鱼给鸭/鹅（toss_fish_duck / toss_fish_goose）
	if target.begins_with("toss_fish_"):
		if _fish_carry_type.is_empty():
			notice_requested.emit("notice.idle")
			return
		var species_name := target.substr(10)  # "duck" 或 "goose"
		# 找最近的对应物种
		var closest: FeltActor = null
		var closest_dist := 110.0
		for actor_id: String in _actors:
			var actor: FeltActor = _actors[actor_id]
			if actor.species == species_name:
				var d := _player.position.distance_to(actor.position)
				if d < closest_dist:
					closest_dist = d
					closest = actor
		if closest == null:
			notice_requested.emit("notice.idle")
			return
		_consume_pending_action()
		# 投喂：清除携带状态，动物做出短暂反应
		_fish_carry_type = ""
		_fish_carry_timer = 0.0
		closest.hold_expression("idle", 3.5)
		notice_requested.emit("notice.toss_fish.%s" % species_name)
		queue_redraw()
		return
	# 钓鱼互动
	if target == "fishing":
		_consume_pending_action()
		_start_fishing()
		return
	# 植物床互动
	if target == "plant":
		_consume_pending_action()
		_interact_plant()
		return
	# 抚摸动物（pet_cow / pet_sheep / pet_horse）
	if target.begins_with("pet_"):
		var species_name := target.substr(4)  # "cow", "sheep", "horse"
		# 找到最近的对应动物
		var closest: FeltActor = null
		var closest_dist := 90.0
		for actor_id: String in _actors:
			var actor: FeltActor = _actors[actor_id]
			if actor.species == species_name:
				var d := _player.position.distance_to(actor.position)
				if d < closest_dist:
					closest_dist = d
					closest = actor
		if closest != null:
			_consume_pending_action()
			# 记录被抚摸的物种，防止拍立得跨物种误触发（例如抚摸牛时解锁羊的拍立得）
			_just_petted_species = species_name
			_player.just_petted_seconds = 6.0
			_player.player_state = "just_petted"
			notice_requested.emit("notice.pet.%s" % species_name)
			_evaluate_expressions()
			return
	notice_requested.emit("notice.idle")


## 返回玩家附近（radius px 内）最近的可抚摸动物；无则返回 null
## 可选传入鼠标世界坐标 cursor_point，若提供则优先选光标下最近的动物
func _nearest_pettable_actor(radius: float = 85.0, cursor_point: Vector2 = Vector2.INF) -> FeltActor:
	if _player == null:
		return null
	var pos := _player.position
	var best: FeltActor = null
	var best_score := INF
	for pet_id: String in ["cow", "sheep_a", "sheep_b", "horse"]:
		var actor := actor_named(pet_id)
		if actor == null:
			continue
		var dist_player := pos.distance_to(actor.position)
		if dist_player >= radius:
			continue
		# 评分：首先按光标距离（若有），其次按玩家距离
		var score: float
		if cursor_point != Vector2.INF:
			score = cursor_point.distance_to(actor.position) * 0.6 + dist_player * 0.4
		else:
			score = dist_player
		if score < best_score:
			best_score = score
			best = actor
	return best


func primary_action_key() -> String:
	if _leading: return "action.release"
	if _player == null: return "action.grass"
	var pos := _player.position
	# 手持鱼时：优先检查附近是否有鸭/鹅可投喂
	if not _fish_carry_type.is_empty():
		for toss_id: String in ["duck_a", "duck_b", "duck_c", "goose"]:
			var toss_actor := actor_named(toss_id)
			if toss_actor != null and pos.distance_to(toss_actor.position) < 90.0:
				return "action.toss_fish"
	if _player.carrying_grass: return "action.feed"
	# 钓鱼区域
	if pos.distance_to(_fishing_point()) < 85.0:
		match _fish_state:
			FISH_IDLE: return "action.fish"
			FISH_CASTING: return "action.fish_waiting"
			FISH_BITE: return "action.reel"
	# 植物床区域（含收获）
	if pos.distance_to(_plant_point()) < 75.0:
		match _plant_state:
			PLANT_EMPTY: return "action.plant"
			PLANT_PLANTED, PLANT_SPROUTING: return "action.water"
			PLANT_BLOOMED: return "action.harvest"
	# 可抚摸动物：选最近的
	if _nearest_pettable_actor(85.0) != null:
		return "action.pet"
	return "action.grass"


func request_primary_action() -> void:
	if not input_enabled: return
	if _leading:
		_leading = false
		_player.leading = false
		actor_named("llama").end_lead()
		notice_requested.emit("notice.lead_stop")
		return
	var pos := _player.position
	# 手持鱼时：优先投喂附近鸭/鹅
	if not _fish_carry_type.is_empty():
		for toss_id: String in ["duck_a", "duck_b", "duck_c", "goose"]:
			var toss_actor := actor_named(toss_id)
			if toss_actor != null and pos.distance_to(toss_actor.position) < 90.0:
				_interact_with_target("toss_fish_%s" % toss_actor.species)
				return
		# 没有附近目标时，走向最近的鸭/鹅
		var nearest_toss: FeltActor = null
		var nearest_toss_dist := INF
		for toss_id: String in ["duck_a", "duck_b", "duck_c", "goose"]:
			var toss_actor := actor_named(toss_id)
			if toss_actor != null:
				var d := pos.distance_to(toss_actor.position)
				if d < nearest_toss_dist:
					nearest_toss_dist = d
					nearest_toss = toss_actor
		if nearest_toss != null:
			_request_action("toss_fish_%s" % nearest_toss.species, nearest_toss.position)
			return
	if _player.carrying_grass:
		_request_action("llama", actor_named("llama").position)
		return
	# 钓鱼
	if pos.distance_to(_fishing_point()) < 85.0:
		_interact_with_target("fishing")
		return
	# 植物床（所有生长阶段，包含收获）
	if pos.distance_to(_plant_point()) < 75.0:
		_interact_with_target("plant")
		return
	# 抚摸动物：选最近的
	var nearest_pet := _nearest_pettable_actor(85.0)
	if nearest_pet != null:
		_interact_with_target("pet_%s" % nearest_pet.species)
		return
	# 默认：去拿草
	_request_action("grass", _grass_point())


func request_pointer_action(point: Vector2) -> void:
	if not input_enabled or _player == null:
		return
	var llama := actor_named("llama")
	# 手持鱼时：点击鸭/鹅优先触发投喂（包括头部偏移 +30px）
	if not _fish_carry_type.is_empty():
		for toss_id: String in ["duck_a", "duck_b", "duck_c", "goose"]:
			var toss_actor := actor_named(toss_id)
			if toss_actor != null and (point.distance_to(toss_actor.position) < 68.0 or point.distance_to(toss_actor.position + Vector2(0, -30)) < 68.0):
				_request_action("toss_fish_%s" % toss_actor.species, toss_actor.position)
				return
	# 扩大各区域点击命中半径，让鼠标/触控与 Space 更一致
	if point.distance_to(_grass_point()) < 65.0:          # 草堆：45 → 65px
		_request_action("grass", _grass_point())
	elif llama != null and (point.distance_to(llama.position) < 55.0 or point.distance_to(llama.position + Vector2(0,-48)) < 60.0):
		_request_action("llama", llama.position)
	elif point.distance_to(_fishing_point()) < 80.0 or YardGround.in_pond(point):
		# 点击水塘或钓鱼点附近 → 去钓鱼（65 → 80px）
		_request_action("fishing", _fishing_point())
	elif point.distance_to(_plant_point()) < 70.0:         # 植物床：50 → 70px
		_request_action("plant", _plant_point())
	else:
		# 检查可抚摸动物：光标附近 65px 内，并结合玩家距离选最近的
		var cursor_pet := _nearest_pettable_actor(85.0, point)
		if cursor_pet != null and point.distance_to(cursor_pet.position) < 65.0:
			_request_action("pet_%s" % cursor_pet.species, cursor_pet.position)
		else:
			_request_action("", point)


func _request_action(target: String, goal: Vector2) -> void:
	notice_dismiss_requested.emit("notice.cannot_walk")
	_rejected_seconds = 0.0
	if target.is_empty() and YardGround.allows(goal,YardGround.lawn(),true):
		goal = _open_goal_near_body(goal)
	_pending_interaction = target
	_has_walk_goal = false
	_walk_path.clear()
	if not target.is_empty() and _player.position.distance_to(goal) < 64.0:
		_pending_interaction = ""
		_interact_with_target(target)
		return
	# A tap at our feet means stop here, not an unreachable destination.
	if target.is_empty() and YardGround.allows(goal,YardGround.lawn(),true) and _player.position.distance_to(goal) < 12.0:
		return
	if not try_walk_to(goal):
		_pending_interaction = ""
		_rejected_point = goal
		_rejected_seconds = 1.2
		queue_redraw()
		notice_requested.emit("notice.cannot_walk")


func try_walk_to(goal: Vector2) -> bool:
	if not input_enabled or _player == null:
		return false
	# Hit-testing happens once, in request_pointer_action. Re-snapping here could
	# replace an explicit llama destination with nearby grass or another animal.
	if not YardGround.allows(goal, YardGround.lawn(), true):
		return false
	if _player.position.distance_to(goal) < 12.0:
		return false
	_walk_path = YardBodies.route(_player.position, goal, _player.body_radius*YardGround.depth_at(_player.position.y), _routing_obstacles(), YardGround.lawn())
	_body_repath = 0.7
	# A valid lawn destination can be occupied by a moving animal at click time.
	# Retain it and let the normal waiting/repath loop resume when it clears.
	_has_walk_goal = true
	_walk_goal = goal
	return true


func physical_obstacles(exclude_id: String = "") -> Array:
	var result: Array = []
	if exclude_id != "player" and _player != null:
		result.append({"id":"player", "position":_player.position, "radius":_player.body_radius*YardGround.depth_at(_player.position.y)})
	for id: String in _actors:
		var actor: FeltActor = _actors[id]
		if id == exclude_id or actor.species == "duck": continue
		result.append({"id":id,"position":actor.position,"radius":actor.body_radius*YardGround.depth_at(actor.position.y)})
	return result


func _routing_obstacles() -> Array:
	var obstacles := physical_obstacles("player")
	# The selected llama is an interaction destination, not a walk-through
	# point. Leading still routes around it when the person reverses direction.
	if _pending_interaction == "llama":
		obstacles = obstacles.filter(func(item: Dictionary) -> bool: return item.id != "llama")
	return obstacles


func _open_goal_near_body(goal: Vector2) -> Vector2:
	var radius := _player.body_radius*YardGround.depth_at(_player.position.y)
	var obstacles := physical_obstacles("player")
	if YardBodies.clear_at(goal,radius,obstacles): return goal
	var best := goal
	var distance := INF
	for item: Dictionary in obstacles:
		var extent: Vector2 = radius + item.radius + Vector2(5,4)
		if ((goal-item.position)/extent).length_squared()>1.0: continue
		for i in 16:
			var angle := float(i)*TAU/16.0
			var candidate: Vector2 = item.position + Vector2(cos(angle),sin(angle))*extent
			if not YardGround.allows(candidate,YardGround.lawn(),true) or not YardBodies.clear_at(candidate,radius,obstacles): continue
			var score := candidate.distance_squared_to(_player.position)
			if score < distance:
				distance = score
				best = candidate
	return best


func try_step_to_point(point: Vector2) -> bool:
	if not input_enabled:
		return false
	var best := ""
	var best_distance := 76.0
	for spot_name: String in PICTURE_SPOTS:
		var spot: Dictionary = PICTURE_SPOTS[spot_name]
		var spot_pos: Vector2 = spot.position
		var distance := point.distance_to(spot_pos)
		if distance < best_distance:
			best_distance = distance
			best = spot_name
	if best == "" or best == _spot:
		return false
	_spot = best
	_apply_picture()
	notice_requested.emit("notice.step")
	return true


func _latch_move(move: Vector2) -> void:
	if move.length() < 0.25:
		_move_held = false
		return
	if _move_held:
		return
	_move_held = true
	_step_toward(move)


func _step_toward(direction: Vector2) -> void:
	var here: Dictionary = PICTURE_SPOTS[_spot]
	var origin: Vector2 = here.position
	var best := ""
	var best_dot := 0.34
	var aim := direction.normalized()
	for next_name: String in here.neighbors:
		var next_spot: Dictionary = PICTURE_SPOTS[next_name]
		var next_pos: Vector2 = next_spot.position
		var delta := next_pos - origin
		if delta.length() < 1.0:
			continue
		var alignment := delta.normalized().dot(aim)
		if alignment > best_dot:
			best_dot = alignment
			best = next_name
	if best == "":
		return
	_spot = best
	_apply_picture()
	notice_requested.emit("notice.step")


func _apply_picture() -> void:
	_place_player_spot()
	_pose_cast()


func _place_player_spot() -> void:
	if _player == null:
		return
	var spot: Dictionary = PICTURE_SPOTS[_spot]
	_player.position = spot.position
	_player.reset_locomotion()
	_player.facing = float(spot.facing)
	_player.picture_depth = float(spot.depth)
	_player.player_state = "idle"


func _pose_cast() -> void:
	if _actors.is_empty():
		return
	var layout := _cast_layout()
	var animal_scale := float(TuningStore.get_value("enemies.visual.scale", 1.0))
	for actor_id: String in layout:
		var actor: FeltActor = _actors.get(actor_id)
		if actor == null:
			continue
		var pose: Dictionary = layout[actor_id]
		if _leading and actor_id == "llama":
			pose = _lead_pose()
		actor.set_meta("visual_scale", animal_scale)
		actor.set_pose(pose.position, float(pose.scale)*float(actor.get_meta("source_scale_ratio",1.0)), float(pose.facing))
		actor.current_zone = _zone_at(actor.position)


func _lead_pose() -> Dictionary:
	var spot: Dictionary = PICTURE_SPOTS[_spot]
	var face := float(spot.facing)
	return {
		"position": _player.position + Vector2(-58.0 * face, 10.0),
		"scale": 0.32 * float(spot.depth),
		"facing": face,
	}


func _cast_layout() -> Dictionary:
	# 晴天各就各位。阴天大鹅改站到草泥马旁边，整张画换一个构图，而不是自己滑过去。
	var goose_point := Vector2(700, 466) if weather == "overcast" else Vector2(812, 496)
	var goose_scale := 0.32 if weather == "overcast" else 0.34
	return {
		"llama": {"position": Vector2(636, 452), "scale": 0.30, "facing": -1.0},
		"cow": {"position": Vector2(400, 516), "scale": 0.40, "facing": 1.0},
		"horse": {"position": Vector2(560, 505), "scale": 0.36, "facing": -1.0},
		"goose": {"position": goose_point, "scale": goose_scale, "facing": -1.0},
		"sheep_a": {"position": Vector2(990, 448), "scale": 0.28, "facing": -1.0},
		"sheep_b": {"position": Vector2(1088, 505), "scale": 0.34, "facing": -1.0},
		"duck_a": {"position": Vector2(688, 562), "scale": 0.26, "facing": 1.0},
		"duck_b": {"position": Vector2(746, 570), "scale": 0.24, "facing": -1.0},
		"duck_c": {"position": Vector2(652, 568), "scale": 0.25, "facing": 1.0},
	}


func _spawn_cast() -> void:
	_player = VacationerType.new()
	add_child(_player)
	_player.setup(Vector2(260, 540))
	var configs := [
		{
			"id": "llama",
			"species": "llama",
			"position": Vector2(560, 470),
			"wander": Rect2(500, 445, 240, 80),
			"zone": "pasture",
			"speed": 26.0,
			"scale": 0.36,
			"textures": {
				"idle": "res://assets/holiday/characters/llama.png",
				"annoyed": "res://assets/holiday/characters/llama_annoyed.png",
				"happy": "res://assets/holiday/characters/llama_happy.png",
				"smirk": "res://assets/holiday/characters/llama_smirk.png",
			},
		},
		{
			"id": "goose",
			"native_facing": -1.0,
			"species": "goose",
			"position": Vector2(800, 490),
			"wander": Rect2(720, 455, 150, 75),
			"zone": "pond",
			"speed": 34.0,
			"scale": 0.38,
			"textures": {"idle": "res://assets/holiday/characters/goose.png"},
		},
		{
			"id": "sheep_a",
			"species": "sheep",
			"position": Vector2(1020, 505),
			"wander": Rect2(970, 485, 150, 60),
			"zone": "pen",
			"speed": 22.0,
			"scale": 0.36,
			"textures": {"idle": "res://assets/holiday/characters/sheep_clingy.png"},
		},
		{
			"id": "sheep_b",
			"native_facing": -1.0,
			"species": "sheep",
			"position": Vector2(1120, 530),
			"wander": Rect2(1040, 500, 130, 55),
			"zone": "pen",
			"speed": 16.0,
			"scale": 0.34,
			"textures": {"idle": "res://assets/holiday/characters/sheep_dull.png"},
		},
		{
			"id": "cow",
			"native_facing": -1.0,
			"species": "cow",
			"position": Vector2(430, 510),
			"wander": Rect2(370, 470, 170, 80),
			"zone": "pasture",
			"speed": 14.0,
			"scale": 0.36,
			"textures": {"idle": "res://assets/holiday/characters/cow.png"},
		},
		{
			"id": "horse",
			"native_facing": -1.0,
			"species": "horse",
			"position": Vector2(650, 480),
			"wander": Rect2(570, 455, 155, 62),
			"zone": "pasture",
			"speed": 15.0,
			"scale": 0.36,
			"textures": {"idle": "res://assets/holiday/characters/cast_v2/horse.png"},
		},
		{
			"id": "duck_a",
			"species": "duck",
			"position": Vector2(680, 582),
			"wander": Rect2(620, 500, 160, 70),
			"zone": "pond",
			"speed": 18.0,
			"scale": 0.32,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
		{
			"id": "duck_b",
			"species": "duck",
			"position": Vector2(740, 594),
			"wander": Rect2(640, 510, 150, 70),
			"zone": "pond",
			"speed": 17.0,
			"scale": 0.30,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
		{
			"id": "duck_c",
			"species": "duck",
			"position": Vector2(650, 590),
			"wander": Rect2(610, 505, 170, 75),
			"zone": "pond",
			"speed": 19.0,
			"scale": 0.31,
			"textures": {"idle": "res://assets/holiday/characters/duck.png"},
		},
	]
	# Small non-overlapping homes follow the painted lawn, not the fence artwork.
	# Residents never chase the llama out of these homes; the llama can visit them.
	var homes := {
		"cow": Rect2(430, 465, 72, 48),
		"horse": Rect2(568, 444, 94, 45),
		"sheep_a": Rect2(282, 490, 54, 37),
		"sheep_b": Rect2(346, 473, 52, 36),
		"goose": Rect2(746, 492, 40, 20),
		"llama": Rect2(370, 447, 440, 78),
	}
	for original: Dictionary in configs:
		var id := str(original.id)
		original.daily_routine = true
		if homes.has(id):
			original.wander = homes[id]
			original.position = homes[id].get_center()
		if id == "llama": original.position = Vector2(705, 500)
		original.speed = {"cow": 10.0, "horse": 12.0, "sheep": 11.0, "goose": 13.0, "duck": 10.0, "llama": 23.0}[str(original.species)]
		var config:=CastArt.configure(original)
		var actor: FeltActor = FeltActorType.new()
		add_child(actor)
		actor.setup(config)
		actor.set_meta("source_scale_ratio",float(config.get("source_scale_ratio",1.0)))
		actor.set_meta("base_speed", float(config.get("speed", 28.0)))
		_actors[str(config.id)] = actor


func _define_zones() -> void:
	_zones = {
		"door": Rect2(40, 250, 280, 250),
		"pasture": Rect2(320, 300, 430, 220),
		"pond": Rect2(520, 470, 360, 180),
		"pen": Rect2(860, 280, 360, 250),
	}


func _zone_at(point: Vector2) -> String:
	for zone_name: String in _zones:
		var rect: Rect2 = _zones[zone_name]
		if rect.has_point(point):
			return zone_name
	return "pasture"


func _bind_grounds() -> void:
	_player.walk_ground = YardGround.lawn()
	_player.avoid_pond = true
	if not YardGround.allows(_player.position, YardGround.lawn(), true):
		_player.position = Vector2(260, 540)
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		if actor_id.begins_with("duck"):
			actor.adopt_ellipse(YardGround.POND_CENTER, Vector2(96, 28))
		elif actor_id.begins_with("sheep"):
			actor.adopt_ground(YardGround.lawn(), true)
		else:
			actor.adopt_ground(YardGround.lawn(), true)


func _grass_point() -> Vector2:
	# 草堆在门前小路边，人可以走过去拿。
	return Vector2(340, 600)


func _spawn_grass() -> void:
	_grass_patch = GrassPatchType.new()
	add_child(_grass_patch)
	_grass_patch.setup(_grass_point())


func _apply_weather_art() -> void:
	if _backdrop == null:
		return
	# Weather changes light, never the ground layout under the actors.
	_backdrop.texture = SUNNY
	if _backdrop.texture != null:
		var tex_size := _backdrop.texture.get_size()
		_backdrop.scale = Vector2(WORLD_SIZE.x / tex_size.x, WORLD_SIZE.y / tex_size.y)
	var filter_on := bool(TuningStore.get_value("environment.filter.enabled", true))
	var intensity := float(TuningStore.get_value("environment.filter.intensity", 0.12))
	if not filter_on:
		_backdrop.modulate = Color.WHITE
		return
	if weather == "overcast":
		_backdrop.modulate = Color(0.92, 0.90, 0.96).lerp(Color.WHITE, 1.0 - intensity)
	else:
		_backdrop.modulate = Color(1.0, 0.97, 0.90).lerp(Color.WHITE, 1.0 - intensity)


func _evaluate_expressions() -> void:
	var snapshot := _world_snapshot()
	var ranked: Array = ExpressionCatalog.RULES.duplicate()
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	var used_owners: Dictionary = {}
	for rule: Dictionary in ranked:
		var owner := str(rule.get("owner", ""))
		if used_owners.has(owner):
			continue
		if not _rule_matches(rule, snapshot):
			continue
		used_owners[owner] = true
		_apply_rule(rule, false)


func _world_snapshot() -> Dictionary:
	var nearby: Dictionary = {}
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		var near_list: Array = []
		for other_id: String in _actors:
			if other_id == actor_id:
				continue
			var other: FeltActor = _actors[other_id]
			if actor.is_near(other, float(TuningStore.get_value("gameplay.proximity.radius", 92.0))):
				near_list.append(other.species)
		nearby[actor_id] = near_list
	return {
		"weather": weather,
		"season": season,
		"player": _player.snapshot_state() if _player != null else "idle",
		"nearby": nearby,
		"actors": _actors,
	}


func _species_actors(species: String) -> Array:
	var matches: Array = []
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		if actor.species == species:
			matches.append(actor)
	return matches


func _rule_matches(rule: Dictionary, snapshot: Dictionary) -> bool:
	# manual_only 规则只能通过 _apply_rule(rule, true) 手动触发
	if bool(rule.get("manual_only", false)):
		return false
	var owner := str(rule.get("owner", ""))
	var actors := _species_actors(owner)
	if actors.is_empty():
		return false
	# min_day 节奏门控：防止玩家第一次进院就集齐所有拍立得
	if rule.has("min_day") and holiday_day < int(rule.min_day):
		return false
	if bool(rule.get("observe_nearby",false)):
		var close := false
		for subject in actors:
			if _player != null and _player.position.distance_to(subject.position) < 205.0:
				close = true
		if not close: return false
	if rule.has("weather") and str(rule.weather) != str(snapshot.weather):
		return false
	if rule.has("player") and str(rule.player) != str(snapshot.player):
		return false
	# 抚摸类规则（player=just_petted）只匹配对应物种，防止抚摸牛时解锁羊的拍立得
	if rule.has("player") and str(rule.player) == "just_petted" and not _just_petted_species.is_empty():
		if str(rule.get("owner", "")) != _just_petted_species:
			return false
	if rule.has("zone"):
		var wanted := str(rule.zone)
		var any_in_zone := false
		for actor: FeltActor in actors:
			if actor.current_zone == wanted:
				any_in_zone = true
		if not any_in_zone:
			return false
	if rule.has("nearby"):
		var ok := false
		for actor: FeltActor in actors:
			var near: Array = snapshot.nearby.get(actor.actor_id, [])
			if _contains_all(near, rule.nearby):
				ok = true
		if not ok:
			return false
	if rule.has("not_nearby"):
		for actor: FeltActor in actors:
			var near: Array = snapshot.nearby.get(actor.actor_id, [])
			for blocked: Variant in rule.not_nearby:
				if str(blocked) in near:
					return false
	if rule.has("same_zone") and not _species_share_zone(rule):
		return false
	# sees 表示玩家得站在近处，这张表情才算被看见。
	if bool(rule.get("sees", false)) and not _player_sees(actors):
		return false
	return true


func _species_share_zone(rule: Dictionary) -> bool:
	# 每种动物只要有一只在同一片区域即可。两只羊不必同时离开羊圈。
	var shared := str(rule.get("zone", ""))
	var species_list: Array = rule.same_zone
	if shared != "":
		for species: Variant in species_list:
			if not _species_in_zone(str(species), shared):
				return false
		return true
	var zones: Dictionary = {}
	for species: Variant in species_list:
		var group := _species_actors(str(species))
		if group.is_empty():
			return false
		for actor: FeltActor in group:
			zones[actor.current_zone] = true
	for zone_name: String in zones:
		var all_present := true
		for species: Variant in species_list:
			if not _species_in_zone(str(species), zone_name):
				all_present = false
				break
		if all_present:
			return true
	return false


func _species_in_zone(species: String, zone_name: String) -> bool:
	for actor: FeltActor in _species_actors(species):
		if actor.current_zone == zone_name:
			return true
	return false


func _player_sees(actors: Array) -> bool:
	if _player == null:
		return false
	var radius := float(TuningStore.get_value("gameplay.proximity.radius", 92.0)) * 2.2
	for actor: FeltActor in actors:
		if _player.position.distance_to(actor.position) <= radius:
			return true
	return false


func _contains_all(haystack: Array, needles: Array) -> bool:
	for needle: Variant in needles:
		if str(needle) not in haystack:
			return false
	return true


func _apply_rule(rule: Dictionary, force: bool) -> void:
	var rule_id := str(rule.get("id", ""))
	if not force and float(_cooldowns.get(rule_id, 0.0)) > 0.0:
		return
	var owner := str(rule.get("owner", ""))
	var actors := _species_actors(owner)
	if actors.is_empty():
		return
	var actor: FeltActor = actors[0]
	if owner == "llama":
		actor = _actors.get("llama")
	if actor == null:
		return
	var expression := str(rule.get("expression", "idle"))
	var hold := float(rule.get("hold", 4.0))
	actor.hold_expression(expression, hold)
	_held[rule_id] = hold
	_cooldowns[rule_id] = hold + float(TuningStore.get_value("gameplay.expression.cooldown", 16.0))
	if bool(rule.get("spit", false)):
		var goose := actor_named("goose")
		if goose != null:
			actor.spit(goose.global_position + Vector2(0,-30))
	if bool(rule.get("polaroid", false)):
		var first_collection := rule_id not in collected
		# Old saves keep all earned IDs. A missing scene photo is filled only
		# on the next real matching encounter, without another unlock or camera jump.
		if first_collection or not photo_moments.has(rule_id):
			# Event reactions may flip the actor immediately; capture the same pose
			# and attached rope together, not the preceding tick's endpoints.
			_update_lead_rope()
			var moment := PhotoMoment.capture(self,rule)
			if not moment.is_empty(): photo_moments[rule_id] = moment
			if first_collection:
				collected.append(rule_id)
				last_photo = rule_id
			if first_collection or not moment.is_empty(): album_updated.emit(collected, rule_id)
			if first_collection:
				_focus_seconds = 2.4
				camera_focus_requested.emit(actor.global_position + Vector2(0, -40), 1.16)


## 当假期翻天时调用：推进植物床、发送通知、保存进度
func _on_new_day() -> void:
	day_advanced.emit(holiday_day)
	notice_requested.emit("notice.new_day")
	# 推进植物生长
	if _plant_state == PLANT_PLANTED and holiday_day >= _plant_day_planted + 1:
		_plant_state = PLANT_SPROUTING
		notice_requested.emit("notice.plant.sprouting")
	elif _plant_state == PLANT_SPROUTING and holiday_day >= _plant_day_planted + 3 and _plant_watered_day >= _plant_day_planted:
		_plant_state = PLANT_BLOOMED
		notice_requested.emit("notice.plant.bloomed")
		# 首次开花触发拍立得（手动规则）
		if "plant_first_bloom" not in collected:
			var bloom_rule := ExpressionCatalog.find_rule("plant_first_bloom")
			if not bloom_rule.is_empty():
				_apply_rule(bloom_rule, true)
	_save_progress()
	queue_redraw()


## 保存当前假期进度到 SaveStore
func _save_progress() -> void:
	SaveStore.set_holiday_progress(holiday_day, _day_elapsed)
	SaveStore.set_plant_state(_plant_state, _plant_day_planted, _plant_watered_day)


## 钓鱼点（水塘北岸，玩家可以站到的最近处）
func _fishing_point() -> Vector2:
	return Vector2(700, 535)


## 植物床中心（门左侧小角落）
func _plant_point() -> Vector2:
	return Vector2(205, 575)


## 每帧推进钓鱼状态
func _tick_fishing(delta: float) -> void:
	# 钓到庆祝闪光计时：独立于钓鱼状态机，IDLE 时也继续倒计时
	if _fish_catch_flash > 0.0:
		_fish_catch_flash -= delta
		queue_redraw()
	# 同步特效覆盖层的庆祝环计时（overlay 自行处理 queue_redraw）
	if _effects_overlay != null and _effects_overlay.fish_ring_time > 0.0:
		_effects_overlay.fish_ring_time = maxf(0.0, _effects_overlay.fish_ring_time - delta)
		_effects_overlay.queue_redraw()
	if _fish_state == FISH_IDLE or _fish_state == FISH_CAUGHT:
		return
	if _fish_state == FISH_CASTING:
		_fish_timer -= delta
		# 玩家走远则取消
		if _player != null and _player.position.distance_to(_fishing_point()) > 110.0:
			_fish_state = FISH_IDLE
			return
		if _fish_timer <= 0.0:
			# 75% 概率钓到（原 55%），让玩家更容易走完钓鱼→携带→投喂的完整流程
			if randf() < 0.75:
				_fish_state = FISH_BITE
				_fish_timer = 6.0  # 6秒收杆窗口（原 4秒），减少突然错过的挫败感
				_fish_bite_nudge = 2.0  # 首次提示立即发出，之后每 2 秒重发
				notice_requested.emit("notice.fishing.bite")
			else:
				_fish_state = FISH_IDLE
				notice_requested.emit("notice.fishing.miss")
	elif _fish_state == FISH_BITE:
		_fish_timer -= delta
		# 每隔 2 秒重发咬钩提示，帮助玩家不错过收杆时机
		_fish_bite_nudge -= delta
		if _fish_bite_nudge <= 0.0:
			_fish_bite_nudge = 2.0
			notice_requested.emit("notice.fishing.bite")
		if _fish_timer <= 0.0:
			# 没有收杆，鱼跑了
			_fish_state = FISH_IDLE
			notice_requested.emit("notice.fishing.miss")
	queue_redraw()


## 开始钓鱼
func _start_fishing() -> void:
	if _player == null:
		return
	if _fish_state == FISH_IDLE:
		# 玩家需要走到钓鱼点附近
		if _player.position.distance_to(_fishing_point()) > 85.0:
			_request_action("fishing", _fishing_point())
			return
		_fish_state = FISH_CASTING
		# 等待时间缩短至 5-10 秒（原 9-16 秒），让玩家更快进入咬钩环节
		_fish_timer = randf_range(5.0, 10.0)
		notice_requested.emit("notice.fishing.cast")
		queue_redraw()
	elif _fish_state == FISH_BITE:
		# 收杆！
		_reel_in_fish()
	elif _fish_state == FISH_CASTING:
		# 还在等咬钩：按 Space/Enter 不取消钓鱼，提示玩家继续等待
		## 取消方式改为走离钓鱼点 110px 以上，避免与收杆操作混淆
		notice_requested.emit("notice.fishing.wait")


## 收杆并处理收获
func _reel_in_fish() -> void:
	_fish_caught_total += 1
	# 先设为 CAUGHT 状态：让拍立得在本帧内捕捉到钓到鱼的瞬间
	_fish_state = FISH_CAUGHT
	# 随机决定鱼的类型：小鱼(60%) / 中等(25%) / 奇怪(15%)
	var roll := randf()
	var carry_type: String
	if roll < 0.60:
		carry_type = "small"
		notice_requested.emit("notice.fishing.caught")
	elif roll < 0.85:
		carry_type = "medium"
		notice_requested.emit("notice.fishing.caught.medium")
	else:
		carry_type = "odd"
		notice_requested.emit("notice.fishing.caught.odd")
	# 收杆成功信号：供 HUD 做明确的视觉反馈（区别于普通按钮脉冲）
	fish_caught.emit(carry_type)
	# 首次钓到 → 触发拍立得（在 FISH_CAUGHT 状态下拍摄）
	if not _first_fish_polaroid_done:
		_first_fish_polaroid_done = true
		SaveStore.set_first_fish_caught()
		var fish_rule := ExpressionCatalog.find_rule("fish_first_catch")
		if not fish_rule.is_empty():
			_apply_rule(fish_rule, true)
	# 拍立得拍摄后重置钓鱼逻辑，改用携带计时器跟踪
	_fish_state = FISH_IDLE
	_fish_carry_type = carry_type
	_fish_carry_timer = 20.0  # 20秒内可投喂给鸭/鹅，给玩家充裕时间走到鸭鹅旁
	# 启动钓到庆祝闪光：2.6 秒多环扩散 + 粒子爆射，并记录鱼种以区分颜色
	_fish_catch_flash = 2.6
	_fish_catch_type = carry_type
	# 同步到特效覆盖层（z_index=50，在鸭/鹅精灵之上渲染，确保玩家必然看见庆祝环）
	if _effects_overlay != null:
		_effects_overlay.fish_ring_time = 2.6
		_effects_overlay.fish_ring_type = carry_type
		_effects_overlay.fish_ring_pos = _fishing_point()
		_effects_overlay.queue_redraw()
	queue_redraw()


## 与植物床互动（种植 / 浇水）
func _interact_plant() -> void:
	if _player == null:
		return
	if _player.position.distance_to(_plant_point()) > 75.0:
		_request_action("plant", _plant_point())
		return
	match _plant_state:
		PLANT_EMPTY:
			_plant_state = PLANT_PLANTED
			_plant_day_planted = holiday_day
			_plant_watered_day = -1
			notice_requested.emit("notice.plant.planted")
			SaveStore.set_plant_state(_plant_state, _plant_day_planted, _plant_watered_day)
		PLANT_PLANTED:
			if _plant_watered_day < holiday_day:
				_plant_watered_day = holiday_day
				notice_requested.emit("notice.plant.watered")
				SaveStore.set_plant_state(_plant_state, _plant_day_planted, _plant_watered_day)
			else:
				notice_requested.emit("notice.plant.already_watered")
		PLANT_SPROUTING:
			if _plant_watered_day < holiday_day:
				_plant_watered_day = holiday_day
				notice_requested.emit("notice.plant.watered")
				SaveStore.set_plant_state(_plant_state, _plant_day_planted, _plant_watered_day)
			else:
				notice_requested.emit("notice.plant.already_watered")
		PLANT_BLOOMED:
			# 收获花朵，土地重置为空地（可再次种植）
			_plant_state = PLANT_EMPTY
			_plant_day_planted = 0
			_plant_watered_day = -1
			notice_requested.emit("notice.plant.harvested")
			SaveStore.set_plant_state(_plant_state, _plant_day_planted, _plant_watered_day)
			# 收获庆祝：短暂的花瓣粒子爆发（用 _plant_harvest_flash 计时器驱动）
			_plant_harvest_flash = 1.8
	queue_redraw()


func _update_lead_rope() -> void:
	if _lead_rope == null: return
	_lead_rope.visible = _leading and _player != null
	if not _lead_rope.visible: return
	var llama := actor_named("llama")
	var hand := _player.grass_hand_global_position()
	# Actual approved llama art's lower-neck point, relative to its foot anchor.
	var collar := llama.to_global(Vector2(875, 665) - llama._ground_anchor)
	var midpoint := (hand+collar)*0.5 + Vector2(0,10)
	var cord := PackedVector2Array()
	for i in 17:
		var t := float(i)/16.0
		cord.append(to_local(hand.lerp(midpoint,t).lerp(midpoint.lerp(collar,t),t)))
	_lead_rope.points = cord
	# A held rope belongs above its wearers' clothing, not behind every sprite.
	_lead_rope.z_index = maxi(_player.z_index,llama.z_index)+2


## 每帧更新特效覆盖层的宠物目标弧数据
## alpha 修正：改用线性衰减（不再平方），确保在感应边缘（60-105px）也能清晰显示
func _update_effects_overlay(_delta: float) -> void:
	if _effects_overlay == null:
		return
	_effects_overlay.pet_day_t = _day_seconds
	# 不可抚摸状态：清除目标
	if _player == null or _leading or not _fish_carry_type.is_empty() or _player.carrying_grass:
		_effects_overlay.pet_pos = Vector2.INF
		_effects_overlay.pet_alpha = 0.0
		_effects_overlay.queue_redraw()
		return
	# 找最近的可抚摸动物（感应半径 105px）
	var nearest: FeltActor = null
	var nearest_dist := 105.0
	for pet_id: String in ["cow", "sheep_a", "sheep_b", "horse"]:
		var a := actor_named(pet_id)
		if a == null:
			continue
		var d := _player.position.distance_to(a.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = a
	if nearest == null:
		_effects_overlay.pet_pos = Vector2.INF
		_effects_overlay.pet_alpha = 0.0
		_effects_overlay.queue_redraw()
		return
	# 线性衰减（原平方衰减在 85px 时 alpha<0.05 → 完全不可见，这是 playtest 失败根因）
	## 新公式：60px 内全亮，60-105px 线性淡出——在任何感应距离内都清晰可见
	var proximity := clampf(1.0 - (nearest_dist - 60.0) / 45.0, 0.0, 1.0)
	var pulse := 0.70 + 0.30 * absf(sin(_day_seconds * 2.4))
	_effects_overlay.pet_pos = nearest.position
	_effects_overlay.pet_alpha = 0.95 * proximity * pulse
	_effects_overlay.queue_redraw()


func _draw() -> void:
	if _rejected_seconds > 0.0:
		var alpha := minf(1.0, _rejected_seconds / 0.35) * 0.80
		var ink := Color(0.52,0.31,0.20,alpha)
		# Two quiet broken arcs mark the actual tap without implying a new path.
		draw_arc(_rejected_point, 12.0, 0.30, PI-0.30, 20, ink, 2.2, true)
		draw_arc(_rejected_point, 12.0, PI+0.30, TAU-0.30, 20, ink, 2.2, true)
	if _has_walk_goal:
		draw_arc(_walk_goal, 10.0, 0.0, TAU, 24, Color(1.0,0.92,0.65,0.85), 2.0)
	if _player != null:
		_draw_contact_shadow(_player.position,Vector2(11,4)*YardGround.depth_at(_player.position.y))
	for actor_id: String in _actors:
		var actor: FeltActor = _actors[actor_id]
		var extent := Vector2(actor.body_radius.x,actor.body_radius.y*0.42)*YardGround.depth_at(actor.position.y)
		_draw_contact_shadow(actor.position,extent)
	# Contact shadows leave a translated/scaled draw transform. Props below
	# are expressed in world coordinates, so restore identity before drawing.
	draw_set_transform(Vector2.ZERO)
	# 绘制植物床
	_draw_plant_bed()
	# 绘制钓鱼区域与鱼竿（庆祝扩散环已移至 _effects_overlay，此处保留鱼竿/浮标/常驻涟漪）
	_draw_fishing_spot()
	# 宠物目标弧和钓鱼庆祝环现在由 _effects_overlay（z_index=50）绘制，不再在此调用
	## 保留 _draw_pet_target_arc() 和 _draw_target_indicator() 函数定义（供调试/测试引用）


## 绘制种植槽：用同心椭圆叠加模拟透视土壤斑，不使用矩形。
## 土壤随玩家距离渐显（>180px 完全隐藏），避免远处"棕色贴纸"感。
## 架构注意：仍是 Canvas 层叠加，无 3D 遮挡；根本改善需后续将院子重构为真实场景。
func _draw_plant_bed() -> void:
	var pt := _plant_point()
	# 土壤可见度：随玩家距离平滑渐隐，消除远处"棕色贴纸"感。
	## 80px 以内：完全可见；80-200px：线性衰减（平方使靠近时揭示更自然）；>200px：完全隐藏。
	var dist_to_pt := _player.position.distance_to(pt) if _player != null else 300.0
	var soil_reveal := clampf(1.0 - (dist_to_pt - 80.0) / 120.0, 0.0, 1.0)
	soil_reveal = soil_reveal * soil_reveal
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
	match _plant_state:
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
			var lean := sin(_day_seconds * 0.9) * 1.2
			var base := pt + Vector2(0, -3)
			var sprout_tip := base + Vector2(lean, -11)
			if soil_reveal > 0.05:
				draw_circle(base + Vector2(0, 1), 2.8, Color(0.20, 0.14, 0.08, 0.40 * soil_reveal))
			draw_line(base, sprout_tip, Color(0.38, 0.62, 0.32, 0.95), 2.2, true)
			draw_line(base + Vector2(lean * 0.4, -3), sprout_tip + Vector2(-6, 0), Color(0.44, 0.68, 0.36, 0.88), 2.0, true)
			draw_line(base + Vector2(lean * 0.5, -5), sprout_tip + Vector2(6, -1), Color(0.44, 0.68, 0.36, 0.88), 2.0, true)
		PLANT_BLOOMED:
			# 花朵：始终显示（花朵是亮眼功能，不随距离隐藏）；茎基阴影随土壤渐显
			var sway := sin(_day_seconds * 1.2) * 1.8
			var base := pt + Vector2(0, -3)
			var bloom_tip := base + Vector2(sway, -15)
			if soil_reveal > 0.05:
				draw_circle(base + Vector2(0, 2), 4.0, Color(0.18, 0.12, 0.07, 0.38 * soil_reveal))
			draw_line(base, bloom_tip, Color(0.38, 0.62, 0.32, 0.92), 2.2, true)
			for i: int in 5:
				var angle := float(i) / 5.0 * TAU - PI * 0.5
				draw_circle(bloom_tip + Vector2(0, -1) + Vector2(cos(angle), sin(angle)) * 5.5, 3.2, Color(0.92, 0.68, 0.76, 0.90))
			draw_circle(bloom_tip + Vector2(0, -1), 3.0, Color(0.98, 0.90, 0.55, 0.95))
	# 收获庆祝：花瓣爆散动画（_plant_harvest_flash > 0 时激活）
	if _plant_harvest_flash > 0.0:
		var t := 1.0 - clampf(_plant_harvest_flash / 1.8, 0.0, 1.0)
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
	if _plant_state == PLANT_BLOOMED:
		var bloom_pulse := 0.30 + 0.25 * absf(sin(_day_seconds * 2.2))
		for _ei: int in _ELLIPSE_SEGS + 1:
			var _a := float(_ei) / float(_ELLIPSE_SEGS) * TAU
			_ellipse_pts.append(pt + Vector2(cos(_a) * 34.0, sin(_a) * 12.0))
		draw_polyline(_ellipse_pts, Color(0.92, 0.68, 0.76, bloom_pulse), 2.8, true)
	else:
		var near_plant := _player != null and _player.position.distance_to(pt) < 80.0
		var indicator_alpha := 0.22 if near_plant else 0.04
		for _ei: int in _ELLIPSE_SEGS + 1:
			var _a := float(_ei) / float(_ELLIPSE_SEGS) * TAU
			_ellipse_pts.append(pt + Vector2(cos(_a) * 30.0, sin(_a) * 10.0))
		draw_polyline(_ellipse_pts, Color(0.58, 0.42, 0.26, indicator_alpha), 1.4, true)


## 绘制钓鱼点标记与钓鱼状态（常驻波纹、鱼竿、浮标）
## 注意：庆祝扩散环已移至 WorldEffectsOverlay（z_index=50），此处不再绘制，
## 避免在 z_index=0 时被鸭/鹅精灵遮挡（这是 playtest #3 中庆祝环"不可见"的根因）
func _draw_fishing_spot() -> void:
	var fp := _fishing_point()
	var player_near := _player != null and _player.position.distance_to(fp) < 100.0
	# 水塘常驻波纹：三圈相位错开的扩散涟漪，给水面带来生气
	var ripple_t := float(Time.get_ticks_msec()) * 0.001
	for i: int in 3:
		var phase := fmod(ripple_t * 0.4 + float(i) / 3.0, 1.0)
		var r := lerpf(6.0, 30.0, phase)
		var a := (1.0 - phase) * 0.22
		draw_arc(fp + Vector2(10, 12), r, 0.0, TAU, 20, Color(0.42, 0.68, 0.88, a), 1.8, true)
	if not player_near and _fish_state == FISH_IDLE:
		return
	# 指示圆（靠近时才显示）
	if player_near and _fish_state == FISH_IDLE:
		draw_arc(fp, 22.0, 0.0, TAU, 24, Color(0.48, 0.60, 0.75, 0.30), 1.2, true)
	# 鱼竿（总是显示，玩家在附近时）
	if player_near or _fish_state != FISH_IDLE:
		var rod_base := fp + Vector2(-4, -2)
		var rod_tip := fp + Vector2(20, -32)
		draw_line(rod_base, rod_tip, Color(0.40, 0.28, 0.18, 0.82), 2.5, true)
		# 钓鱼中：画鱼线和浮标
		if _fish_state == FISH_CASTING or _fish_state == FISH_BITE:
			var float_target := fp + Vector2(28, 18)
			draw_line(rod_tip, float_target, Color(0.38, 0.28, 0.18, 0.65), 1.2, true)
			# 浮标颜色：有咬钩时变红
			var bob_color := Color(0.90, 0.32, 0.25, 0.92) if _fish_state == FISH_BITE else Color(0.80, 0.88, 0.96, 0.85)
			draw_circle(float_target, 3.8, bob_color)
			# 有咬钩时浮标加闪烁提示（两段脉冲，速度加快，更难错过）
			if _fish_state == FISH_BITE:
				var pulse1 := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
				draw_circle(float_target, 7.5, Color(0.90, 0.32, 0.25, pulse1 * 0.55))
				draw_arc(float_target, 10.0, 0.0, TAU, 16, Color(0.95, 0.50, 0.38, pulse1 * 0.40), 2.2, true)
		elif _fish_state == FISH_CAUGHT:
			# 钓上来！画一条小鱼（此状态极短，主要由 _fish_catch_flash 提供视觉反馈）
			var fish_pos := fp + Vector2(28, 8)
			draw_line(rod_tip, fish_pos, Color(0.38, 0.28, 0.18, 0.65), 1.2, true)
			draw_circle(fish_pos, 4.0, Color(0.55, 0.75, 0.82, 0.90))
			draw_arc(fish_pos + Vector2(4, 0), 3.0, PI * 0.6, PI * 1.4, 8, Color(0.45, 0.65, 0.72, 0.88), 2.0, true)


## 在被软选中的动物脚下绘制一个淡淡的选中圆弧，告知玩家当前会互动哪只动物
func _draw_target_indicator() -> void:
	if _target_animal == null or _player == null:
		return
	# 牵行、持鱼、持草时不显示（有更高优先级操作）
	if _leading or not _fish_carry_type.is_empty() or _player.carrying_grass:
		return
	var pt := _target_animal.position
	# 随时间缓慢脉冲，alpha 在 0.18~0.38 间呼吸
	var pulse_a := 0.28 + 0.10 * sin(_day_seconds * 2.6)
	# 软杏色：与院子暖色调融合
	var col := Color(0.92, 0.75, 0.52, pulse_a)
	draw_arc(pt, 14.0, 0.0, TAU, 20, col, 1.8, true)
	# 上方小三角形暗示"你将与这只动物互动"
	var tip := pt + Vector2(0, -28)
	draw_line(tip + Vector2(-5, 4), tip, col, 1.5, true)
	draw_line(tip + Vector2(5, 4), tip, col, 1.5, true)


func _draw_contact_shadow(point: Vector2, extent: Vector2) -> void:
	draw_set_transform(point+Vector2(0,1.5),0.0,extent)
	draw_circle(Vector2.ZERO,1.20,Color(0.29,0.25,0.16,0.035))
	draw_circle(Vector2.ZERO,0.97,Color(0.29,0.25,0.16,0.060))
	draw_circle(Vector2.ZERO,0.70,Color(0.29,0.25,0.16,0.055))


## 绘制最近可抚摸动物的软目标弧 + 地面环 + 箭头（高对比橙色，带呼吸脉冲）
## 仅当玩家位于抚摸感应范围内（< 105px）且非牵行/携带状态时显示
func _draw_pet_target_arc() -> void:
	if _player == null or _leading or not _fish_carry_type.is_empty() or _player.carrying_grass:
		return
	# 找最近的可抚摸动物（感应半径扩大至 105px，让玩家更早看到提示）
	var nearest_pet: FeltActor = null
	var nearest_dist := 105.0
	for pet_id: String in ["cow", "sheep_a", "sheep_b", "horse"]:
		var pet_actor := actor_named(pet_id)
		if pet_actor == null:
			continue
		var d := _player.position.distance_to(pet_actor.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_pet = pet_actor
	if nearest_pet == null:
		return
	# 透明度随距离平方衰减（近处超亮，远处快速衰减），叠加脉冲
	var proximity := 1.0 - clampf((nearest_dist - 30.0) / 75.0, 0.0, 1.0)
	proximity = proximity * proximity
	var pulse := 0.62 + 0.38 * absf(sin(_day_seconds * 2.4))
	var arc_alpha := 0.95 * proximity * pulse
	if arc_alpha < 0.05:
		return
	var pt := nearest_pet.position
	# ── 地面柔光（填充圆 + 实心橙圈）：一眼告知脚下有目标
	var ground_r := 22.0 + 3.0 * absf(sin(_day_seconds * 2.4))
	draw_circle(pt, ground_r, Color(0.95, 0.68, 0.32, arc_alpha * 0.30))
	draw_arc(pt, 20.0, 0.0, TAU, 28, Color(1.0, 0.55, 0.08, arc_alpha * 0.75), 2.8, true)
	# ── 头部半圆弧（180°，5.5px，纯橙色 + 暗色光晕底）
	draw_arc(pt, 42.0, -PI * 0.90, -PI * 0.10, 36, Color(0.55, 0.26, 0.0, arc_alpha * 0.35), 9.0, true)
	draw_arc(pt, 42.0, -PI * 0.90, -PI * 0.10, 36, Color(1.0, 0.55, 0.08, arc_alpha), 5.5, true)
	# ── 内圈辅助弧
	draw_arc(pt, 31.0, -PI * 0.82, -PI * 0.18, 26, Color(1.0, 0.80, 0.45, arc_alpha * 0.58), 2.2, true)
	# ── 向下箭头（↓）：5.0px，尖端实心圆
	var tip := pt + Vector2(0.0, -33.0)
	var wl  := tip + Vector2(-13.0, -13.0)
	var wr  := tip + Vector2(13.0, -13.0)
	draw_line(wl, tip, Color(1.0, 0.55, 0.08, arc_alpha * 1.15), 5.0, true)
	draw_line(wr, tip, Color(1.0, 0.55, 0.08, arc_alpha * 1.15), 5.0, true)
	draw_line(wl, wr, Color(1.0, 0.55, 0.08, arc_alpha * 0.55), 2.2, true)
	draw_circle(tip, 3.5, Color(1.0, 0.80, 0.45, arc_alpha * 0.92))
