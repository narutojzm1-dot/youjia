class_name SequenceResident
extends AnimatedSprite2D

const WALK := preload("res://scenes/experimental/resident_walk_authored_v1.tres")
const IDLE := preload("res://assets/holiday/characters/resident_walk_authored_v1/idle.png")
const STRIDE := 52.0
const NOMINAL_FPS := 12.0
# 52 world pixels / (16 frames / 12fps) = 39px/s at unit depth/scale.
const SPEED_MULTIPLIER := 39.0/96.0
var distance_phase:=0.0

func _ready() -> void:
	sprite_frames=WALK.duplicate()
	sprite_frames.add_animation("idle")
	sprite_frames.add_frame("idle",IDLE)
	centered=false
	offset=Vector2(-192,-420)
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	reset_motion()

func advance(delta: float,moved: Vector2,depth: float,face: float,reduced: bool,visual_scale: float=1.0) -> void:
	scale=Vector2(face,1.0)*0.25*depth*visual_scale
	pause()
	if reduced or moved.length()/maxf(delta,0.0001)<1.0:
		reset_motion()
		return
	animation=&"walk"
	distance_phase=fmod(distance_phase+moved.length()/maxf(STRIDE*depth*visual_scale,0.001),1.0)
	var progress:=distance_phase*16.0
	set_frame_and_progress(int(progress),fmod(progress,1.0))

func reset_motion() -> void:
	pause()
	animation=&"idle"
	frame=0
	distance_phase=0.0
