class_name YardGround
extends RefCounted

# 画是透视的。画面越靠上越远，角色越小，屏幕上的一步也越短。
const FAR_Y := 420.0
const NEAR_Y := 650.0
const POND_CENTER := Vector2(705, 592)
const POND_RADIUS := Vector2(148, 52)


static func lawn() -> PackedVector2Array:
	# 屋子前面的小路、池塘上方的草坪，绕开水。
	return PackedVector2Array([
		Vector2(200, 525),
		Vector2(248, 458),
		Vector2(400, 432),
		Vector2(860, 418),
		Vector2(915, 468),
		Vector2(885, 548),
		Vector2(760, 538),
		Vector2(500, 548),
		Vector2(370, 590),
		Vector2(300, 648),
		Vector2(185, 600),
	])


static func pen_and_lawn() -> PackedVector2Array:
	# 羊圈连着通往草坪的缺口，羊可以自己走出来，再走回去。
	return PackedVector2Array([
		Vector2(480, 448),
		Vector2(860, 428),
		Vector2(1188, 455),
		Vector2(1210, 555),
		Vector2(980, 578),
		Vector2(860, 545),
		Vector2(500, 552),
	])


static func depth_at(y: float) -> float:
	var t := clampf((y - FAR_Y) / (NEAR_Y - FAR_Y), 0.0, 1.0)
	return lerpf(0.82, 1.18, t)


static func contains(poly: PackedVector2Array, point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, poly)


static func in_pond(point: Vector2) -> bool:
	return in_ellipse(point, POND_CENTER, POND_RADIUS)


static func in_ellipse(point: Vector2, center: Vector2, radius: Vector2) -> bool:
	if radius.x <= 0.0 or radius.y <= 0.0:
		return false
	var delta := point - center
	var nx := delta.x / radius.x
	var ny := delta.y / radius.y
	return nx * nx + ny * ny <= 1.0


static func allows(point: Vector2, poly: PackedVector2Array, avoid_pond: bool) -> bool:
	if poly.is_empty():
		return not (avoid_pond and in_pond(point))
	if not contains(poly, point):
		return false
	if avoid_pond and in_pond(point):
		return false
	return true


static func move_inside(current: Vector2, delta: Vector2, poly: PackedVector2Array, avoid_pond: bool) -> Vector2:
	var next := current + delta
	if allows(next, poly, avoid_pond):
		return next
	# 撞到水塘或篱笆外时，沿还能走的一边滑，不穿过去。
	var along_x := Vector2(next.x, current.y)
	if allows(along_x, poly, avoid_pond):
		return along_x
	var along_y := Vector2(current.x, next.y)
	if allows(along_y, poly, avoid_pond):
		return along_y
	return current


static func _clear_segment(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(a.distance_to(b) / 5.0))
	for i in range(steps + 1):
		if not allows(a.lerp(b, float(i) / steps), lawn(), true):
			return false
	return true


static func route(start: Vector2, goal: Vector2) -> Array[Vector2]:
	# Tiny visibility graph follows the concave lawn instead of pushing into its edge.
	if not allows(goal, lawn(), true):
		return []
	if _clear_segment(start, goal):
		return [goal]
	var nodes: Array[Vector2] = [start, goal]
	for corner in lawn():
		for offset in [Vector2(6,6),Vector2(-6,6),Vector2(6,-6),Vector2(-6,-6)]:
			if allows(corner+offset,lawn(),true):
				nodes.append(corner+offset)
	var distances: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	for i in nodes.size():
		distances.append(INF)
		previous.append(-1)
		visited.append(false)
	distances[0] = 0.0
	for iteration in nodes.size():
		var best := -1
		for i in nodes.size():
			if not visited[i] and (best == -1 or distances[i] < distances[best]):
				best = i
		if best == -1 or distances[best] == INF: break
		if best == 1: break
		visited[best] = true
		for i in nodes.size():
			if visited[i] or not _clear_segment(nodes[best],nodes[i]): continue
			var cost := distances[best] + nodes[best].distance_to(nodes[i])
			if cost < distances[i]:
				distances[i] = cost
				previous[i] = best
	if previous[1] == -1: return []
	var result: Array[Vector2] = []
	var index := 1
	while index > 0:
		result.push_front(nodes[index])
		index = previous[index]
	return result
