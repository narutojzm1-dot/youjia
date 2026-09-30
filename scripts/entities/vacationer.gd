class_name Vacationer
extends Node2D

const TEXTURE := preload("res://assets/holiday/characters/player.png")
const GRASS := preload("res://assets/holiday/fx/grass_bundle.png")
# 原图按近景画的，缩进院子全景里才像站在草地上的人。
const DISPLAY_SCALE := 0.4

var carrying_grass := false
var player_state := "idle"
var facing := 1.0
var just_fed_seconds := 0.0
var leading := false
# 当前落点的远近。越远越小，和画的透视一起用。
var picture_depth := 1.0

var _sprite: Sprite2D
var _grass: Sprite2D
var _velocity := Vector2.ZERO
var _idle_timer := 0.0
var _step_phase := 0.0
var _gait := GroundedGait.new()
var _rig: PlantedGait
var planted_gait_enabled := false
var native_walker_enabled := false
var _native_walker: NativeWalker
var painted_walker_enabled := false
var _painted_walker: PaintedWalker
var resident_walker_enabled:=false
var sequence_walker_enabled:=false
var _sequence_walker: SequenceResident
var walk_ground: PackedVector2Array = PackedVector2Array()
var avoid_pond := false


func setup(start: Vector2) -> void:
	position = start
	z_index = 8
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.centered = true
	# 锚到脚底，和动物同一套站位。
	_sprite.offset = Vector2(0, -TEXTURE.get_height() * 0.5)
	add_child(_sprite)
	_gait.setup(_sprite, 0.61, 0.53)
	_rig = PlantedGait.new()
	_sprite.add_child(_rig)
	_rig.setup(_sprite, "player")
	set_planted_gait_enabled(OS.get_environment("YOUJIA_PLAYER_GAIT") == "v2")
	_native_walker=preload("res://scenes/native_walker.tscn").instantiate()
	add_child(_native_walker)
	native_walker_enabled=OS.get_environment("YOUJIA_PLAYER_GAIT")=="skeleton"
	_native_walker.visible=native_walker_enabled
	_sprite.visible=not native_walker_enabled
	resident_walker_enabled=OS.get_environment("YOUJIA_PLAYER_GAIT")=="resident"
	_painted_walker=ResidentWalker.new() if resident_walker_enabled else PaintedWalker.new()
	add_child(_painted_walker)
	painted_walker_enabled=OS.get_environment("YOUJIA_PLAYER_GAIT") in ["painted","resident"]
	_painted_walker.visible=painted_walker_enabled
	if painted_walker_enabled:
		_sprite.visible=false
	_sequence_walker=SequenceResident.new()
	add_child(_sequence_walker)
	sequence_walker_enabled=OS.get_environment("YOUJIA_PLAYER_GAIT") in ["","sequence"]
	_sequence_walker.visible=sequence_walker_enabled
	if sequence_walker_enabled:
		_sprite.visible=false
	_grass = Sprite2D.new()
	_grass.texture = GRASS
	_grass.visible = false
	_grass.position = Vector2(18, -28)
	_grass.scale = Vector2(0.55, 0.55)
	add_child(_grass)


