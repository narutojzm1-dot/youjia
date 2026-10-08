extends Node2D
## Reuse the original painted wood as foreground; only the door opening uses
## a clean plate. No full-scene replacement or image-size dependent positions.
const SUNNY := preload("res://assets/holiday/environment/yard_sunny.png")
const OVERCAST := preload("res://assets/holiday/environment/yard_overcast_aligned.png")
const CLEAN := preload("res://assets/holiday/environment/yard_gate_clean.png")
var patch: Polygon2D
var leaves: Array[Array] = []
var woods: Array[Array] = []
var record: Dictionary = {}

func _ready() -> void: build()

func build() -> void:
	if patch != null: return
	patch = polygon([Vector2(889,439),Vector2(933,443),Vector2(934,502),Vector2(889,493)], CLEAN, 1)
	# Gate leaf frame and diagonal braces, sampled from the original painting.
	for points: Array in [
		[Vector2(891,439),Vector2(929,443),Vector2(929,449),Vector2(891,445)],
		[Vector2(891,480),Vector2(929,490),Vector2(929,495),Vector2(891,487)],
		[Vector2(891,442),Vector2(896,443),Vector2(896,487),Vector2(891,485)],
		[Vector2(925,447),Vector2(930,447),Vector2(930,494),Vector2(925,491)],
		[Vector2(892,446),Vector2(896,444),Vector2(928,486),Vector2(925,490)],
		[Vector2(893,482),Vector2(925,446),Vector2(929,450),Vector2(897,488)],
	]:
		leaves.append([polygon(points, SUNNY, 500), polygon(points, OVERCAST, 500)])
	# Front rails and posts. Transparent gaps stay gaps, so feet remain visible.
	for points: Array in [
		[Vector2(945,447),Vector2(1125,465),Vector2(1125,474),Vector2(945,456)],
		[Vector2(945,469),Vector2(1125,490),Vector2(1125,501),Vector2(945,480)],
		[Vector2(945,491),Vector2(1044,511),Vector2(1044,521),Vector2(945,502)],
		[Vector2(878,405),Vector2(891,402),Vector2(889,499),Vector2(877,494)],
		[Vector2(930,442),Vector2(945,442),Vector2(945,512),Vector2(930,506)],
		[Vector2(1044,425),Vector2(1060,427),Vector2(1057,534),Vector2(1043,530)],
		[Vector2(1098,434),Vector2(1113,431),Vector2(1110,509),Vector2(1098,509)],
	]:
		var depth: int = [525,525,525,499,512,534,509][woods.size()]
		woods.append([polygon(points, SUNNY, depth), polygon(points, OVERCAST, depth)])

func polygon(points: Array, texture: Texture2D, depth: int) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = PackedVector2Array(points)
	node.texture = texture
	var uv := PackedVector2Array()
	for point: Vector2 in points: uv.append(point * texture.get_size() / Vector2(1280,720))
	node.uv = uv
	node.z_index = depth
	add_child(node)
	return node

func refresh(opened: bool, mix: float, sunny_tint: Color, cloudy_tint: Color) -> void:
	build()
	record = {"opened":opened,"mix":mix,"sun":[sunny_tint.r,sunny_tint.g,sunny_tint.b,sunny_tint.a],"cloud":[cloudy_tint.r,cloudy_tint.g,cloudy_tint.b,cloudy_tint.a]}
	patch.visible = opened
	patch.modulate = sunny_tint.lerp(Color(0.82,0.85,0.87) * cloudy_tint, mix)
	for pair: Array in leaves:
		for leaf: Polygon2D in pair:
			leaf.transform = Transform2D(Vector2(0.27,-0.30), Vector2(0,1), Vector2(889*0.73,889*0.30)) if opened else Transform2D.IDENTITY
		pair[0].modulate = sunny_tint
		pair[1].modulate = Color(cloudy_tint.r, cloudy_tint.g, cloudy_tint.b, mix)
	for pair: Array in woods:
		pair[0].modulate = sunny_tint
		pair[1].modulate = Color(cloudy_tint.r, cloudy_tint.g, cloudy_tint.b, mix)
