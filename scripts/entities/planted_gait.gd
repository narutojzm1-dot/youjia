class_name PlantedGait
extends Node2D

# A texture mesh, not a repainted image. Upper-body UVs stay rigid; independent
# leg chains move only their hip/knee/ankle regions. Stance targets live in world
# space so a sole remains on the ground as the character root travels over it.
var foot_world_positions: Array[Vector2] = []
var foot_in_stance: Array[bool] = []
var _source_feet: Array[Vector2] = []
var _hips: Array[Vector2] = []
var _offsets: Array[float] = []
var _swing_starts: Array[Vector2] = []
var _settle_progress: Array[float] = []
var _swing_progress: Array[float] = []
var _swing_duration: Array[float] = []
var _forced_swing: Array[bool] = []
var _mesh: Polygon2D
var _leg_meshes: Array[Polygon2D] = []
var _leg_sources: Array[PackedVector2Array] = []
var _sprite: Sprite2D
var _source: PackedVector2Array
var _kind := "player"
var _phase := 0.0
var _moving := false
var _initialized := false
var _direction := Vector2.RIGHT
var _last_sign := 1.0
var _last_origin := Vector2.ZERO
var _sway_weight := 0.0
var _stride := 34.0
var _duty := 0.62
var _lift := 4.0
var _hip_y := 128.0
var _ankle_y := 195.0
var _fallback: Material
var active := true
var _layers: Variant
var _use_layers := false

func setup(sprite: Sprite2D, kind: String) -> void:
	_sprite = sprite
	_kind = kind
	_fallback = sprite.material
	if kind == "llama":
		_source_feet = [Vector2(43,272), Vector2(81,263), Vector2(118,280), Vector2(157,271)]
		_hips = [Vector2(37,210), Vector2(64,211), Vector2(116,210), Vector2(142,210)]
		_offsets = [0.0, 0.5, 0.25, 0.75]
		_stride = 22.0
		_duty = 0.72
		_lift = 2.5
		_hip_y = 210.0
		_ankle_y = 257.0
	else:
		_source_feet = [Vector2(34,215), Vector2(69,211)]
		_hips = [Vector2(38,128), Vector2(59,128)]
		_offsets = [0.0, 0.5]
	_mesh = Polygon2D.new()
	_mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_mesh)
	_build_mesh()
	if kind in ["player","llama"]:
		_layers=LayeredHero.new() if kind=="player" else LayeredLlama.new()
		add_child(_layers)
		_layers.setup()
		_layers.z_index=-3
		for leg: Polygon2D in _leg_meshes:
			leg.visible=false
	for foot: Vector2 in _source_feet:
		foot_world_positions.append(Vector2.ZERO)
		foot_in_stance.append(true)
		_swing_starts.append(Vector2.ZERO)
		_settle_progress.append(0.0)
		_swing_progress.append(0.0)
		_swing_duration.append(1.0-_duty)
		_forced_swing.append(false)

func _build_mesh() -> void:
	var size := _sprite.texture.get_size()
	var anchor := Vector2(size.x*0.5,size.y)
	_mesh.texture = _sprite.texture
	var upper := PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),Vector2(size.x,_hip_y),Vector2(0,_hip_y)])
	if _kind=="llama":
		# Follow the neutral painting's wool/belly edge instead of slicing
		# the continuous torso with a horizontal rectangular crop.
		upper=PackedVector2Array([Vector2(0,0),Vector2(size.x,0),Vector2(204,200),Vector2(172,205),Vector2(160,218),Vector2(151,222),Vector2(140,218),Vector2(128,215),Vector2(120,223),Vector2(109,225),Vector2(99,225),Vector2(90,219),Vector2(81,225),Vector2(70,226),Vector2(60,220),Vector2(50,217),Vector2(42,224),Vector2(33,225),Vector2(24,220),Vector2(16,211),Vector2(0,208)])
	_mesh.uv = upper
	var body := PackedVector2Array()
	for p: Vector2 in upper:
		body.append(p-anchor)
	_mesh.polygon = body
	# Independent leg meshes can pass in front of one another without folding
	# a triangle across the transparent gap or sampling the neighboring limb.
	for limb: int in _source_feet.size():
		var left := 0.0 if limb==0 else (_source_feet[limb-1].x+_source_feet[limb].x)*0.5
		var right := size.x if limb==_source_feet.size()-1 else (_source_feet[limb].x+_source_feet[limb+1].x)*0.5
		if _kind=="player":
			left=0.0 if limb==0 else 47.0
			right=47.0 if limb==0 else size.x
		var xs: Array[float] = [left,lerpf(left,right,0.25),_source_feet[limb].x,lerpf(left,right,0.75),right]
		xs.sort()
		var ys: Array[float] = [_hip_y,lerpf(_hip_y,_ankle_y,0.3),lerpf(_hip_y,_ankle_y,0.55),lerpf(_hip_y,_ankle_y,0.8),_ankle_y,_source_feet[limb].y,size.y]
		ys.sort()
		var unique_ys: Array[float] = []
		for y: float in ys:
			if unique_ys.is_empty() or not is_equal_approx(y,unique_ys.back()):
				unique_ys.append(y)
		ys=unique_ys
		var source := PackedVector2Array()
		for y: float in ys:
			for x: float in xs:
				source.append(Vector2(x,y))
		var cells: Array[PackedInt32Array] = []
		for row: int in ys.size()-1:
			for col: int in xs.size()-1:
				var index := row*xs.size()+col
				cells.append(PackedInt32Array([index,index+1,index+xs.size()+1,index+xs.size()]))
		var leg := Polygon2D.new()
		leg.texture = _sprite.texture
		leg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		leg.polygons = cells
		leg.uv = source
		var rest_vertices := PackedVector2Array()
		for point: Vector2 in source:
			rest_vertices.append(point-anchor)
		leg.polygon = rest_vertices
		add_child(leg)
		_leg_meshes.append(leg)
		_leg_sources.append(source)

