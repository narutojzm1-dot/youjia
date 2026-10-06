class_name NearPathLayout
extends RefCounted
# 院外近郊原画（02_near_path，1672×941）上的可走路与取景（纯数据 + 纯函数）。
# 坐标就是原画像素；人物脚点只落在折线上，不横穿花丛、溪水或纸边。
# 路线取自制作人候选 art/concepts/producer_world_20261005/near_path_anchors.candidate.json
# （gate_to_foreground_candidate，折线、双向、前景终点不是出口）；左上小路与木桥未交付连接，不走。
# 停留点、物件锚点、透视比例是 Cloud 按画面校准的实验参数，制作人尚未给出，不是用户批准的规格。

const ART := "res://assets/holiday/exploration/near_path_02.webp"
const SIZE := Vector2(1672, 941)
# 路从岔口出发；以后接相邻页时在这里加路。现在只有一条：从前景终点到院门台阶下
const JUNCTION := Vector2(740, 845)
const ARMS := {
	"lane": [JUNCTION, Vector2(850, 811), Vector2(945, 769), Vector2(1030, 729), Vector2(1110, 690), Vector2(1150, 660), Vector2(1220, 630), Vector2(1305, 599), Vector2(1360, 565)],
}
# 走到这条路的尽头再往前就是回院
const HOME_ARM := "lane"
const START := {"arm": "lane", "d": 663.0}
const WALK_SPEED := 85.0
# 停留点“附近”：只用来提示可以停下看，经过不计任何东西
const NEAR := 55.0
# 走到院门口还往院里走这么久，就当作走回院子
const HOME_HOLD := 0.45
# 点按回院的院门一带（原画像素，实验值）：离路尽头不超过这么远，且不低于路尽头这么多
const HOME_TAP_REACH := 260.0
const HOME_TAP_BELOW := 30.0
# 方向与路的夹角太大时不走，免得按“上”在横路上乱滑
const MIN_ALIGN := 0.3
# 脚点 y → 人物比例：远（院门）小、近（画面下沿）大
const DEPTH_NEAR_Y := 845.0
const DEPTH_FAR_Y := 565.0
const DEPTH_NEAR := 1.35
const DEPTH_FAR := 0.75
const WALKER_BOX := Rect2(-24, -108, 48, 108)
# 桌面完整构图的最小视口短边（实验值）；更小（手机或很小的桌面窗口）时放大并随人物平移，缩放固定不变
const FULL_VIEW_MIN := 600.0
const PHONE_VIEW_HEIGHT := 640.0
const PHONE_VIEW_WIDTH := 420.0

const STOPS := [
	{"id": "gate", "arm": "lane", "d": 590.0, "item": Vector2(1240, 668)},
	{"id": "brook", "arm": "lane", "d": 195.0, "item": Vector2(880, 752)},
	{"id": "shade", "arm": "lane", "d": 365.0, "item": Vector2(1000, 688)},
	{"id": "slope", "arm": "lane", "d": 25.0, "item": Vector2(800, 872)},
	{"id": "leaf_pile", "arm": "lane", "d": 480.0, "item": Vector2(1214, 638)},
]


static func stop(stop_id: String) -> Dictionary:
	for entry: Dictionary in STOPS:
		if entry.id == stop_id:
			return entry
	return {}


static func arm_length(arm: String) -> float:
	var points: Array = ARMS[arm]
	var total := 0.0
	for i in range(1, points.size()):
		total += (points[i] as Vector2).distance_to(points[i - 1])
	return total


static func point(arm: String, d: float) -> Vector2:
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
static func tangent(arm: String, d: float) -> Vector2:
	var length := arm_length(arm)
	var a := point(arm, clampf(d - 2.0, 0.0, length))
	var b := point(arm, clampf(d + 2.0, 0.0, length))
	return (b - a).normalized() if a.distance_to(b) > 0.01 else (point(arm, 4.0) - JUNCTION).normalized()


## 整条路从岔口到尽头的大方向
static func heading(arm: String) -> Vector2:
	var points: Array = ARMS[arm]
	return ((points[-1] as Vector2) - JUNCTION).normalized()


static func depth(y: float) -> float:
	return lerpf(DEPTH_FAR, DEPTH_NEAR, clampf((y - DEPTH_FAR_Y) / (DEPTH_NEAR_Y - DEPTH_FAR_Y), 0.0, 1.0))


## 画面上任意一点最近的路上位置
static func nearest(target: Vector2) -> Dictionary:
	var best := {"arm": HOME_ARM, "d": 0.0, "gap": INF}
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
static func step_toward(from: Dictionary, to: Dictionary, distance: float) -> Dictionary:
	var arm: String = from.arm
	var d: float = from.d
	if arm == to.arm or d <= 0.01:
		if arm != to.arm:
			arm = to.arm
			d = 0.0
		var goal: float = to.d
		return {"arm": arm, "d": move_toward(d, goal, distance)}
	return {"arm": arm, "d": maxf(d - distance, 0.0)}


static func route_length(from: Dictionary, to: Dictionary) -> float:
	if from.arm == to.arm:
		return absf(float(from.d) - float(to.d))
	return float(from.d) + float(to.d)


## 方向键：沿当前路的投影走；在岔口选与方向最顺的那条路
static func step_input(from: Dictionary, direction: Vector2, distance: float) -> Dictionary:
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


static func at_home(spot: Dictionary) -> bool:
	return spot.arm == HOME_ARM and float(spot.d) >= arm_length(HOME_ARM) - 0.5


static func home_direction() -> Vector2:
	return tangent(HOME_ARM, arm_length(HOME_ARM))


## 点在院门一带（路尽头上方、不太远）才算点了回院；路尽头右下的石头、草地只走过去
static func is_home_tap(art: Vector2) -> bool:
	var end := point(HOME_ARM, arm_length(HOME_ARM))
	return at_home(nearest(art)) and art.distance_to(end) <= HOME_TAP_REACH and art.y <= end.y + HOME_TAP_BELOW


static func nearby(spot: Dictionary) -> String:
	var best := ""
	var gap := NEAR
	for entry: Dictionary in STOPS:
		var distance := route_length(spot, entry)
		if distance <= gap:
			gap = distance
			best = entry.id
	return best


## 取景：足够大的视口完整展示原画；手机按固定缩放放大并随人物平移，不因停下看而变焦
static func frame(foot: Vector2, viewport: Vector2) -> Dictionary:
	var size := Vector2(maxf(viewport.x, 1.0), maxf(viewport.y, 1.0))
	var fit := minf(size.x / SIZE.x, size.y / SIZE.y)
	var zoom := fit
	if minf(size.x, size.y) < FULL_VIEW_MIN:
		zoom = maxf(fit, minf(size.y / PHONE_VIEW_HEIGHT, size.x / PHONE_VIEW_WIDTH))
	var visible := size / zoom
	var center := Vector2(_axis(foot.x, visible.x, SIZE.x), _axis(foot.y - visible.y * 0.1, visible.y, SIZE.y))
	return {"zoom": zoom, "camera": center, "visible": visible}


static func visible_rect(view: Dictionary) -> Rect2:
	var visible: Vector2 = view.visible
	return Rect2(Vector2(view.camera) - visible * 0.5, visible)


static func _axis(center: float, visible: float, length: float) -> float:
	if visible >= length:
		return length * 0.5
	return clampf(center, visible * 0.5, length - visible * 0.5)
