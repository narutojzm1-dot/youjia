class_name YardGateGround
extends RefCounted

# Feet, not sprite bounds. The doorway is the only connection through the fence.
const OUTSIDE := Vector2(914, 516)
const INSIDE := Vector2(914, 466)
const THRESHOLD := Rect2(899, 482, 31, 23)

static var _outside := PackedVector2Array()
static var _connected := PackedVector2Array()

static func outside() -> PackedVector2Array:
	if not _outside.is_empty(): return _outside
	var shape := YardGround.lawn()
	var approach := PackedVector2Array([Vector2(835,510), Vector2(895,492),
		Vector2(931,492), Vector2(931,534), Vector2(895,548)])
	_outside = Geometry2D.merge_polygons(shape, approach)[0]
	return _outside

static func inside() -> PackedVector2Array:
	return PackedVector2Array([Vector2(902,472), Vector2(924,432),
		Vector2(1050,432), Vector2(1120,470), Vector2(1100,499),
		Vector2(948,474), Vector2(927,479), Vector2(927,482), Vector2(902,482)])

static func connected() -> PackedVector2Array:
	if not _connected.is_empty(): return _connected
	var doorway := PackedVector2Array([Vector2(902,474),Vector2(927,474),
		Vector2(927,521),Vector2(902,521)])
	var path: PackedVector2Array = Geometry2D.merge_polygons(outside(), doorway)[0]
	_connected = Geometry2D.merge_polygons(path, inside())[0]
	return _connected

static func for_body(open: bool, feet: Vector2) -> PackedVector2Array:
	if open: return connected()
	return inside() if YardGround.contains(inside(), feet) else outside()
