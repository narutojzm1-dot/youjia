extends Node2D
## REQ-20261008-075（Owner GROK-CONTRIBUTOR）：地上放下的草 / 小鱼 / 小米
## 原来没有落地影，在草地上像浮着的贴纸。脚下垫一圈静止柔和接触影
## （暖墨扁椭圆，随 YardGround.depth_at 远小近大），和院里动物 / 种植床 /
## 摆好小物的落地感一致。不改投放、拾起、取食逻辑与存档。
## 低动效相同：影子本来就不动画。

const INK := Color(0.16, 0.11, 0.07)
const OUTER_ALPHA := 0.16
const INNER_ALPHA := 0.20

var kind := "grass"
var depth := 1.0


## 道具本地坐标：扁椭圆半径（未乘 depth）。草略宽、小米略小、中鱼略长。
static func radii_for(food_kind: String) -> Vector2:
	match food_kind:
		"grass":
			return Vector2(14.0, 4.5)
		"millet":
			return Vector2(10.0, 3.5)
		"medium":
			return Vector2(13.0, 4.0)
		_:
			# small / odd fish 及其他
			return Vector2(11.0, 3.8)


func configure(food_kind: String, ground_depth: float) -> void:
	kind = food_kind
	depth = maxf(ground_depth, 0.01)
	queue_redraw()


func radii() -> Vector2:
	return radii_for(kind) * depth


func _draw() -> void:
	var r := radii()
	# 贴着落点略偏下：食物锚点在脚底附近。
	draw_set_transform(Vector2(0.0, 2.0), 0.0, r)
	draw_circle(Vector2.ZERO, 1.0, Color(INK, OUTER_ALPHA))
	draw_set_transform(Vector2(0.0, 1.2), 0.0, Vector2(r.x * 0.66, r.y * 0.6))
	draw_circle(Vector2.ZERO, 1.0, Color(INK, INNER_ALPHA))
	draw_set_transform(Vector2.ZERO)
