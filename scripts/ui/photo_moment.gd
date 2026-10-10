class_name PhotoMoment
extends Control

# A compact, inert record of the live yard. No simulation, viewport readback or
# generated artwork: every pose, prop, face and frame comes from the encounter.
const VERSION := 1
const ASSET_ROOT := "res://assets/holiday/"
const WALK_SHADER := preload("res://shaders/felt_walk.gdshader")
const MAX_ITEMS := 64
const MAX_POINTS := 64
const MAX_COORD := 16384.0
const GAIT_DEFAULTS := {
	"phase": 0.0, "amount": 0.0, "hip": 0.68, "foot_split": 0.5,
	"stride_uv": 0.1, "lift_uv": 0.015, "native_walk_face": 1.0,
	"grounded_stride": false, "face_override": false, "rest_breath_shift": 0.0, "blink_amount": 0.0,
}

var _snapshot: Dictionary = {}
var _stage: Node2D
var _ground: Node2D
var _shadows: Node2D
var _background_texture: Texture2D


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(184, 184)
	size = Vector2(184, 184)
	resized.connect(_fit)


# Capture after applying the event's expression, before the yard ticks again.
# This does not change the live actors, inventory, weather or collected IDs.
static func capture(world: Node2D, rule: Dictionary) -> Dictionary:
	if not is_instance_valid(world) or not world.is_inside_tree():
		return {}
	var event_id := str(rule.get("id", ""))
	if event_id.is_empty():
		return {}
	var backdrop: Variant = _property(world, "_backdrop")
	if not backdrop is Sprite2D:
		return {}
	var background := _capture_sprite(backdrop, world, "background", -1, 0)
	if background.is_empty():
		return {}
	var items: Array = []
	_collect(world, world, backdrop, "", items)
	# In an animal portrait the traveler holds the camera behind the frame;
	# otherwise their foreground body can completely hide the subject. Keep
	# the traveler only when their action is part of the event being recorded.
	var traveler_in_frame := event_id in ["llama_fed_gentle", "fish_first_catch"] \
		or (event_id == "llama_overcast_goose_annoyed" and bool(_property(world, "_leading", false)))
	if not traveler_in_frame:
		var portrait_items: Array = []
		for item: Dictionary in items:
			if str(item.get("subject", "")) != "player" and str(item.get("kind", "")) != "line":
				portrait_items.append(item)
		items = portrait_items
	items.sort_custom(_draws_before)
	var shadows: Array = []
	var actors: Dictionary = _property(world, "_actors", {})
	var player: Variant = world.call("get_player") if world.has_method("get_player") else null
	if traveler_in_frame and player is Node2D:
		var point: Vector2 = world.to_local(player.global_position)
		var extent := Vector2(11, 4) * YardGround.depth_at(point.y)
		shadows.append([point.x, point.y, extent.x, extent.y])
	for id: Variant in actors:
		var actor: Variant = actors[id]
		if not actor is Node2D or not actor.is_visible_in_tree():
			continue
		var point: Vector2 = world.to_local(actor.global_position)
		var radius: Vector2 = _property(actor, "body_radius", Vector2(16, 8))
		var extent := Vector2(radius.x, radius.y * 0.42) * YardGround.depth_at(point.y)
		shadows.append([point.x, point.y, extent.x, extent.y])
	var frame := _event_frame(rule, actors, items)
	var world_size: Vector2 = world.call("get_world_size") if world.has_method("get_world_size") else Vector2(1280, 720)
	# Keep every card filled with the actual yard. A pond-centered square can
	# otherwise extend below the painted world, even with the subjects in frame.
	var span := minf(frame.size.x, minf(world_size.x, world_size.y))
	var half_span := span * 0.5
	var focus := Vector2(
		clampf(frame.position.x, half_span, world_size.x - half_span),
		clampf(frame.position.y, half_span, world_size.y - half_span))
	return sanitize({
		"version": VERSION, "rule_id": event_id,
		"day": int(_property(world, "holiday_day", 1)),
		"caption_variant": randi_range(0, clampi(int(rule.get("caption_variants", 1)), 1, 3) - 1),
		"weather": str(_property(world, "weather", "sun")),
		"world_size": [world_size.x, world_size.y],
		"focus": [focus.x, focus.y], "span": span,
		"background": background, "items": items, "shadows": shadows,
		"house_lights": float(world.house.lights) if _property(world,"house") != null else 0.0,
		"yard_gate": world.gate_view.record.duplicate(true) if _property(world,"gate_view") != null else {},
		"rain": world.rain.snapshot() if _property(world,"rain") != null else {},
		"night_sky": world.get_node("RegionalNightSky").snapshot() if world.has_node("RegionalNightSky") else {},
	})


