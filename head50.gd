class_name YardWorld
extends Node2D

signal album_updated(collected: PackedStringArray, latest_id: String)
signal weather_changed(weather: String)
signal notice_requested(key: String)
signal notice_dismiss_requested(key: String)
signal camera_focus_requested(world_point: Vector2, zoom: float)
signal camera_release_requested
signal cinematic_view_changed(stage: String)
signal day_advanced(day: int)
## 钓到鱼时触发，带上鱼种类字符串，供 HUD 做更强的收杆反馈动画
signal fish_caught(carry_type: String)

const SUNNY := preload("res://assets/holiday/environment/yard_sunny.png")
const OVERCAST := preload("res://assets/holiday/environment/yard_overcast.png")
## 叠加云带：晴/阴各一帧半透明水彩带，不替换整张院子底图。
const CLOUD_SUNNY := preload("res://assets/holiday/environment/cloud_band_sunny.png")
const CLOUD_OVERCAST := preload("res://assets/holiday/environment/cloud_band_overcast.png")
## 傍晚暖色云带：只在晴天且 TOD 为傍晚时替换晴天帧，阴天仍用阴云。
const CLOUD_SUNSET := preload("res://assets/holiday/environment/cloud_band_sunset.png")
## 早晨薄云：晴天 dawn/morning 窗口，比正午更淡、略偏上。
const CLOUD_MORNING := preload("res://assets/holiday/environment/cloud_band_morning.png")
const GrassPatchType := preload("res://scripts/entities/grass_patch.gd")
const FeltActorType := preload("res://scripts/entities/felt_actor.gd")
const VacationerType := preload("res://scripts/entities/vacationer.gd")
## 世界特效层每帧位于角色脚底排序之上。
const WorldEffectsOverlayType := preload("res://scripts/game/world_effects_overlay.gd")
const YardSceneFeedbackType := preload("res://scripts/game/yard_scene_feedback.gd")
const AnimalRelationshipsType := preload("res://scripts/game/animal_relationships.gd")
const AnimalRelationshipEncounterType := preload("res://scripts/game/animal_relationship_encounter.gd")
const WORLD_SIZE := Vector2(1280, 720)
## 云带世界坐标 Y：压在天空带内，不盖住前景动物。
const CLOUD_BAND_Y := 18.0
## 云带缓慢平移速度（世界像素/秒）；低动效时为 0。
const CLOUD_DRIFT_SPEED := 6.5
## REQ-012 切片 C：安静停留后轻微抬头看天（秒）。长于栅栏草叶 2.5s 与鹅马等待 3.5s，避免抢镜头。
const QUIET_SKY_STILL_SECONDS := 5.5
## 抬头镜头保持时长；走动立即取消。
const QUIET_SKY_HOLD_SECONDS := 4.0
## 同一次停留结束后的冷却，避免镜头来回抢。
const QUIET_SKY_COOLDOWN_SECONDS := 28.0
## 轻微放大；不做成任务式取景 UI。
const QUIET_SKY_ZOOM := 1.14
# 人只站在画里已经对上地面的几个位置。圆点是可以走过去的下一处。
const PICTURE_SPOTS := {
	"door": {"position": Vector2(250, 508), "depth": 1.0, "facing": 1.0, "neighbors": ["grass"]},
	"grass": {"position": Vector2(420, 548), "depth": 1.1, "facing": 1.0, "neighbors": ["door", "by_llama", "pond"]},
	"by_llama": {"position": Vector2(578, 478), "depth": 0.88, "facing": 1.0, "neighbors": ["grass", "by_cow", "by_goose"]},
	"by_cow": {"position": Vector2(545, 508), "depth": 1.02, "facing": -1.0, "neighbors": ["by_llama", "grass"]},
