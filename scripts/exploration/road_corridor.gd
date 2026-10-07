extends RefCounted
## Walkable painted road widths, with a small visibility graph for tap walking.
## All coordinates are original painting pixels; no world/save state lives here.
var segments: Array[Dictionary] = []
var nodes: Array[Vector2] = []
var edges: Array[Dictionary] = []

func configure(arms: Dictionary, widths: Dictionary) -> void:
	for arm: String in arms:
		var points: Array = arms[arm]
		var radii: Array = widths[arm]
		for i in range(points.size()):
			if not nodes.has(points[i]): nodes.append(points[i])
			if i > 0:
				segments.append({"a": points[i - 1], "b": points[i], "ra": radii[i - 1], "rb": radii[i]})
	for i in nodes.size():
		var links := {}
		for j in nodes.size():
			if i != j and clear_line(nodes[i], nodes[j]): links[j] = nodes[i].distance_to(nodes[j])
		edges.append(links)

func project(point: Vector2, inset := 0.0) -> Vector2:
	var best := Vector2.ZERO
	var gap := INF
	for s: Dictionary in segments:
		var axis: Vector2 = s.b - s.a
		var t := clampf((point - Vector2(s.a)).dot(axis) / axis.length_squared(), 0.0, 1.0)
		var center: Vector2 = Vector2(s.a).lerp(s.b, t)
		var radius := maxf(1.0, lerpf(s.ra, s.rb, t) - inset)
		var candidate := center + (point - center).limit_length(radius)
		var distance := candidate.distance_squared_to(point)
		if distance < gap:
			gap = distance
			best = candidate
	return best

func contains(point: Vector2) -> bool:
	return project(point).distance_squared_to(point) < 0.01

func clear_line(a: Vector2, b: Vector2) -> bool:
	var count := maxi(1, ceili(a.distance_to(b) / 6.0))
	for i in count + 1:
		var sample := a.lerp(b, float(i) / count)
		# Keep automatic shortcuts inside bends. A tangent sampled only at its
		# ends can clip the concave fork and repeatedly project back to one edge.
		var inset := 2.0 if i > 1 and i < count - 1 else 0.0
		if project(sample, inset).distance_squared_to(sample) >= 0.01: return false
	return true

func move_input(from: Vector2, direction: Vector2, distance: float) -> Vector2:
	var result := from
	var remaining := maxf(distance, 0.0)
	while remaining > 0.001:
		var step := minf(remaining, 6.0)
		var wanted := result + direction.limit_length(1.0) * step
		var next := project(wanted)
		if result.distance_to(next) <= step + 0.1 and clear_line(result, next): result = next
		remaining -= step
	return result

func path(from: Vector2, to: Vector2) -> Array[Vector2]:
	var a := project(from)
	var b := project(to)
	if clear_line(a, b): return [a, b]
	var costs := {}
	var previous := {}
	var open: Array[int] = []
	for i in nodes.size():
		if clear_line(a, nodes[i]):
			costs[i] = a.distance_to(nodes[i])
			previous[i] = -1
			open.append(i)
	var best := -1
	var best_cost := INF
	while not open.is_empty():
		var current := open[0]
		for i: int in open:
			if float(costs[i]) < float(costs[current]): current = i
		open.erase(current)
		if float(costs[current]) >= best_cost: continue
		if clear_line(nodes[current], b):
			var total: float = costs[current] + nodes[current].distance_to(b)
			if total < best_cost:
				best = current
				best_cost = total
		for next: int in edges[current]:
			var candidate: float = costs[current] + edges[current][next]
			if candidate < float(costs.get(next, INF)):
				costs[next] = candidate
				previous[next] = current
				if not open.has(next): open.append(next)
	if best == -1: return [a]
	var result: Array[Vector2] = [b]
	while best != -1:
		result.push_front(nodes[best])
		best = previous[best]
	result.push_front(a)
	return result

func advance(from: Vector2, to: Vector2, distance: float) -> Vector2:
	var route := path(from, to)
	var remaining := maxf(distance, 0.0)
	for i in range(1, route.size()):
		var span := route[i - 1].distance_to(route[i])
		if remaining <= span: return route[i - 1].move_toward(route[i], remaining)
		remaining -= span
	return route[-1]

func distance(from: Vector2, to: Vector2) -> float:
	var route := path(from, to)
	if route.size() < 2: return INF
	var total := 0.0
	for i in range(1, route.size()): total += route[i - 1].distance_to(route[i])
	return total