# Only this version's bounded JSON primitives and trusted texture paths survive.
# Legacy album IDs and malformed records intentionally produce no fabricated scene.
static func sanitize(data: Variant) -> Dictionary:
	if not data is Dictionary or not _number(data.get("version"), VERSION, VERSION):
		return {}
	if not data.get("rule_id") is String or data.rule_id.is_empty() or data.rule_id.length() > 96:
		return {}
	if data.has("day") and (not _number(data.day, 1, 10000) or float(data.day) != floorf(float(data.day))):
		return {}
	var caption_count := clampi(int(ExpressionCatalog.find_rule(str(data.rule_id)).get("caption_variants", 1)), 1, 3)
	if data.has("caption_variant") and (
			not _number(data.caption_variant, 0, caption_count - 1)
			or float(data.caption_variant) != floorf(float(data.caption_variant))):
		return {}
	if not data.get("weather") is String or data.weather not in ["sun", "overcast", "rain"]:
		return {}
	if not _numbers(data.get("world_size"), 2, 1.0, 4096.0) or not _numbers(data.get("focus"), 2, -MAX_COORD, MAX_COORD):
		return {}
	if not _number(data.get("span"), 64.0, 4096.0):
		return {}
	if not data.get("items") is Array or data.items.is_empty() or data.items.size() > MAX_ITEMS:
		return {}
	if not data.get("shadows") is Array or data.shadows.size() > 32:
		return {}
	var background := _sanitize_item(data.get("background"))
	if background.is_empty() or background.kind != "sprite":
		return {}
	var items: Array = []
	for raw: Variant in data.items:
		var item := _sanitize_item(raw)
		if item.is_empty():
			return {}
		items.append(item)
	items.sort_custom(_draws_before)
	var shadows: Array = []
	for shadow: Variant in data.shadows:
		if not _numbers(shadow, 4, -MAX_COORD, MAX_COORD) or float(shadow[2]) <= 0.0 or float(shadow[3]) <= 0.0 or float(shadow[2]) > 256.0 or float(shadow[3]) > 256.0:
			return {}
		shadows.append(shadow.duplicate())
	var cleaned := {
		"version": VERSION, "rule_id": data.rule_id, "weather": data.weather,
		"world_size": data.world_size.duplicate(), "focus": data.focus.duplicate(),
		"span": float(data.span), "background": background, "items": items, "shadows": shadows,
	}
	if data.has("day"):
		cleaned.day = int(data.day)
	if data.has("caption_variant"):
		cleaned.caption_variant = int(data.caption_variant)
	var rain := preload("res://scripts/game/regional_rain.gd").sanitize(data.get("rain", {}))
	if not rain.is_empty() and float(rain.amount) > 0.0: cleaned.rain = rain
	var night_sky := preload("res://scripts/game/regional_night_sky.gd").sanitize(data.get("night_sky", {}))
	if not night_sky.is_empty() and float(night_sky.amount) > 0.0: cleaned.night_sky = night_sky
	if data.has("house_lights") and _number(data.house_lights,0.0,1.0): cleaned.house_lights = float(data.house_lights)
	var gate: Variant = data.get("yard_gate", {})
	if gate is Dictionary and gate.get("opened") is bool and _number(gate.get("mix"),0.0,1.0) and _numbers(gate.get("sun"),4,0.0,2.0) and _numbers(gate.get("cloud"),4,0.0,2.0):
		cleaned.yard_gate = gate.duplicate(true)
	return cleaned


