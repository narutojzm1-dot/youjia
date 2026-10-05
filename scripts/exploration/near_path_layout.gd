class_name NearPathLayout
extends RefCounted
# 近郊小路画卷的几何与取景（纯数据 + 纯函数）。数值是首片实验参数，不是正式构图规格；
# 正式画面交付后只需替换这里的停留点位置、小景框与物件锚点。

const SIZE := Vector2(3600, 720)
const GROUND_Y := 560.0
const WALK_MIN := 150.0
const WALK_MAX := 3450.0
const START_X := 230.0
const WALK_SPEED := 110.0
# 停留点“附近”：只用来提示可以停下看，经过不计任何东西
const NEAR := 110.0
# 回到画卷起点再往回走这么久，就当作走回院子
const HOME_HOLD := 0.45
const FIT_MARGIN := 20.0
const WALKER_BOX := Rect2(-24, -108, 48, 108)

const STOPS := [
	{"id": "gate", "x": 470.0, "scene": Rect2(210, 250, 520, 360), "item": Vector2.ZERO},
	{"id": "brook", "x": 1260.0, "scene": Rect2(1000, 270, 520, 340), "item": Vector2(1338, 574)},
	{"id": "shade", "x": 2160.0, "scene": Rect2(1900, 200, 520, 410), "item": Vector2(2236, 576)},
	{"id": "slope", "x": 3060.0, "scene": Rect2(2800, 230, 520, 380), "item": Vector2.ZERO},
]


static func stop(stop_id: String) -> Dictionary:
	for entry: Dictionary in STOPS:
		if entry.id == stop_id:
			return entry
	return {}


static func nearby(x: float) -> String:
	var best := ""
	var gap := NEAR
	for entry: Dictionary in STOPS:
		var distance := absf(float(entry.x) - x)
		if distance <= gap:
			gap = distance
			best = entry.id
	return best


## 行走时跟随：按高度铺满，太宽时按长度铺满；相机窗口始终在画卷内
static func follow(x: float, viewport: Vector2) -> Dictionary:
	var size := Vector2(maxf(viewport.x, 1.0), maxf(viewport.y, 1.0))
	var zoom := size.y / SIZE.y
	if size.x / zoom > SIZE.x:
		zoom = size.x / SIZE.x
	var visible := size / zoom
	return {"zoom": zoom, "camera": Vector2(_axis(x, visible.x, SIZE.x), _axis(GROUND_Y - visible.y * 0.15, visible.y, SIZE.y)), "visible": visible}


## 停下看时收景：整处小景一次入画，不比跟随更近；竖屏上下露出纸边
static func fit(x: float, viewport: Vector2, stop_id: String) -> Dictionary:
	var entry := stop(stop_id)
	if entry.is_empty():
		return follow(x, viewport)
	var scene: Rect2 = entry.scene
	var size := Vector2(maxf(viewport.x, 1.0), maxf(viewport.y, 1.0))
	var base: float = follow(x, size).zoom
	var padded := scene.size + Vector2.ONE * FIT_MARGIN * 2.0
	var zoom := minf(base, minf(size.x / padded.x, size.y / padded.y))
	var visible := size / zoom
	var center := scene.get_center()
	return {"zoom": zoom, "camera": Vector2(_axis(center.x, visible.x, SIZE.x), _axis(center.y, visible.y, SIZE.y)), "visible": visible}


static func visible_rect(view: Dictionary) -> Rect2:
	var visible: Vector2 = view.visible
	return Rect2(Vector2(view.camera) - visible * 0.5, visible)


static func coverage(view: Dictionary, rect: Rect2) -> float:
	if rect.get_area() <= 0.0:
		return 0.0
	return visible_rect(view).intersection(rect).get_area() / rect.get_area()


static func _axis(center: float, visible: float, length: float) -> float:
	if visible >= length:
		return length * 0.5
	return clampf(center, visible * 0.5, length - visible * 0.5)