func reset_contacts() -> void:
	_initialized=false
	_moving=false
	position.y=0.0

func tick(delta: float, moved: Vector2, depth: float, reduced: bool) -> void:
	# Other expression paintings have genuinely different leg poses. Never apply
	# neutral-pose joints to them; retain their original rendering until mapped.
	active = _kind != "llama" or _sprite.texture.resource_path.ends_with("/llama.png")
	visible = active
	_use_layers = _layers != null and not reduced
	if _layers != null:
		_layers.visible=_use_layers
		for leg: Polygon2D in _leg_meshes:
			leg.visible=not _use_layers
	_sprite.self_modulate.a = 0.0 if active else 1.0
	_sprite.material = null if active else _fallback
	if not active:
		_initialized = false
		return
	var transform_sign := signf(global_transform.determinant())
	if _initialized and global_position.distance_to(_last_origin) > moved.length()+48.0:
		_initialized=false
	_last_origin=global_position
	if not _initialized or transform_sign != _last_sign or reduced:
		for i: int in _source_feet.size():
			foot_world_positions[i] = _rest_world(i)
			foot_in_stance[i] = true
			_settle_progress[i] = 0.0
			_forced_swing[i] = false
		_initialized = true
		_last_sign = transform_sign
		_phase = 0.0
	var velocity := moved / maxf(delta,0.0001)
	var moving := velocity.length() > 2.0 and not reduced
	# Weight-bearing crouch supplies reach without stretching the painted limbs.
	position.y = 0.0 if reduced else lerpf(position.y, (3.0 if _kind=="llama" else 2.0) if moving else 0.0, 1.0-exp(-delta*10.0))
	if moving:
		_direction = moved.normalized()
		if not _moving:
			_phase = _duty*0.5
		_phase = fmod(_phase + moved.length() / (depth * _stride), 1.0)
	for i: int in _source_feet.size():
		var rest := _rest_world(i)
		var cycle := fmod(_phase + _offsets[i], 1.0)
		if moving:
			var stance := cycle < _duty
			# On diagonal travel or a sharp steering change, lift a strained
			# support foot early rather than stretching its painted leg.
			if stance and foot_in_stance[i] and _needs_recovery(i):
				_forced_swing[i]=true
			if _forced_swing[i]:
				stance=false
			if not stance and foot_in_stance[i] and foot_in_stance.count(true)<=1:
				stance=true
				_forced_swing[i]=false
			if stance:
				if not foot_in_stance[i]:
					foot_world_positions[i] = _landing_world(i) + _direction * (_stride * depth * _duty * 0.5)
				foot_in_stance[i] = true
			else:
				if foot_in_stance[i]:
					_swing_starts[i] = foot_world_positions[i]
					_swing_progress[i]=0.0
					_swing_duration[i]=(1.0-_duty) if _forced_swing[i] else maxf(0.06,1.0-cycle)
				foot_in_stance[i] = false
				_swing_progress[i] = minf(1.0,_swing_progress[i]+moved.length()/(depth*_stride*_swing_duration[i]))
				var u := _swing_progress[i]
				var landing := _landing_world(i) + _direction * (_stride * depth * _duty * 0.5)
				foot_world_positions[i] = _swing_starts[i].lerp(landing, smoothstep(0.0,1.0,u)) - Vector2(0,sin(PI*u)*_lift*depth)
				if _forced_swing[i] and u>=1.0:
					_forced_swing[i]=false
					foot_in_stance[i]=true
					_offsets[i]=fposmod(-_phase,1.0)
			_settle_progress[i] = 0.0
		elif not foot_in_stance[i]:
			# Finish an airborne recovery on release instead of freezing midair
			# or fading every leg back through the ground at the same time.
			if _settle_progress[i] == 0.0:
				_swing_starts[i] = foot_world_positions[i]
			_settle_progress[i] = minf(1.0,_settle_progress[i]+delta/0.16)
			foot_world_positions[i] = _swing_starts[i].lerp(rest,smoothstep(0.0,1.0,_settle_progress[i]))
			if _settle_progress[i] >= 1.0:
				foot_in_stance[i] = true
	_moving = moving
	_sway_weight=move_toward(_sway_weight,1.0 if moving else 0.0,delta*6.0)
	var sway := sin(_phase*TAU)*_sway_weight*(0.014 if _kind=="player" else 0.006)
	if reduced:
		sway=0.0
	var pivot := Vector2(0,_hip_y-_sprite.texture.get_height())
	_mesh.rotation=sway
	_mesh.position=pivot-pivot.rotated(sway)
	_deform()