static func has_event_subject(snapshot: Dictionary, rule_id: String) -> bool:
	if snapshot.is_empty(): return false
	if rule_id in ["pond_hen_ride", "pond_goose_refused"]:
		var cel := "turtle-hen-ride.png" if rule_id == "pond_hen_ride" else "goose-turtle-peck-miss.png"
		for item: Dictionary in snapshot.get("items", []):
			if item.get("kind", "") == "sprite" and str(item.get("texture", {}).get("path", "")).ends_with("/pond/" + cel): return true
		return false
	if rule_id in ["goose_pond_rest", "goose_duck_shore", "sheep_pair_near"]:
		var seen: Dictionary = {}
		for item: Dictionary in snapshot.get("items", []):
			if item.get("kind", "") == "sprite": seen[str(item.get("subject", ""))] = true
		if rule_id == "goose_pond_rest": return seen.has("goose")
		if rule_id == "sheep_pair_near": return seen.has("sheep_a") and seen.has("sheep_b")
		return seen.has("goose") and (seen.has("duck_a") or seen.has("duck_b") or seen.has("duck_c"))
	var subject := "plant" if rule_id == "plant_first_bloom" else "fishing" if rule_id == "fish_first_catch" else ""
	if subject.is_empty(): return true
	for item: Dictionary in snapshot.get("items", []):
		if item.kind == "prop" and item.subject == subject:
			return true
	return false


func setup(snapshot: Dictionary) -> void:
	_snapshot = sanitize(snapshot)
	if is_instance_valid(_stage):
		remove_child(_stage)
		_stage.queue_free()
	_stage = Node2D.new()
	_stage.name = "RecordedScene"
	_stage.process_mode = Node.PROCESS_MODE_DISABLED
	_stage.z_index = 0
	add_child(_stage)
	_background_texture = null
	if _snapshot.is_empty():
		queue_redraw()
		return
	_background_texture = _load_texture(_snapshot.background.texture)
	_ground = Node2D.new()
	_ground.name = "RecordedGround"
	_ground.draw.connect(_draw_ground)
	_stage.add_child(_ground)
	_shadows = Node2D.new()
	_shadows.name = "RecordedShadows"
	_shadows.draw.connect(_draw_shadows)
	_stage.add_child(_shadows)
	for item: Dictionary in _snapshot.items:
		var visual: Node2D
		if item.kind == "sprite":
			var sprite := Sprite2D.new()
			sprite.texture = _load_texture(item.texture)
			sprite.centered = item.centered
			sprite.offset = _vec(item.offset)
			sprite.flip_h = item.flip_h
			sprite.flip_v = item.flip_v
			sprite.hframes = int(item.frames[0])
			sprite.vframes = int(item.frames[1])
			sprite.frame = int(item.frames[2])
			if item.has("region"):
				sprite.region_enabled = true
				sprite.region_rect = _rect(item.region)
			if item.has("gait"):
				sprite.material = _load_gait(item.gait, str(item.texture.get("path", "")))
			visual = sprite
		elif item.kind == "prop":
			var prop := YardPropVisual.new()
			prop.configure(item.subject, item.state)
			visual = prop
		else:
			var line := Line2D.new()
			for point: Array in item.points:
				line.add_point(_vec(point))
			line.width = float(item.width)
			line.default_color = _color(item.color)
			line.begin_cap_mode = int(item.caps[0])
			line.end_cap_mode = int(item.caps[1])
			line.joint_mode = int(item.joint)
			line.antialiased = true
			visual = line
		visual.transform = _transform(item.transform)
		visual.modulate = _color(item.modulate)
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# Yard depth never leaks outside the clipped card or above modal controls.
		visual.z_index = 0
		visual.z_as_relative = true
		visual.set_meta("subject", item.subject)
		visual.set_meta("recorded_depth", item.depth)
		_stage.add_child(visual)
		# Only the explicitly captured weather layer belongs below contact shadows.
		# Keep legacy items (including negative-depth clouds) in their old order.
		if item.kind == "sprite" and item.subject in ["weather_background", "weather_cloud"]:
			_stage.move_child(visual, _shadows.get_index())
	if _snapshot.has("night_sky"):
		var painted := Sprite2D.new()
		painted.texture = _background_texture
		painted.transform = _transform(_snapshot.background.transform)
		var sky = preload("res://scripts/game/regional_night_sky.gd").new()
		sky.configure(painted)
		painted.free()
		sky.restore(_snapshot.night_sky)
		sky.z_index = 0
		_stage.add_child(sky)
		_stage.move_child(sky, _shadows.get_index())
	if float(_snapshot.get("house_lights",0.0)) > 0.0:
		var light_view = preload("res://scripts/game/house_lights.gd").new()
		light_view.lights = float(_snapshot.house_lights)
		_stage.add_child(light_view)
	if _snapshot.has("yard_gate"):
		var gate = preload("res://scripts/game/yard_gate_view.gd").new()
		_stage.add_child(gate)
		var state: Dictionary = _snapshot.yard_gate
		gate.refresh(state.opened,state.mix,_color(state.sun),_color(state.cloud))
		# Flatten painted pieces into the same inert, clipped draw order as poses.
		# They must not use live yard Z values above the album's modal controls.
		for piece: Node2D in gate.get_children():
			var depth := piece.z_index
			piece.reparent(_stage, false)
			piece.z_index = 0
			piece.set_meta("recorded_depth",depth)
			for other: Node in _stage.get_children():
				if other != piece and int(other.get_meta("recorded_depth",-1)) > depth:
					_stage.move_child(piece,other.get_index())
					break
		gate.free()
	if _snapshot.has("rain"):
		var rain = preload("res://scripts/game/regional_rain.gd").new()
		_stage.add_child(rain)
		rain.configure(_vec(_snapshot.world_size))
		rain.restore(_snapshot.rain)
		for layer: Polygon2D in rain.layers: layer.z_index = 0
		# Water rings remain under the recorded birds, just like the live yard.
		var surface: Polygon2D = rain.layers[0]
		surface.reparent(_stage,false)
		_stage.move_child(surface,_shadows.get_index())
	_fit()


