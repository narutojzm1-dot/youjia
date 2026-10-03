class_name SequenceResident
extends AnimatedSprite2D

const WALK := preload("res://scenes/experimental/resident_walk_authored_v1.tres")
const IDLE := preload("res://assets/holiday/characters/resident_walk_authored_v1/idle.png")
const ACTION_ATLAS := preload("res://assets/holiday/characters/resident_grass_actions_v1/actions.png")
const ACTION_FRAMES := 9
const ACTION_SECONDS := {&"pickup": 0.60, &"feed": 0.54}
var action_hands: Dictionary = {}
var action_elapsed := 0.0
var action_kind: StringName = &""
const STRIDE := 52.0
const NOMINAL_FPS := 12.0
# A brisk, comfortable walk while keeping the authored stride registered to travel.
# At the default 96px/s tuning this gives 61.4px/s; frame phase still follows distance.
const SPEED_MULTIPLIER := 0.64
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
	centered=false
	offset=Vector2(-192,-420)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	reset_motion()

func advance(delta: float,moved: Vector2,depth: float,face: float,reduced: bool,visual_scale: float=1.0) -> void:
	scale=Vector2(face,1.0)*0.25*depth*visual_scale
	pause()
	if not action_kind.is_empty():
		if reduced or moved.length()/maxf(delta,0.0001)>=1.0:
			reset_motion()
		else:
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
