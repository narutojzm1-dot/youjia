class_name NearPathLayout
extends RefCounted
# 院外近郊原画（02_near_path，1672×941）上的可走路与取景（纯数据 + 纯函数）。
# 坐标就是原画像素；道路内可自由走动，不横穿溪水或纸边。
# 路线取自制作人候选 art/concepts/producer_world_20261005/near_path_anchors.candidate.json
# 原lane保留；2026-10-07用户授权开放画中北向支路及道路宽度。
# 停留点沿用已发布契约；道路宽度和远景比例由Leader按实景校准。

const ART := "res://assets/holiday/exploration/near_path_02.webp"
const SIZE := Vector2(1672, 941)
# 两条路共享前景段；有宽度的路面寻路在实际分叉处转向，无需退回前景。
const JUNCTION := Vector2(740, 845)
const ARMS := {
	"lane": [JUNCTION, Vector2(850, 811), Vector2(945, 769), Vector2(1030, 729), Vector2(1110, 690), Vector2(1150, 660), Vector2(1220, 630), Vector2(1305, 599), Vector2(1360, 565)],
	"north": [JUNCTION, Vector2(850, 811), Vector2(945, 769), Vector2(1030, 729), Vector2(1110, 690), Vector2(1110, 637), Vector2(1010, 610), Vector2(910, 590), Vector2(810, 576), Vector2(775, 575)],
}
const WALK_WIDTHS := {
	"lane": [65.0, 58.0, 52.0, 48.0, 42.0, 36.0, 30.0, 24.0, 18.0],
	"north": [65.0, 58.0, 52.0, 48.0, 42.0, 30.0, 24.0, 19.0, 14.0, 10.0],
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
const DEPTH_FAR_Y := 530.0
const DEPTH_NEAR := 1.35
const DEPTH_FAR := 0.45
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


static var _geometry: PaintedPath

static func geometry() -> PaintedPath:
	if _geometry == null:
		_geometry = PaintedPath.new({
			"ART": ART,
			"SIZE": SIZE,
			"JUNCTION": JUNCTION,
			"ARMS": ARMS,
			"WALK_WIDTHS": WALK_WIDTHS,
			"HOME_ARM": HOME_ARM,
			"START": START,
			"WALK_SPEED": WALK_SPEED,
			"NEAR": NEAR,
			"HOME_HOLD": HOME_HOLD,
			"MIN_ALIGN": MIN_ALIGN,
			"HOME_TAP_REACH": HOME_TAP_REACH,
			"HOME_TAP_BELOW": HOME_TAP_BELOW,
			"DEPTH_NEAR_Y": DEPTH_NEAR_Y,
			"DEPTH_FAR_Y": DEPTH_FAR_Y,
			"DEPTH_NEAR": DEPTH_NEAR,
			"DEPTH_FAR": DEPTH_FAR,
			"WALKER_BOX": WALKER_BOX,
			"FULL_VIEW_MIN": FULL_VIEW_MIN,
			"PHONE_VIEW_HEIGHT": PHONE_VIEW_HEIGHT,
			"PHONE_VIEW_WIDTH": PHONE_VIEW_WIDTH,
			"STOPS": STOPS,
		})
	return _geometry

static func stop(stop_id: String) -> Dictionary:
	return geometry().stop(stop_id)

static func arm_length(arm: String) -> float:
	return geometry().arm_length(arm)

static func point(arm: String, d: float) -> Vector2:
	return geometry().point(arm, d)

static func tangent(arm: String, d: float) -> Vector2:
	return geometry().tangent(arm, d)

static func heading(arm: String) -> Vector2:
	return geometry().heading(arm)

static func depth(y: float) -> float:
	return geometry().depth(y)

static func nearest(target: Vector2) -> Dictionary:
	return geometry().nearest(target)

static func step_toward(from: Dictionary, to: Dictionary, distance: float) -> Dictionary:
	return geometry().step_toward(from, to, distance)

static func route_length(from: Dictionary, to: Dictionary) -> float:
	return geometry().route_length(from, to)

static func step_input(from: Dictionary, direction: Vector2, distance: float) -> Dictionary:
	return geometry().step_input(from, direction, distance)

static func at_home(spot: Dictionary) -> bool:
	return geometry().at_home(spot)

static func home_direction() -> Vector2:
	return geometry().home_direction()

static func is_home_tap(art: Vector2) -> bool:
	return geometry().is_home_tap(art)

static func nearby(spot: Dictionary) -> String:
	return geometry().nearby(spot)

static func frame(foot: Vector2, viewport: Vector2) -> Dictionary:
	return geometry().frame(foot, viewport)

static func visible_rect(view: Dictionary) -> Rect2:
	return geometry().visible_rect(view)

static func _axis(center: float, visible: float, length: float) -> float:
	return geometry()._axis(center, visible, length)