func _fit() -> void:
	if not _snapshot.is_empty() and is_instance_valid(_stage):
		_stage.transform = _card_transform()
	queue_redraw()


func _card_transform() -> Transform2D:
	# Uniform cover keeps the captured composition intact when a card resizes.
	var zoom := maxf(size.x, size.y) / float(_snapshot.span)
	return Transform2D(Vector2(zoom, 0), Vector2(0, zoom), size * 0.5 - _vec(_snapshot.focus) * zoom)


func _draw_ground() -> void:
	if _snapshot.is_empty() or _background_texture == null:
		return
	var background: Dictionary = _snapshot.background
	_ground.draw_set_transform_matrix(_transform(background.transform))
	var texture_size := _background_texture.get_size()
	var origin := _vec(background.offset) - (texture_size * 0.5 if background.centered else Vector2.ZERO)
	_ground.draw_texture_rect(_background_texture, Rect2(origin, texture_size), false, _color(background.modulate))
	_ground.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_shadows() -> void:
	if _snapshot.is_empty():
		return
	for shadow: Array in _snapshot.shadows:
		var point := Vector2(float(shadow[0]), float(shadow[1]) + 1.5)
		var extent := Vector2(float(shadow[2]), float(shadow[3]))
		_shadows.draw_set_transform_matrix(Transform2D(Vector2(extent.x, 0), Vector2(0, extent.y), point))
		_shadows.draw_circle(Vector2.ZERO, 1.20, Color(0.29, 0.25, 0.16, 0.035))
		_shadows.draw_circle(Vector2.ZERO, 0.97, Color(0.29, 0.25, 0.16, 0.060))
		_shadows.draw_circle(Vector2.ZERO, 0.70, Color(0.29, 0.25, 0.16, 0.055))
	_shadows.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _collect(node: Node, world: Node2D, backdrop: Node, subject: String, items: Array) -> void:
	# Shader output has its own bounded frozen record, never the unshaded source bitmap.
	if node.get_script() == preload("res://scripts/game/regional_night_sky.gd"): return
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	var actor_id: Variant = _property(node, "actor_id", "")
	var script: Script = node.get_script() as Script
	if node is Sprite2D and node.name == "WeatherBackdropBlend" and node.get_parent() == world:
		subject = "weather_background"
	elif node is Sprite2D and node.get_parent() == world and str(node.name) in [
			"CloudBandA", "CloudBandB", "CloudMorningA", "CloudMorningB",
			"CloudSunsetA", "CloudSunsetB", "CloudOvercastA", "CloudOvercastB"]:
		subject = "weather_cloud"
	elif node.name == "PhysicalBasket":
		subject = "basket"
	elif node.name == "YardCrop":
		subject = "crop"
	elif actor_id is String and not actor_id.is_empty():
		subject = actor_id
	elif script != null and script.resource_path == "res://scripts/entities/vacationer.gd":
		subject = "player"
	elif script != null and script.resource_path == "res://scripts/entities/grass_patch.gd":
		subject = "grass"
	if node != backdrop:
		var item: Dictionary = {}
		if node is YardPropVisual:
			item = {"kind": "prop", "subject": node.subject, "depth": _depth(node, world), "order": items.size(),
				"transform": _matrix(world.global_transform.affine_inverse() * node.global_transform),
				"modulate": _rgba(_tint(node, world)), "state": node.state.duplicate(true)}
		elif node is Sprite2D or node is AnimatedSprite2D:
			item = _capture_sprite(node, world, subject, _depth(node, world), items.size())
		elif node is Line2D and node.points.size() >= 2:
			var points: Array = []
			for point: Vector2 in node.points:
				points.append([point.x, point.y])
			item = {"kind": "line", "subject": subject, "depth": _depth(node, world), "order": items.size(),
				"transform": _matrix(world.global_transform.affine_inverse() * node.global_transform),
				"modulate": _rgba(_tint(node, world)), "points": points, "width": node.width,
				"color": _rgba(node.default_color), "caps": [node.begin_cap_mode, node.end_cap_mode], "joint": node.joint_mode}
		if not item.is_empty():
			items.append(item)
	for child: Node in node.get_children():
		_collect(child, world, backdrop, subject, items)


