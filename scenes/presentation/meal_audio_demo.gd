extends Node
## Isolation demo for GROK #745 meal audio leaf. Keys: C cook toggle, P pause, H hunger.

const MealAudioScript := preload("res://scripts/presentation/meal_audio.gd")

var _leaf: Node
var _label: Label


func _ready() -> void:
	_leaf = MealAudioScript.new()
	_leaf.name = "MealAudio"
	add_child(_leaf)
	_label = Label.new()
	_label.position = Vector2(24, 24)
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)
	var audio: Node = get_node("/root/AudioDirector")
	audio.call("unlock_audio")
	_leaf.ensure_registered()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_C:
			_leaf.set_cooking(not _leaf.is_cooking())
		KEY_P:
			_leaf.set_paused(not _leaf.is_paused())
		KEY_H:
			_leaf.play_hunger()
		KEY_S:
			_leaf.play_spoon_now()
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if _leaf == null or _label == null:
		return
	var snap: Dictionary = _leaf.debug_snapshot()
	_label.text = (
		"GROK #745 meal audio demo\n"
		+ "C cook | P pause | H hunger | S spoon\n"
		+ "cooking=%s paused=%s playing=%s\n" % [snap["cooking"], snap["paused"], snap["cook_playing"]]
		+ "hunger=%s spoon=%s players=%s" % [snap["hunger_play_count"], snap["spoon_play_count"], snap["child_players"]]
	)
