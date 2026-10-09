class_name YardBodies
extends RefCounted

# Footprints live on the ground plane. Overlapping silhouettes are valid only
# when their feet are separated and the common y-depth order occludes them.
const CELL := 12.0

static func radius_for(species: String) -> Vector2:
	return {"player":Vector2(10,6), "llama":Vector2(24,11), "cow":Vector2(36,13), "horse":Vector2(36,13), "sheep":Vector2(23,10), "goose":Vector2(14,8), "duck":Vector2(10,5)}.get(species, Vector2(16,8))

static func clear_at(point: Vector2, radius: Vector2, obstacles: Array) -> bool:
	for item: Dictionary in obstacles:
		var extent: Vector2 = radius + item.radius
		var relative: Vector2 = (point - item.position) / extent
		if relative.length_squared() < 0.9999: return false
	return true

static func hit_fraction(start: Vector2, step: Vector2, radius: Vector2, item: Dictionary) -> float:
	var extent: Vector2 = radius + item.radius
	var p: Vector2 = (start - item.position) / extent
	var v: Vector2 = step / extent
	var a := v.length_squared()
	if a < 0.00000001: return INF
	var b := 2.0 * p.dot(v)
	var c := p.length_squared() - 1.0
	# Never trap a body that starts at contact and is moving away.
	if c < 0.001 and b >= 0.0: return INF
	var discriminant := b*b - 4.0*a*c
	if discriminant < 0.0: return INF
	var t := (-b - sqrt(discriminant))/(2.0*a)
	if c < 0.0 and b < 0.0: return 0.0
	return t if t >= 0.0 and t <= 1.0 else INF

static func clear_segment(a: Vector2, b: Vector2, radius: Vector2, obstacles: Array) -> bool:
	for item: Dictionary in obstacles:
		if hit_fraction(a, b-a, radius, item) != INF: return false
	return true

static func move_inside(start: Vector2, step: Vector2, radius: Vector2, obstacles: Array, ground: PackedVector2Array, avoid_pond: bool) -> Vector2:
	var point := start
	var remaining := step
	for iteration in 3:
		var hit := 1.0
		var blocker: Dictionary = {}
		for item: Dictionary in obstacles:
			var fraction := hit_fraction(point, remaining, radius, item)
			if fraction < hit:
				hit = fraction
				blocker = item
		var next := point + remaining * maxf(0.0, hit - (0.002 if not blocker.is_empty() else 0.0))
		point = YardGround.move_inside(point, next-point, ground, avoid_pond)
		if blocker.is_empty(): break
		var extent: Vector2 = radius + blocker.radius
		var normal: Vector2 = ((point-blocker.position)/(extent*extent)).normalized()
		remaining *= 1.0-hit
		remaining -= normal * minf(0.0, remaining.dot(normal))
		if remaining.length_squared() < 0.000001: break
	return point

static func _ground_segment(a: Vector2, b: Vector2, ground: PackedVector2Array, avoid_pond: bool) -> bool:
	# Five-pixel probes can skip a very narrow concave fence corner. Split at
	# every polygon intersection and check each open interval before smoothing.
	var axis := b - a
	if axis.length_squared() > 0.000001:
		var cuts: Array[float] = [0.0, 1.0]
		for edge: int in ground.size():
			var crossing: Variant = Geometry2D.segment_intersects_segment(a, b, ground[edge], ground[(edge + 1) % ground.size()])
			if crossing != null:
				cuts.append(clampf((crossing - a).dot(axis) / axis.length_squared(), 0.0, 1.0))
		cuts.sort()
		for index: int in range(1, cuts.size()):
			if cuts[index] - cuts[index - 1] > 0.000001 and not YardGround.allows(a.lerp(b, (cuts[index] + cuts[index - 1]) * 0.5), ground, avoid_pond): return false
	var count := maxi(1, ceili(a.distance_to(b)/5.0))
	for i in range(count+1):
		if not YardGround.allows(a.lerp(b,float(i)/count),ground,avoid_pond): return false
	return true

static func route(start: Vector2, goal: Vector2, radius: Vector2, obstacles: Array, ground: PackedVector2Array, avoid_pond: bool = true) -> Array[Vector2]:
	if not YardGround.allows(goal,ground,avoid_pond) or not clear_at(goal,radius,obstacles): return []
	if clear_segment(start,goal,radius,obstacles) and _ground_segment(start,goal,ground,avoid_pond): return [goal]
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(14,33,65,23)
	# Preserve the established lawn grid; extend east only for pen routes.
	for corner: Vector2 in ground:
		grid.region = grid.region.expand(Vector2i(ceili(corner.x/CELL), ceili(corner.y/CELL)))
	grid.cell_size = Vector2.ONE*CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var start_cell := Vector2i.ZERO
	var goal_cell := Vector2i.ZERO
	var start_distance := INF
	var goal_distance := INF
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var cell := Vector2i(x,y)
			var point := Vector2(cell)*CELL
			var open := YardGround.allows(point,ground,avoid_pond) and clear_at(point,radius+Vector2(2,2),obstacles)
			grid.set_point_solid(cell, not open)
			if not open: continue
			var ds := point.distance_squared_to(start)
			if ds < start_distance and clear_segment(start,point,radius,obstacles) and _ground_segment(start,point,ground,avoid_pond):
				start_cell = cell
				start_distance = ds
			var dg := point.distance_squared_to(goal)
			if dg < goal_distance and clear_segment(point,goal,radius,obstacles) and _ground_segment(point,goal,ground,avoid_pond):
				goal_cell = cell
				goal_distance = dg
	if start_distance == INF or goal_distance == INF: return []
	var raw := grid.get_point_path(start_cell,goal_cell)
	if raw.is_empty(): return []
	raw.append(goal)
	var result: Array[Vector2] = []
	var from := start
	var index := 0
	while index < raw.size():
		var furthest := index
		for candidate in range(index,raw.size()):
			if clear_segment(from,raw[candidate],radius,obstacles) and _ground_segment(from,raw[candidate],ground,avoid_pond): furthest = candidate
			else: break
		if from.distance_to(raw[furthest]) > 1.0:
			result.append(raw[furthest])
		from = raw[furthest]
		index = furthest+1
	if result.is_empty() or result[-1].distance_to(goal)>1.0: result.append(goal)
	return result