static func _capture_sprite(sprite: Node2D, world: Node2D, subject: String, depth: int, order: int) -> Dictionary:
	if _tint(sprite, world).a <= 0.0001: return {}
	var texture: Texture2D
	if sprite is AnimatedSprite2D:
		if sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(sprite.animation):
			return {}
		texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	else:
		texture = sprite.texture
	var descriptor := _texture_data(texture)
	if descriptor.is_empty():
		return {}
	var item := {"kind": "sprite", "subject": subject, "depth": depth, "order": order,
		"texture": descriptor, "transform": _matrix(world.global_transform.affine_inverse() * sprite.global_transform),
		"centered": sprite.centered, "offset": [sprite.offset.x, sprite.offset.y],
		"flip_h": sprite.flip_h, "flip_v": sprite.flip_v, "modulate": _rgba(_tint(sprite, world)), "frames": [1, 1, 0]}
	if sprite is Sprite2D:
		item.frames = [sprite.hframes, sprite.vframes, sprite.frame]
		if sprite.region_enabled:
			item.region = _rectangle(sprite.region_rect)
	var material: Material = sprite.material
	if material is ShaderMaterial and material.shader == WALK_SHADER:
		var gait: Dictionary = {}
		for key: String in GAIT_DEFAULTS:
			var value: Variant = material.get_shader_parameter(key)
			gait[key] = GAIT_DEFAULTS[key] if value == null else value
		if gait.face_override:
			gait.expression = _texture_data(material.get_shader_parameter("expression_texture"))
			var region: Vector4 = material.get_shader_parameter("face_region")
			gait.face_region = [region.x, region.y, region.z, region.w]
		item.gait = gait
	return item


