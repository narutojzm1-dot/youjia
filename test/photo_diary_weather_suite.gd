extends SceneTree
## REQ-20261009-077：带 caption_variant 的快照，在日子和瞬间文案之间垫天气纸签（hud.weather.*）。
## 无 weather、未知天气，或有天气但没有 caption_variant 的旧日期档，说明与原文相等。
## 不改捕获、布局和 localization JSON，只改 PhotoDiary 展示。

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func run() -> void:
	var i18n := root.get_node("I18n")
	# Crumb helpers: only the three recorded weathers map; others stay empty.
	for weather: String in ["sun", "overcast", "rain"]:
		var crumb: String = PhotoDiary.weather_crumb({"weather": weather}, i18n)
		check(not crumb.is_empty(), "weather_crumb returns label for %s" % weather)
		check(crumb == str(i18n.call("t", "hud.weather." + weather)),
			"weather_crumb reuses hud.weather.%s" % weather)
	check(PhotoDiary.weather_crumb({}, i18n).is_empty(), "missing weather → no crumb")
	check(PhotoDiary.weather_crumb({"weather": "storm"}, i18n).is_empty(), "unknown weather → no crumb")
	check(PhotoDiary.weather_crumb({"weather": ""}, i18n).is_empty(), "empty weather → no crumb")

	# Full captions: weather sits on the moment line; day line stays the same.
	for loc: String in ["zh-CN", "en"]:
		i18n.set_locale(loc)
		var tag := loc
		var base := {
			"version": 1,
			"rule_id": "fish_first_catch",
			"day": 3,
			"caption_variant": 0,
		}
		var plain: String = PhotoDiary.caption(base)
		check(not plain.is_empty(), tag + " caption without weather still builds")
		check(not plain.contains(" · ") or plain.find(" · ") > plain.find("\n"),
			tag + " plain caption has no weather crumb before the moment")
		# sun
		var sunny: String = PhotoDiary.caption(base.duplicate().merged({"weather": "sun"}))
		var sun_label: String = str(i18n.call("t", "hud.weather.sun"))
		check(sunny.contains(sun_label), tag + " sunny caption contains weather label")
		check(sunny.contains(" · "), tag + " sunny caption pads with middle-dot")
		check(sunny.find(sun_label) > sunny.find("\n"), tag + " weather sits on the moment line")
		# overcast / rain distinct
		var cloudy: String = PhotoDiary.caption(base.duplicate().merged({"weather": "overcast"}))
		var rainy: String = PhotoDiary.caption(base.duplicate().merged({"weather": "rain"}))
		check(cloudy.contains(str(i18n.call("t", "hud.weather.overcast"))), tag + " overcast crumb")
		check(rainy.contains(str(i18n.call("t", "hud.weather.rain"))), tag + " rain crumb")
		check(sunny != cloudy and cloudy != rainy and sunny != rainy,
			tag + " three weathers produce distinct captions")
		# Day line unchanged: both start the same before the newline.
		var plain_day := plain.get_slice("\n", 0)
		check(sunny.begins_with(plain_day), tag + " day line unchanged when weather is added")
		# Legacy: no day → title only, weather ignored for the day template path.
		var legacy: String = PhotoDiary.caption({"rule_id": "fish_first_catch", "weather": "sun"})
		check(not legacy.is_empty() and not legacy.contains(sun_label),
			tag + " legacy no-day caption stays title-only (no invented day/weather line)")
		# 有日期、保留 weather、没有 caption_variant：中英说明都等于不含天气纸签的原文。
		var original_text := str(i18n.call("t", "photo.diary.day", {
			"day": "3",
			"moment": str(i18n.call("t", "photo.diary.fish_first_catch")),
		}))
		for legacy_weather: String in ["sun", "overcast", "rain"]:
			var dated_legacy := {
				"version": 1,
				"rule_id": "fish_first_catch",
				"day": 3,
				"weather": legacy_weather,
			}
			check(dated_legacy.has("weather") and not dated_legacy.has("caption_variant"),
				tag + " dated legacy keeps " + legacy_weather + " and has no caption_variant")
			check(PhotoDiary.caption(dated_legacy) == original_text,
				tag + " dated legacy with " + legacy_weather + " and no caption_variant keeps original caption")

	check(checks >= 20, "suite ran enough checks (%d)" % checks)
	if root.has_node("AudioDirector"):
		root.get_node("AudioDirector").release_streams()
	if failures.is_empty():
		print("[photo-diary-weather] PASS: %d checks" % checks)
		quit(0)
	else:
		for failure: String in failures.slice(0, 30):
			printerr("[photo-diary-weather] " + failure)
		print("[photo-diary-weather] FAIL: %d of %d" % [failures.size(), checks])
		quit(1)
