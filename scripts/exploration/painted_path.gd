class_name PaintedPath
extends RefCounted
## Shared painted-road geometry; each page provides original-image coordinates.

var ART: String
var SIZE: Vector2
var JUNCTION: Vector2
var ARMS: Dictionary
var HOME_ARM: String
var START: Dictionary
var WALK_SPEED: float
var NEAR: float
var HOME_HOLD: float
var MIN_ALIGN: float
var HOME_TAP_REACH: float
var HOME_TAP_BELOW: float
var DEPTH_NEAR_Y: float
var DEPTH_FAR_Y: float
var DEPTH_NEAR: float
var DEPTH_FAR: float
var WALKER_BOX: Rect2
var FULL_VIEW_MIN: float
var PHONE_VIEW_HEIGHT: float
var PHONE_VIEW_WIDTH: float
var STOPS: Array

func _init(definition: Dictionary) -> void:
	for key: String in definition:
		set(key, definition[key])

func stop(stop_id: String) -> Dictionary:
	for entry: Dictionary in STOPS:
		if entry.id == stop_id:
			return entry
	return {}


func arm_length(arm: String) -> float:
	var points: Array = ARMS[arm]
	var total := 0.0
	for i in range(1, points.size()):
		total += (points[i] as Vector2).distance_to(points[i - 1])
	return total


func point(arm: String, d: float) -> Vector2:
	var points: Array = ARMS[arm]
	var left := clampf(d, 0.0, arm_length(arm))
	for i in range(1, points.size()):
		var a: Vector2 = points[i - 1]
		var b: Vector2 = points[i]
		var span := a.distance_to(b)
		if left <= span or i == points.size() - 1:
			return a.lerp(b, clampf(left / maxf(span, 0.001), 0.0, 1.0))
		left -= span
	return points[-1]


## 沿路离开岔口的方向（单位向量）
func tangent(arm: String, d: float) -> Vector2:
	var length := arm_length(arm)
	var a := point(arm, clampf(d - 2.0, 0.0, length))
	var b := point(arm, clampf(d + 2.0, 0.0, length))
	return (b - a).normalized() if a.distance_to(b) > 0.01 else (point(arm, 4.0) - JUNCTION).normalized()


## 整条路从岔口到尽头的大方向
func heading(arm: String) -> Vector2:
	var points: Array = ARMS[arm]
	return ((points[-1] as Vector2) - JUNCTION).normalized()


func depth(y: float) -> float:
	return lerpf(DEPTH_FAR, DEPTH_NEAR, clampf((y - DEPTH_FAR_Y) / (DEPTH_NEAR_Y - DEPTH_FAR_Y), 0.0, 1.0))


## 画面上任意一点最近的路上位置
func nearest(target: Vector2) -> Dictionary:
	var best := {"arm": ARMS.keys()[0], "d": 0.0, "gap": INF}
	for arm: String in ARMS:
		var points: Array = ARMS[arm]
		var walked := 0.0
		for i in range(1, points.size()):
			var a: Vector2 = points[i - 1]
			var b: Vector2 = points[i]
			var span := a.distance_to(b)
			var t := clampf((target - a).dot(b - a) / maxf(span * span, 0.001), 0.0, 1.0)
			var gap := target.distance_to(a.lerp(b, t))
			if gap < float(best.gap):
				best = {"arm": arm, "d": walked + t * span, "gap": gap}
			walked += span
	return best


## 沿路从 from 走向 to 的下一段：同一条路直接走，不同路先回岔口
func step_toward(from: Dictionary, to: Dictionary, distance: float) -> Dictionary:
	var arm: String = from.arm
	var d: float = from.d
	if arm == to.arm or d <= 0.01:
		if arm != to.arm:
			arm = to.arm
			d = 0.0
		var goal: float = to.d
		return {"arm": arm, "d": move_toward(d, goal, distance)}
	return {"arm": arm, "d": maxf(d - distance, 0.0)}


func route_length(from: Dictionary, to: Dictionary) -> float:
	if from.arm == to.arm:
		return absf(float(from.d) - float(to.d))
	return float(from.d) + float(to.d)


## 方向键：沿当前路的投影走；在岔口选与方向最顺的那条路
func step_input(from: Dictionary, direction: Vector2, distance: float) -> Dictionary:
	if direction.length() < 0.01:
		return from
	var dir := direction.normalized()
	var arm: String = from.arm
	var d: float = from.d
	if d <= 0.5:
		var best_arm := arm
		var best_align := -INF
		for candidate: String in ARMS:
			var align := dir.dot((tangent(candidate, 0.0) + heading(candidate)).normalized())
			if align > best_align:
				best_align = align
				best_arm = candidate
		if best_align < MIN_ALIGN:
			return from
		return {"arm": best_arm, "d": minf(distance, arm_length(best_arm))}
	var along := dir.dot(tangent(arm, d))
	if absf(along) < MIN_ALIGN:
		along = dir.dot(heading(arm))
	if absf(along) < MIN_ALIGN:
		return from
	return {"arm": arm, "d": clampf(d + signf(along) * distance, 0.0, arm_length(arm))}


func at_home(spot: Dictionary) -> bool:
	return not HOME_ARM.is_empty() and spot.arm == HOME_ARM and float(spot.d) >= arm_length(HOME_ARM) - 0.5


func home_direction() -> Vector2:
	return Vector2.ZERO if HOME_ARM.is_empty() else tangent(HOME_ARM, arm_length(HOME_ARM))


## 点在院门一带（路尽头上方、不太远）才算点了回院；路尽头右下的石头、草地只走过去
func is_home_tap(art: Vector2) -> bool:
	if HOME_ARM.is_empty(): return false
	var end := point(HOME_ARM, arm_length(HOME_ARM))
	return at_home(nearest(art)) and art.distance_to(end) <= HOME_TAP_REACH and art.y <= end.y + HOME_TAP_BELOW


func nearby(spot: Dictionary) -> String:
	var best := ""
	var gap := NEAR
	for entry: Dictionary in STOPS:
		var distance := route_length(spot, entry)
		if distance <= gap:
			gap = distance
			best = entry.id
	return best


## 取景：足够大的视口完整展示原画；手机按固定缩放放大并随人物平移，不因停下看而变焦
func frame(foot: Vector2, viewport: Vector2) -> Dictionary:
	var size := Vector2(maxf(viewport.x, 1.0), maxf(viewport.y, 1.0))
	var fit := minf(size.x / SIZE.x, size.y / SIZE.y)
	var zoom := fit
	if minf(size.x, size.y) < FULL_VIEW_MIN:
		zoom = maxf(fit, minf(size.y / PHONE_VIEW_HEIGHT, size.x / PHONE_VIEW_WIDTH))
	var visible := size / zoom
	var center := Vector2(_axis(foot.x, visible.x, SIZE.x), _axis(foot.y - visible.y * 0.1, visible.y, SIZE.y))
	return {"zoom": zoom, "camera": center, "visible": visible}


func visible_rect(view: Dictionary) -> Rect2:
	var visible: Vector2 = view.visible
	return Rect2(Vector2(view.camera) - visible * 0.5, visible)


func _axis(center: float, visible: float, length: float) -> float:
	if visible >= length:
		return length * 0.5
	return clampf(center, visible * 0.5, length - visible * 0.5)