static func _event_frame(rule: Dictionary, actors: Dictionary, items: Array) -> Rect2:
	var selected: Array = []
	var minimum := 220.0
	var event_id := str(rule.get("id", ""))
	match event_id:
		"pond_hen_ride", "pond_goose_refused":
			selected = ["turtle"]
			minimum = 240.0
		"llama_fed_gentle":
			selected = ["player", "llama"]
			minimum = 190.0
		"llama_overcast_goose_annoyed":
			selected = ["llama", "goose"]
			minimum = 200.0
		"llama_sun_sheep_happy":
			selected = ["llama"]
			var llama: Variant = actors.get("llama")
			var nearest := ""
			var distance := INF
			for id: Variant in actors:
				var actor: Variant = actors[id]
				if llama is Node2D and actor is Node2D and _property(actor, "species", "") == "sheep":
					var next_distance: float = llama.position.distance_squared_to(actor.position)
					if next_distance < distance:
						distance = next_distance
						nearest = str(id)
			if not nearest.is_empty(): selected.append(nearest)
		"llama_sheep_cow_smirk":
			selected = ["llama", "cow", "horse"]
			minimum = 300.0
		"goose_horse_mount":
			selected = ["goose", "horse"]
			minimum = 230.0
		"duck_pond_chorus":
			selected = ["duck_a", "duck_b", "duck_c"]
			minimum = 330.0
		"goose_pond_rest":
			selected = ["goose"]
			minimum = 230.0
		"goose_duck_shore":
			selected = ["goose"]
			var goose: Variant = actors.get("goose")
			var nearest := ""
			var distance := INF
			for id: Variant in actors:
				var duck: Variant = actors[id]
				if goose is Node2D and duck is Node2D and _property(duck, "species", "") == "duck":
					var next_distance: float = goose.position.distance_squared_to(duck.position)
					if next_distance < distance:
						distance = next_distance
						nearest = str(id)
			if not nearest.is_empty(): selected.append(nearest)
			minimum = 260.0
		"sheep_pair_near":
			selected = ["sheep_a", "sheep_b"]
			minimum = 260.0
		"cow_rare_calm":
			selected = ["cow"]
			minimum = 240.0
		"plant_first_bloom":
			selected = ["plant"]
			minimum = 128.0
		"fish_first_catch":
			selected = ["player", "fishing"]
			minimum = 200.0
		_:
			var owner := str(rule.get("owner", "llama"))
			selected = [owner]
			# Rules name a species; multi-actor species have distinct snapshot IDs.
			# Keep their recorded bodies in frame instead of the no-subject fallback.
			if not actors.has(owner):
				for id: Variant in actors:
					if _property(actors[id], "species", "") == owner:
						selected.append(str(id))
	var bounds := Rect2()
	var found := false
	for item: Dictionary in items:
		if item.kind == "prop" and item.subject in selected:
			var prop_bounds := _transform(item.transform) * YardPropVisual.bounds(item.subject)
			bounds = bounds.merge(prop_bounds) if found else prop_bounds
			found = true
			continue
		if item.kind != "sprite" or item.subject not in selected:
			continue
		var texture := _load_texture(item.texture)
		if texture == null: continue
		var extent := texture.get_size() / Vector2(float(item.frames[0]), float(item.frames[1]))
		if item.has("region"): extent = _rect(item.region).size
		var origin := _vec(item.offset) - (extent * 0.5 if item.centered else Vector2.ZERO)
		var rectangle := _transform(item.transform) * Rect2(origin, extent)
		bounds = bounds.merge(rectangle) if found else rectangle
		found = true
	if event_id == "duck_pond_chorus":
		var pond := Rect2(YardGround.POND_CENTER - YardGround.POND_RADIUS, YardGround.POND_RADIUS * 2.0)
		bounds = bounds.merge(pond) if found else pond
		found = true
	if event_id == "plant_first_bloom" and not found:
		# 植物床位于院子左上角 (205, 575)；硬编码构图以确保拍立得聚焦在正确位置
		bounds = Rect2(179, 555, 52, 40)
		found = true
	if not found: bounds = Rect2(540, 390, 180, 160)
	bounds = bounds.grow(18.0)
	var span := clampf(maxf(minimum, maxf(bounds.size.x, bounds.size.y)), 64.0, 4096.0)
	return Rect2(bounds.get_center(), Vector2(span, span))


