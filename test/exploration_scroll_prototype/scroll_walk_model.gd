extends RefCounted
# 画卷漫步的候选 view-model（candidate，未冻结）：只管横向位置、朝向和相机取景。
# 不知道存档、旅程或核心状态；数值全部是实验参数，不代表正式步速或路线长度。

## 画卷世界尺寸（世界单位，缩放 1 时等于像素）
const SCROLL_LENGTH := 4800.0
const SCROLL_HEIGHT := 720.0
## 可走区：离两端各留一段，角色不贴边
const WALK_MARGIN := 140.0
## 地面所在高度：竖屏裁切时取景围绕它，保证角色与路面在画面内
const GROUND_Y := 560.0
## 实验步速（世界单位 / 秒）
const WALK_SPEED := 160.0
## 停留点“在附近”的距离，只用来提示可以停下看，不计任何进度
const NEAR_DISTANCE := 110.0

## 实验占位停留点：x 位置与占位名，不代表正式地点或带回物
const STOPS := [
	{"id": "placeholder_a", "x": 900.0, "label": "占位停留点 A"},
	{"id": "placeholder_b", "x": 2200.0, "label": "占位停留点 B"},
	{"id": "placeholder_c", "x": 3600.0, "label": "占位停留点 C"},
]

var x := WALK_MARGIN + 260.0
var facing := 1
var direction := 0


func walk_min() -> float:
	return WALK_MARGIN


func walk_max() -> float:
	return SCROLL_LENGTH - WALK_MARGIN


## 方向只取 -1 / 0 / 1；0 表示停下，停下后不会自行移动
func set_direction(value: int) -> void:
	direction = signi(value)
	if direction != 0:
		facing = direction


func step(delta: float) -> void:
	if direction == 0 or delta <= 0.0:
		return
	x = clampf(x + direction * WALK_SPEED * delta, walk_min(), walk_max())


func is_walking() -> bool:
	if direction == 0:
		return false
	if direction < 0:
		return x > walk_min()
	return x < walk_max()


## 按视口尺寸计算取景：先按高度铺满，太宽时改按长度铺满；
## 相机窗口始终落在画卷内，因此两端和上下都不露空白
func view(viewport: Vector2) -> Dictionary:
	var size := Vector2(maxf(viewport.x, 1.0), maxf(viewport.y, 1.0))
	var zoom := size.y / SCROLL_HEIGHT
	if size.x / zoom > SCROLL_LENGTH:
		zoom = size.x / SCROLL_LENGTH
	var visible := size / zoom
	var half := visible * 0.5
	var camera := Vector2(
		clampf(x, half.x, SCROLL_LENGTH - half.x),
		clampf(GROUND_Y - visible.y * 0.15, half.y, SCROLL_HEIGHT - half.y),
	)
	return {"zoom": zoom, "camera": camera, "visible": visible}


func nearby_stop() -> Dictionary:
	for stop: Dictionary in STOPS:
		if absf(float(stop["x"]) - x) <= NEAR_DISTANCE:
			return stop
	return {}