func tick(delta: float, input_vector: Vector2, world_size: Vector2) -> void:
	var depth := YardGround.depth_at(position.y)
	picture_depth = depth
	var speed := float(TuningStore.get_value("player.move.max_speed", 96.0)) * depth
	if sequence_walker_enabled:
		speed *= SequenceResident.SPEED_MULTIPLIER
	if leading:
		speed *= float(TuningStore.get_value("player.lead.speed_multiplier", 0.72))
	var desired := input_vector.limit_length(1.0) * speed
	# Responsive acceleration, firmer braking: release should settle on a foot.
	var response := 11.0 if desired.is_zero_approx() else 8.0
	_velocity = _velocity.lerp(desired, 1.0 - exp(-delta * response))
	if desired.is_zero_approx() and _velocity.length() < 0.5:
		_velocity = Vector2.ZERO
	var before := position
	var step := _velocity * delta
	if walk_ground.is_empty():
		position += step
		position.x = clampf(position.x, 40.0, world_size.x - 40.0)
		position.y = clampf(position.y, 390.0, world_size.y - 36.0)
	else:
		position = YardGround.move_inside(position, step, walk_ground, avoid_pond)
	var moved := position - before
	# A fixed per-frame 0.2px cutoff made slow motion stick at high frame rates.
	if absf(step.x) > 0.00001 and absf(moved.x) < 0.00001:
		_velocity.x = 0.0
	if absf(step.y) > 0.00001 and absf(moved.y) < 0.00001:
		_velocity.y = 0.0
	var actual_speed := moved.length() / maxf(delta, 0.0001)
	var moving := actual_speed > 1.0
	if absf(moved.x) / maxf(delta, 0.0001) > 4.0:
		facing = signf(moved.x)
	if moving:
		player_state = "walking"
		_idle_timer = 0.0
	else:
		_idle_timer += delta
		player_state = "idle" if _idle_timer < 2.4 else "watching"
	_gait.advance(delta, moved, depth, 46.0)
	_step_phase = _gait.phase
	_gait.apply(_sprite, delta, facing, bool(TuningStore.get_value("ui.reduced_motion", false)))
	if just_fed_seconds > 0.0:
		just_fed_seconds -= delta
		if just_fed_seconds <= 0.0 and player_state != "walking":
			player_state = "idle"
	var visual := float(TuningStore.get_value("player.visual.scale", 1.0)) * DISPLAY_SCALE * depth
	if planted_gait_enabled:
		_sprite.scale = Vector2(_gait.face * visual, visual)
		_sprite.rotation = 0.0
		_sprite.position.y = 0.0
		_rig.tick(delta, moved, depth, bool(TuningStore.get_value("ui.reduced_motion", false)))
	else:
		_sprite.scale=Vector2(_gait.face*visual*_gait.turn_width,visual)
	if native_walker_enabled:
		_native_walker.scale=Vector2(_gait.face*depth,depth)
		_native_walker.animate(delta,moved,depth,bool(TuningStore.get_value("ui.reduced_motion",false)))
	if painted_walker_enabled:
		_painted_walker.scale=Vector2(_gait.face*depth,depth)
		_painted_walker.animate(delta,moved,depth,bool(TuningStore.get_value("ui.reduced_motion",false)))
	if sequence_walker_enabled:
		_sequence_walker.advance(delta,moved,depth,_gait.face,bool(TuningStore.get_value("ui.reduced_motion",false)),float(TuningStore.get_value("player.visual.scale",1.0)))
	_grass.visible = carrying_grass
	_grass.position = Vector2(18.0 * _gait.face * depth, -28.0 * depth + _sprite.position.y)
	_grass.scale = Vector2(0.55, 0.55) * depth
	z_index = 8 + int(position.y / 8.0)


func set_planted_gait_enabled(enabled: bool) -> void:
	# Explicit legacy fallback. Accepted sequence frames are the default now.
	if _sequence_walker!=null:
		sequence_walker_enabled=false
		_sequence_walker.visible=false
		native_walker_enabled=false
		_native_walker.visible=false
		painted_walker_enabled=false
		_painted_walker.visible=false
		_sprite.visible=true
	planted_gait_enabled=enabled
	_rig.visible=enabled
	_sprite.self_modulate.a=0.0 if enabled else 1.0
	_sprite.material=null if enabled else _gait._material
	_rig.reset_contacts()


func reset_locomotion() -> void:
	if _sequence_walker!=null:
		_sequence_walker.reset_motion()
	if _painted_walker!=null:
		_painted_walker.reset_motion()
	_velocity=Vector2.ZERO
	_gait.weight=0.0
	_rig.reset_contacts()


func pick_grass() -> void:
	carrying_grass = true


func consume_grass() -> bool:
	if not carrying_grass:
		return false
	carrying_grass = false
	just_fed_seconds = 6.0
	player_state = "just_fed"
	return true


func snapshot_state() -> String:
	if just_fed_seconds > 0.0:
		return "just_fed"
	if leading:
		return "leading"
	return player_state