static func _sanitize_item(raw: Variant) -> Dictionary:
	if not raw is Dictionary or raw.get("kind") not in ["sprite", "line", "prop"]:
		return {}
	if not raw.get("subject") is String or raw.subject.length() > 64:
		return {}
	if not _number(raw.get("depth"), -MAX_COORD, MAX_COORD) or not _number(raw.get("order"), 0, MAX_ITEMS):
		return {}
	if not _numbers(raw.get("transform"), 6, -MAX_COORD, MAX_COORD) or not _numbers(raw.get("modulate"), 4, 0, 4):
		return {}
	for index: int in 4:
		if absf(float(raw.transform[index])) > 64.0: return {}
	var item := {"kind": raw.kind, "subject": raw.subject, "depth": int(raw.depth), "order": int(raw.order),
		"transform": raw.transform.duplicate(), "modulate": raw.modulate.duplicate()}
	if raw.kind == "prop":
		var state := YardPropVisual.sanitize_state(raw.subject, raw.get("state"))
		if state.is_empty(): return {}
		item.state = state
		return item
	if raw.kind == "line":
		if not _number(raw.get("width"), 0.01, 32.0) or not _numbers(raw.get("color"), 4, 0, 4): return {}
		if not _numbers(raw.get("caps"), 2, 0, 2) or not _number(raw.get("joint"), 0, 2): return {}
		if not raw.get("points") is Array or raw.points.size() < 2 or raw.points.size() > MAX_POINTS: return {}
		var points: Array = []
		for point: Variant in raw.points:
			if not _numbers(point, 2, -MAX_COORD, MAX_COORD): return {}
			points.append(point.duplicate())
		item.merge({"points": points, "width": float(raw.width), "color": raw.color.duplicate(), "caps": raw.caps.duplicate(), "joint": int(raw.joint)})
		return item
	var texture := _sanitize_texture(raw.get("texture"))
	if texture.is_empty() or not _numbers(raw.get("offset"), 2, -MAX_COORD, MAX_COORD): return {}
	for key: String in ["centered", "flip_h", "flip_v"]:
		if not raw.get(key) is bool: return {}
	if not _numbers(raw.get("frames"), 3, 0, 4095): return {}
	var frames: Array = raw.frames
	if float(frames[0]) < 1 or float(frames[1]) < 1 or float(frames[0]) > 64 or float(frames[1]) > 64 or float(frames[2]) >= float(frames[0]) * float(frames[1]): return {}
	for value: Variant in frames:
		if float(value) != floorf(float(value)): return {}
	item.merge({"texture": texture, "offset": raw.offset.duplicate(), "centered": raw.centered,
		"flip_h": raw.flip_h, "flip_v": raw.flip_v, "frames": frames.duplicate()})
	if raw.has("region"):
		if not _valid_rect(raw.region): return {}
		item.region = raw.region.duplicate()
	if raw.has("gait"):
		var gait := _sanitize_gait(raw.gait)
		if gait.is_empty(): return {}
		item.gait = gait
	return item


static func _sanitize_gait(raw: Variant) -> Dictionary:
	if not raw is Dictionary: return {}
	var result: Dictionary = {}
	for key: String in GAIT_DEFAULTS:
		var value: Variant = raw.get(key, GAIT_DEFAULTS[key])
		if GAIT_DEFAULTS[key] is bool:
			if not value is bool: return {}
		else:
			if not _number(value, -100000.0 if key == "phase" else -4.0, 100000.0 if key == "phase" else 4.0): return {}
		if key == "blink_amount" and not _number(value, 0.0, 1.0): return {}
		if key == "rest_breath_shift" and not _number(value, 0.0, 0.006): return {}
		result[key] = value
	if result.face_override:
		var expression := _sanitize_texture(raw.get("expression"))
		if expression.is_empty() or not _numbers(raw.get("face_region"), 4, 0, 1): return {}
		if float(raw.face_region[2]) <= 0 or float(raw.face_region[3]) <= 0: return {}
		result.expression = expression
		result.face_region = raw.face_region.duplicate()
	return result


static func _texture_data(texture: Texture2D) -> Dictionary:
	if texture is AtlasTexture:
		if texture.atlas == null or not _valid_path(texture.atlas.resource_path): return {}
		return {"atlas": texture.atlas.resource_path, "region": _rectangle(texture.region),
			"margin": _rectangle(texture.margin), "filter_clip": texture.filter_clip}
	if texture != null and _valid_path(texture.resource_path):
		return {"path": texture.resource_path}
	return {}


static func _sanitize_texture(raw: Variant) -> Dictionary:
	if not raw is Dictionary: return {}
	if raw.has("path"):
		return {"path": raw.path} if _valid_path(raw.path) else {}
	if not _valid_path(raw.get("atlas")) or not _valid_rect(raw.get("region")): return {}
	if not _numbers(raw.get("margin"), 4, 0, 8192) or not raw.get("filter_clip") is bool: return {}
	return {"atlas": raw.atlas, "region": raw.region.duplicate(), "margin": raw.margin.duplicate(), "filter_clip": raw.filter_clip}


