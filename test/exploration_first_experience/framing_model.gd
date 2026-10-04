extends RefCounted
# 停下看景的取景候选（#201，实验参数，未冻结）：比较「跟随角色」与「停下后收进整处小景」两种方案。
# 只算相机缩放与中心，不碰输入、核心或存档；小景矩形是占位几何的包围框，不代表正式构图或资源规格。

const ScrollWalkModel := preload("res://test/exploration_scroll_prototype/scroll_walk_model.gd")

const MODE_FOLLOW := "follow"
const MODE_FIT := "observe_fit"
## 小景四周留白（世界单位），让主体不贴画面边
const FIT_MARGIN := 20.0

## 每个占位停留点的「一处小景」：主体占位形 + 角色可停的范围（停留点 ±NEAR_DISTANCE）+ 一点前后景
## 竖向从树冠顶到路面下沿；文字标签不算景物
const SCENES := {
	"placeholder_a": Rect2(640.0, 280.0, 520.0, 320.0),
	"placeholder_b": Rect2(1940.0, 280.0, 520.0, 320.0),
	"placeholder_c": Rect2(3340.0, 280.0, 520.0, 320.0),
}
## 角色占位的包围框（相对脚底）：用于判断停下后角色是否也在画面里
const WALKER_BOX := Rect2(-22.0, -96.0, 44.0, 96.0)


static func scene_rect(stop_id: String) -> Rect2:
	return SCENES.get(stop_id, Rect2())


## 跟随方案：沿用 #199 原型取景（按高度铺满，相机跟着角色）
static func follow(model, viewport: Vector2) -> Dictionary:
	return model.view(viewport)


## 收景方案：以小景为中心，缩到能装下整处小景；不比跟随更近，所以横屏下与跟随同一缩放
## 竖屏时画面上下会露出画卷以外的装裱底色（纸边），这是本方案的已知代价
static func fit(model, viewport: Vector2, stop_id: String) -> Dictionary:
	var scene := scene_rect(stop_id)
	if scene.size == Vector2.ZERO:
		return follow(model, viewport)
	var size := Vector2(maxf(viewport.x, 1.0), maxf(viewport.y, 1.0))
	var base: float = follow(model, size)["zoom"]
	var padded := scene.size + Vector2.ONE * FIT_MARGIN * 2.0
	var zoom := minf(base, minf(size.x / padded.x, size.y / padded.y))
	var visible := size / zoom
	var center := scene.get_center()
	return {"zoom": zoom, "camera": Vector2(_axis(center.x, visible.x, ScrollWalkModel.SCROLL_LENGTH), _axis(center.y, visible.y, ScrollWalkModel.SCROLL_HEIGHT)), "visible": visible}


static func frame(mode: String, model, viewport: Vector2, stop_id: String) -> Dictionary:
	if mode == MODE_FIT and not stop_id.is_empty():
		return fit(model, viewport, stop_id)
	return follow(model, viewport)


## 画面能看到的世界矩形
static func visible_rect(view: Dictionary) -> Rect2:
	var visible: Vector2 = view["visible"]
	return Rect2(Vector2(view["camera"]) - visible * 0.5, visible)


## 小景落在画面里的面积比例（0–1）：停稳后无需再挪动就能看全时为 1
static func coverage(view: Dictionary, rect: Rect2) -> float:
	if rect.get_area() <= 0.0:
		return 0.0
	return visible_rect(view).intersection(rect).get_area() / rect.get_area()


static func walker_visible(view: Dictionary, walker_x: float) -> bool:
	var box := Rect2(WALKER_BOX.position + Vector2(walker_x, ScrollWalkModel.GROUND_Y), WALKER_BOX.size)
	return visible_rect(view).encloses(box)


## 画面里画卷以外（纸边）所占的比例，用来量化收景方案在竖屏下的代价
static func margin_ratio(view: Dictionary) -> float:
	var shown := visible_rect(view)
	var paper := Rect2(0.0, 0.0, ScrollWalkModel.SCROLL_LENGTH, ScrollWalkModel.SCROLL_HEIGHT)
	return 1.0 - shown.intersection(paper).get_area() / shown.get_area()


## 一个方向上的相机中心：画面比画卷窄时夹在画卷内，比画卷宽时居中
static func _axis(center: float, visible: float, length: float) -> float:
	if visible >= length:
		return length * 0.5
	return clampf(center, visible * 0.5, length - visible * 0.5)
