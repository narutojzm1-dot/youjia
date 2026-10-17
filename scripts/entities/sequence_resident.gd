class_name SequenceResident
extends AnimatedSprite2D

const WALK := preload("res://scenes/experimental/resident_walk_authored_v1.tres")
const IDLE := preload("res://assets/holiday/characters/resident_walk_authored_v1/idle.png")
const ACTION_ATLAS := preload("res://assets/holiday/characters/resident_grass_actions_v1/actions.png")
const STOVE_ATLAS := preload("res://assets/holiday/characters/resident_stove_actions_v1/actions.png")
const MILL_POSE := preload("res://scripts/entities/resident_mill_pose.gd")
var mill_rig: ResidentWalker
var milling_pose_active := false
const ACTION_FRAMES := 9
const ACTION_SECONDS := {&"pickup": 0.60, &"feed": 0.54, &"stove_low":2.16, &"stove_high":2.16, &"stove_top":2.16}
var action_hands: Dictionary = {}
var action_elapsed := 0.0
var action_kind: StringName = &""
var held_action_frame := -1
const STRIDE := 52.0
const NOMINAL_FPS := 12.0
# Match the nearby path's 85px/s at unit depth (96 * 0.9 = 86.4).
# Frame phase follows travelled distance, so faster travel keeps planted steps.
const SPEED_MULTIPLIER := 0.9
var distance_phase:=0.0

func _ready() -> void:
	sprite_frames=WALK.duplicate()
	sprite_frames.add_animation("idle")
	sprite_frames.add_frame("idle",IDLE)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/holiday/characters/resident_grass_actions_v1/manifest.json"))
	action_hands = manifest.hands
	for row: int in 2:
		var kind: StringName = &"pickup" if row == 0 else &"feed"
		sprite_frames.add_animation(kind)
		for index: int in ACTION_FRAMES:
			var picture := AtlasTexture.new()
			picture.atlas = ACTION_ATLAS
			picture.region = Rect2(index * 384, row * 448, 384, 448)
			picture.filter_clip = true
			sprite_frames.add_frame(kind, picture)
	var masonry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/holiday/characters/resident_stove_actions_v1/manifest.json"))
	for row: int in 3:
		var kind: StringName = [&"stove_low",&"stove_high",&"stove_top"][row]
		action_hands[String(kind)] = masonry.hands[String(kind)]
		sprite_frames.add_animation(kind)
		for index: int in ACTION_FRAMES:
			var picture := AtlasTexture.new()
			picture.atlas = STOVE_ATLAS
			picture.region = Rect2(index*384,row*448,384,448)
			picture.filter_clip = true
			sprite_frames.add_frame(kind,picture)
	centered=false
	offset=Vector2(-192,-420)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	reset_motion()

func advance(delta: float,moved: Vector2,depth: float,face: float,reduced: bool,visual_scale: float=1.0) -> void:
	scale=Vector2(face,1.0)*0.25*depth*visual_scale
	pause()
	if milling_pose_active:
		if moved.length()/maxf(delta,0.0001)>=1.0:
			reset_motion()
		else:
			return
	if not action_kind.is_empty():
		if (reduced and not action_kind in [&"stove_low",&"stove_high",&"stove_top"]) or moved.length()/maxf(delta,0.0001)>=1.0:
			reset_motion()
		else:
			if held_action_frame >= 0:
				animation = action_kind
				frame = held_action_frame
				return
			action_elapsed += delta
			var duration: float = ACTION_SECONDS[action_kind]
			if action_elapsed < duration:
				animation = action_kind
				frame = mini(int(action_elapsed / duration * ACTION_FRAMES), ACTION_FRAMES - 1)
				return
			reset_motion()
	if reduced or moved.length()/maxf(delta,0.0001)<1.0:
		reset_motion()
		return
	animation=&"walk"
	distance_phase=fmod(distance_phase+moved.length()/maxf(STRIDE*depth*visual_scale,0.001),1.0)
	var progress:=distance_phase*16.0
	set_frame_and_progress(int(progress),fmod(progress,1.0))

func reset_motion() -> void:
	milling_pose_active = false
	self_modulate = Color.WHITE
	if is_instance_valid(mill_rig): mill_rig.hide()
	held_action_frame = -1
	action_kind = &""
	action_elapsed = 0.0
	pause()
	animation=&"idle"
	frame=0
	distance_phase=0.0

func begin_action(kind: StringName, reduced: bool) -> void:
	reset_motion()
	if reduced or not ACTION_SECONDS.has(kind):
		return
	action_kind = kind
	animation = kind
	frame = 0

func action_hand() -> Vector2:
	var points: Array = action_hands[String(animation)]
	return Vector2(points[frame][0], points[frame][1])

# A production director owns this pose clock. Walking/reduced motion still
# cancel it in advance(); ordinary pickup/feed retain their one-shot timing.
func hold_action_frame(kind: StringName, index: int) -> void:
	if milling_pose_active: reset_motion()
	if not ACTION_SECONDS.has(kind): return
	action_kind = kind
	held_action_frame = clampi(index, 0, ACTION_FRAMES - 1)
	animation = kind
	frame = held_action_frame

func hold_milling_pose(global_contact: Vector2, amount: float, stroke: float) -> void:
	if not is_instance_valid(mill_rig):
		mill_rig = MILL_POSE.new()
		mill_rig.name = "MillGripLayers"
		mill_rig.scale = Vector2.ONE*4.0
		add_child(mill_rig)
	milling_pose_active = true
	# self_modulate hides only this baked sprite; child rigid layers remain lit
	# by the exact same actor/world modulate and are captured as normal sprites.
	self_modulate = Color(1,1,1,0)
	mill_rig.show()
	pause()
	animation = &"idle"
	frame = 0
	mill_rig.apply_contact(mill_rig.to_local(global_contact),amount,stroke)

func milling_hand_global_position() -> Vector2:
	return mill_rig.elbows[1].to_global(Vector2(1.7,11))