static func _load_texture(data: Dictionary) -> Texture2D:
	if data.has("path"): return load(data.path) as Texture2D
	var texture := AtlasTexture.new()
	texture.atlas = load(data.atlas) as Texture2D
	texture.region = _rect(data.region)
	texture.margin = _rect(data.margin)
	texture.filter_clip = data.filter_clip
	return texture


static func _load_gait(data: Dictionary, texture_path := "") -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WALK_SHADER
	for key: String in GAIT_DEFAULTS:
		material.set_shader_parameter(key, data[key])
	preload("res://scripts/entities/painted_rest_breath.gd").configure(material, texture_path)
	if float(data.blink_amount) > 0.0:
		var blink := preload("res://scripts/entities/painted_blink.gd").new()
		var profile: String = blink.profile_for_source(texture_path)
		if profile.is_empty():
			material.set_shader_parameter("blink_amount", 0.0)
		else:
			blink.bind(material, profile)
			material.set_shader_parameter("blink_amount", float(data.blink_amount))
	if data.face_override:
		material.set_shader_parameter("expression_texture", _load_texture(data.expression))
		var region: Array = data.face_region
		material.set_shader_parameter("face_region", Vector4(float(region[0]), float(region[1]), float(region[2]), float(region[3])))
	return material


static func _valid_path(value: Variant) -> bool:
	if not value is String or value.length() > 240 or not value.begins_with(ASSET_ROOT): return false
	if value.contains("..") or value.contains("\\") or value.contains("::") or value.simplify_path() != value: return false
	if value.get_extension().to_lower() not in ["png", "webp", "jpg", "jpeg"]: return false
	return ResourceLoader.exists(value, "Texture2D")


static func _number(value: Variant, lower: float, upper: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= lower and float(value) <= upper


static func _numbers(value: Variant, count: int, lower: float, upper: float) -> bool:
	if not value is Array or value.size() != count: return false
	for number: Variant in value:
		if not _number(number, lower, upper): return false
	return true


static func _valid_rect(value: Variant) -> bool:
	return _numbers(value, 4, 0, 8192) and float(value[2]) > 0 and float(value[3]) > 0


static func _property(node: Object, key: String, fallback: Variant = null) -> Variant:
	for property: Dictionary in node.get_property_list():
		if property.name == key: return node.get(key)
	return fallback


static func _depth(node: CanvasItem, world: Node2D) -> int:
	var depth := node.z_index
	var cursor: CanvasItem = node
	while cursor != world and cursor.z_as_relative:
		cursor = cursor.get_parent() as CanvasItem
		if cursor == null: break
		depth += cursor.z_index
	return depth


static func _tint(node: CanvasItem, world: Node2D) -> Color:
	var tint := node.modulate * node.self_modulate
	var cursor := node.get_parent() as CanvasItem
	while cursor != null:
		tint *= cursor.modulate
		if cursor == world: break
		cursor = cursor.get_parent() as CanvasItem
	return tint


static func _draws_before(a: Dictionary, b: Dictionary) -> bool:
	return int(a.depth) < int(b.depth) or (int(a.depth) == int(b.depth) and int(a.order) < int(b.order))


static func _vec(values: Array) -> Vector2:
	return Vector2(float(values[0]), float(values[1]))


static func _rect(values: Array) -> Rect2:
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


static func _rectangle(rectangle: Rect2) -> Array:
	return [rectangle.position.x, rectangle.position.y, rectangle.size.x, rectangle.size.y]


static func _rgba(color: Color) -> Array:
	return [color.r, color.g, color.b, color.a]


static func _color(values: Array) -> Color:
	return Color(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


static func _matrix(transform: Transform2D) -> Array:
	return [transform.x.x, transform.x.y, transform.y.x, transform.y.y, transform.origin.x, transform.origin.y]


static func _transform(values: Array) -> Transform2D:
	return Transform2D(Vector2(float(values[0]), float(values[1])), Vector2(float(values[2]), float(values[3])), Vector2(float(values[4]), float(values[5])))