func _rest_world(index: int) -> Vector2:
	return _sprite.to_global(_source_feet[index] - Vector2(_sprite.texture.get_width()*0.5,_sprite.texture.get_height()))

func _landing_world(index: int) -> Vector2:
	if _kind != "player":
		return _rest_world(index)
	# Both shoes step along the body's travel line. Adding stride to the
	# illustration's already-spread rest feet creates an exaggerated split.
	var center := (_source_feet[0].x+_source_feet[1].x)*0.5
	return _sprite.to_global(Vector2(center,_source_feet[index].y)-Vector2(_sprite.texture.get_width()*0.5,_sprite.texture.get_height()))

func _needs_recovery(index: int) -> bool:
	var anchor := Vector2(_sprite.texture.get_width()*0.5,_sprite.texture.get_height())
	var ankle := _source_feet[index]-Vector2(0,12.0 if _kind=="llama" else 18.0)
	var target_ankle := to_local(foot_world_positions[index])+anchor-Vector2(0,12.0 if _kind=="llama" else 18.0)
	return target_ankle.distance_to(_hips[index]) > ankle.distance_to(_hips[index])*1.08

func _deform() -> void:
	var anchor := Vector2(_sprite.texture.get_width()*0.5,_sprite.texture.get_height())
	for limb: int in _source_feet.size():
		var d := to_local(foot_world_positions[limb])+anchor-_source_feet[limb]
		var hip := _hips[limb]
		var ankle := _source_feet[limb]-Vector2(0,12.0 if _kind=="llama" else 18.0)
		if _use_layers:
			ankle=_source_feet[limb]+_layers.shoe_offset(limb)
		var knee := hip.lerp(ankle,0.52)+Vector2(-3.0,0.0)
		var target_ankle := ankle+d
		var reach := target_ankle-hip
		var upper_length := hip.distance_to(knee)
		var lower_length := knee.distance_to(ankle)
		var distance := maxf(0.01,reach.length())
		# Only allow the tiny extension needed by the source painting's pose;
		# the crouch and short stride keep normal walking inside limb reach.
		var extension := maxf(1.0,distance/(upper_length+lower_length-0.1))
		upper_length*=extension
		lower_length*=extension
		var angle := acos(clampf((upper_length*upper_length+distance*distance-lower_length*lower_length)/(2.0*upper_length*distance),-1.0,1.0))
		var bend_sign := -signf((knee-hip).cross(ankle-hip))
		var target_knee := hip+reach.normalized().rotated(bend_sign*angle)*upper_length
		var upper_angle := (target_knee-hip).angle()-(knee-hip).angle()
		var lower_angle := (target_ankle-target_knee).angle()-(ankle-knee).angle()
		var vertices := PackedVector2Array()
		for source: Vector2 in _leg_sources[limb]:
			var upper := hip+(source-hip).rotated(upper_angle)
			var lower := target_knee+(source-knee).rotated(lower_angle)
			var posed := upper.lerp(lower,smoothstep(knee.y-5.0,knee.y+5.0,source.y))
			posed=posed.lerp(source+d,smoothstep(ankle.y-5.0,ankle.y,source.y))
			posed=source.lerp(posed,smoothstep(_hip_y,_hip_y+9.0,source.y))
			vertices.append(posed-anchor)
		_leg_meshes[limb].polygon=vertices
		if _use_layers:
			_layers.pose_limb(limb,hip-anchor,target_knee-anchor,target_ankle-anchor,_source_feet[limb]+d-anchor)
