extends Node2D

# #749 溪流裁切版隔离 demo 驱动。仍只是候选：不碰主游戏、存档、导航或生产宿主文件。
## 画面结构仿近郊宿主：Painting 是整幅原画，StreamCrop 是挂在它下面的 183×302 溪床子层。
## phase 是弧度 0→TAU，一圈 8 秒：phase = fposmod(phase + max(delta, 0) * TAU / 8, TAU)。
## 不复用现有近郊动效的 0.42 rad/s，也不用内置 TIME。
## 暂停：phase 冻结。减少动态：撤掉子层（隐藏），只剩原画静帧，phase 冻结。
## strength 0 时子层整层透明，同样只剩原画。
## 线性过滤 / 缩放：--scale 把整幅 Painting（含子层）按比例缩放，用于观察不同分辨率下的采样。
## CODEX-LEAD 2026-10-16 #749：base_sample_linear 默认 true，底图连续 UV 匹配宿主线性原画。
## 控制图仍 nearest。保护区、strength 0、减少动态回原画保持。

const PERIOD_SEC := 8.0
const CROP_RECT := Rect2i(191, 543, 183, 302)
const _TEXEL_EPS := 0.001

var phase: float = 0.0
var paused: bool = false
var reduced_motion: bool = false
var scale_factor: float = 1.0
var painting_offset: Vector2 = Vector2.ZERO

var _sequence_dir: String = ""

var _dump_path: String = ""
var _dump_started: bool = false
var _self_check: bool = false
var _web_probe: bool = false
var _web_matrix: bool = false
var _web_matrix_dir: String = ""
var _build_id: String = ""

var base_sample_linear: bool = true

@onready var _painting: Sprite2D = $Painting
@onready var _crop: Sprite2D = $Painting/StreamCrop


func _ready() -> void:
	_parse_user_args()
	# 默认 true；--base-nearest 在解析时覆写为 false。只在解析后提交一次。
	_material().set_shader_parameter("base_sample_linear", base_sample_linear)
	_crop.position = Vector2(CROP_RECT.position)
	_painting.scale = Vector2(scale_factor, scale_factor)
	_painting.position = painting_offset
	_apply_motion()
	_push_phase()
	print("Stream crop demo ready. phase=", phase, " paused=", paused, " reduced=", reduced_motion,
		" strength=", _material().get_shader_parameter("strength"), " crop=", CROP_RECT,
		" scale=", scale_factor, " offset=", painting_offset,
		" base_sample_linear=", _material().get_shader_parameter("base_sample_linear"))
	# 启动断言：实际提交值必须与解析结果一致（默认 true，--base-nearest 为 false）。
	var actual := bool(_material().get_shader_parameter("base_sample_linear"))
	if actual != base_sample_linear:
		push_error("base_sample_linear startup mismatch: wanted %s got %s" % [base_sample_linear, actual])
	if _self_check:
		_run_self_check()
	elif _web_matrix:
		_run_web_matrix()
	elif _web_probe:
		_run_web_probe()
	elif _sequence_dir != "":
		_run_sequence_check()


func _material() -> ShaderMaterial:
	return _crop.material as ShaderMaterial


func step_phase(delta: float) -> float:
	if paused or reduced_motion:
		return 0.0
	var before := phase
	phase = fposmod(phase + maxf(delta, 0.0) * TAU / PERIOD_SEC, TAU)
	return phase - before


func _process(delta: float) -> void:
	if step_phase(delta) != 0.0:
		_push_phase()
	if _dump_path != "" and not _dump_started:
		_dump_started = true
		_dump_and_quit()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_P or key.keycode == KEY_SPACE:
		paused = not paused
	elif key.keycode == KEY_R:
		reduced_motion = not reduced_motion
		_apply_motion()
	elif key.keycode == KEY_BRACKETLEFT:
		scale_factor = maxf(0.25, scale_factor - 0.25)
		_painting.scale = Vector2(scale_factor, scale_factor)
	elif key.keycode == KEY_BRACKETRIGHT:
		scale_factor = minf(3.0, scale_factor + 0.25)
		_painting.scale = Vector2(scale_factor, scale_factor)


func _apply_motion() -> void:
	# 与生产既有减少动态一致：撤掉动效层，回到原画静态，不把 strength 0.20 当默认。
	_crop.visible = not reduced_motion


func _push_phase() -> void:
	_material().set_shader_parameter("phase", phase)


func _parse_user_args() -> void:
	var args := OS.get_cmdline_user_args()
	# Web 导出没有命令行：页面地址带 ?probe=1 时跑同一套 --web-probe。
	if OS.has_feature("web"):
		var query := str(JavaScriptBridge.eval("window.location.search", true))
		if query.contains("probe=1"):
			_web_probe = true
		# ?matrix=1：完整 10×5 缩放/子像素矩阵（web_matrix_20261017/），不改 ?probe=1 既有路径。
		if query.contains("matrix=1"):
			_web_matrix = true
	var i := 0
	while i < args.size():
		var token := str(args[i])
		if token == "--dump-frame" and i + 1 < args.size():
			_dump_path = str(args[i + 1])
			paused = true
			i += 2
		elif token == "--phase" and i + 1 < args.size():
			phase = float(args[i + 1])
			paused = true
			i += 2
		elif token == "--strength" and i + 1 < args.size():
			_material().set_shader_parameter("strength", float(args[i + 1]))
			i += 2
		elif token == "--scale" and i + 1 < args.size():
			scale_factor = float(args[i + 1])
			i += 2
		elif token == "--offset" and i + 2 < args.size():
			# 整幅 Painting 的屏幕位置（可带小数，用于线性过滤子像素相位对照）。
			painting_offset = Vector2(float(args[i + 1]), float(args[i + 2]))
			i += 3
		elif token == "--sequence-check" and i + 1 < args.size():
			_sequence_dir = str(args[i + 1])
			i += 2
		elif token == "--base-linear":
			base_sample_linear = true
			i += 1
		elif token == "--base-nearest":
			# 历史/受控 legacy：强制底图纹素中心取样，供与整幅 nearest 预览对照。
			base_sample_linear = false
			i += 1
		elif token == "--reduced":
			reduced_motion = true
			i += 1
		elif token == "--web-matrix" and i + 1 < args.size():
			# 桌面同代码对照：PNG 存到该目录（Web 下改为上传给本轮探针服务器）。
			_web_matrix = true
			_web_matrix_dir = str(args[i + 1])
			i += 2
		elif token == "--web-probe":
			_web_probe = true
			i += 1
		elif token == "--self-check":
			_self_check = true
			i += 1
		else:
			i += 1


func _run_self_check() -> void:
	var ok := true
	var eps := 0.000001
	phase = 0.0; paused = false; reduced_motion = false
	var normal := step_phase(0.1)
	ok = ok and absf(normal - TAU / PERIOD_SEC * 0.1) < eps
	phase = 1.0
	var back := step_phase(-0.5)
	ok = ok and back == 0.0 and phase == 1.0
	phase = TAU - 0.01
	step_phase(0.1)
	ok = ok and phase >= 0.0 and phase < TAU
	phase = 0.5; paused = true
	ok = ok and step_phase(0.1) == 0.0 and phase == 0.5
	paused = false; reduced_motion = true; _apply_motion()
	ok = ok and step_phase(0.1) == 0.0 and not _crop.visible
	reduced_motion = false; _apply_motion()
	ok = ok and _crop.visible
	var tex_size := _crop.texture.get_size()
	ok = ok and Vector2i(tex_size) == CROP_RECT.size
	ok = ok and Vector2i(_crop.position) == CROP_RECT.position
	print("crop self-check normal=", normal, " back=", back, " tex=", tex_size, " ok=", ok)
	if not ok:
		push_error("crop demo self-check failed")
	get_tree().quit(0 if ok else 1)


func _dump_and_quit() -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_dump_path)
	print("dump ", _dump_path, " err ", err, " size ", image.get_size(), " phase ", phase)
	get_tree().quit()


## 连续暂停 / 减少动态切换实测（需要窗口；xvfb-run 可）：走真实 _process 帧，
## 通过 Input.parse_input_event 发 P / R 键，与玩家按键同一路径；每步存一帧 PNG 给 verify_scale_linear.py 比较。
func _press(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _snap(tag: String) -> String:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var path := _sequence_dir.path_join("seq_%s.png" % tag)
	get_viewport().get_texture().get_image().save_png(path)
	return path


func _run_sequence_check() -> void:
	var rows: Array[String] = []
	var ok := true
	paused = false
	reduced_motion = false
	_apply_motion()
	await _frames(30)
	var p_run := phase
	ok = ok and p_run > 0.0
	rows.append("run30 phase=%.6f visible=%s" % [p_run, _crop.visible])
	await _press(KEY_P)
	var p_pause := phase
	await _snap("1_paused_a")
	await _frames(30)
	ok = ok and paused and phase == p_pause
	rows.append("paused+30 phase=%.6f (at pause %.6f) paused=%s" % [phase, p_pause, paused])
	await _snap("2_paused_b")
	await _press(KEY_R)
	ok = ok and reduced_motion and not _crop.visible
	await _snap("3_paused_reduced")
	await _frames(30)
	ok = ok and phase == p_pause
	rows.append("paused+reduced+30 phase=%.6f visible=%s" % [phase, _crop.visible])
	await _press(KEY_R)
	ok = ok and not reduced_motion and _crop.visible and phase == p_pause
	await _snap("4_paused_restored")
	rows.append("restore phase=%.6f visible=%s" % [phase, _crop.visible])
	await _press(KEY_P)
	await _frames(30)
	var p_resume := phase
	ok = ok and not paused and p_resume != p_pause
	rows.append("resume+30 phase=%.6f" % p_resume)
	await _press(KEY_R)
	var p_red := phase
	await _snap("5_running_reduced")
	await _frames(30)
	ok = ok and reduced_motion and not _crop.visible and phase == p_red
	rows.append("running+reduced+30 phase=%.6f (at toggle %.6f) visible=%s" % [phase, p_red, _crop.visible])
	await _press(KEY_R)
	ok = ok and _crop.visible
	await _frames(30)
	ok = ok and phase != p_red
	rows.append("reduced off +30 phase=%.6f visible=%s" % [phase, _crop.visible])
	for r in rows:
		print("seq ", r)
	print("sequence-check ok=", ok)
	get_tree().quit(0 if ok else 1)


## Web 隔离实测（--web-probe，或 Web 导出页面 ?probe=1）：不存文件，只在控制台打印一行 WEBPROBE 结果。
## 先跑既有 1:1（scale 1.0、偏移 0），再跑小子集缩放/子像素（0.75 整数居中、2.0 +0.37/+0.61），硬门对齐桌面线性对照。
## 读回的是本页真实画布，不是离线 PNG。帧时只代表当前浏览器/渲染后端，headless SwiftShader 不能当真实 GPU / 手机帧时。
func _water_mask() -> PackedByteArray:
	var flow := (load("res://textures/crop/flow_map.png") as Texture2D).get_image()
	var secw := (load("res://textures/crop/secondary_weight.png") as Texture2D).get_image()
	flow.convert(Image.FORMAT_RGBA8)
	secw.convert(Image.FORMAT_RGBA8)
	var mask := PackedByteArray()
	mask.resize(CROP_RECT.size.x * CROP_RECT.size.y)
	for y in CROP_RECT.size.y:
		for x in CROP_RECT.size.x:
			var f := flow.get_pixel(x, y)
			var w := secw.get_pixel(x, y)
			mask[y * CROP_RECT.size.x + x] = 1 if (f.a8 > 0 or w.r8 > 0 or w.g8 > 0 or w.b8 > 0) else 0
	return mask


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img


## 返回 [nonwater_max, water_max, water_changed_px, band_max]。
## s/ox/oy 为 Painting 的 scale 与 position（默认 1:1 原点）。
## 分类对齐 verify_scale_linear.py：屏幕像素中心 → Painting 连续坐标，再对 ±eps 四个纹素角做 all/any。
## nonwater 只用 ~w_any（四角皆非水面）；水面变化只用 w_all 且非 tie；band 用裁切外 ±3 屏像素且 ~r_any。

func _mask_at(mask: PackedByteArray, tx: int, ty: int) -> bool:
	if tx < 0 or ty < 0 or tx >= CROP_RECT.size.x or ty >= CROP_RECT.size.y:
		return false
	return mask[ty * CROP_RECT.size.x + tx] == 1


## tie_aware（仅完整矩阵用，?probe=1 既有路径不变）：±1 纹素邻域按四角 lo/hi 两侧各外扩 1（像素中心恰在纹素边界时
## floor(l)±1 只覆盖一侧，SwiftShader 在 ×0.75/×1.5 整数偏移下边界像素会落到另一侧）；与 web_matrix_verdict.py 同一判据。
func _diff(a: Image, b: Image, mask: PackedByteArray, s: float = 1.0, ox: float = 0.0, oy: float = 0.0, tie_aware: bool = false) -> Array:
	var nonwater_max := 0
	var water_max := 0
	var water_changed := 0
	var band_max := 0
	var img_w := a.get_width()
	var img_h := a.get_height()
	var sx0 := int(floor(ox + float(CROP_RECT.position.x) * s - 3.0))
	var sy0 := int(floor(oy + float(CROP_RECT.position.y) * s - 3.0))
	var sx1 := int(ceil(ox + float(CROP_RECT.position.x + CROP_RECT.size.x) * s + 3.0))
	var sy1 := int(ceil(oy + float(CROP_RECT.position.y + CROP_RECT.size.y) * s + 3.0))
	sx0 = clampi(sx0, 0, img_w)
	sy0 = clampi(sy0, 0, img_h)
	sx1 = clampi(sx1, 0, img_w)
	sy1 = clampi(sy1, 0, img_h)
	for y in range(sy0, sy1):
		for x in range(sx0, sx1):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var d := maxi(maxi(absi(ca.r8 - cb.r8), absi(ca.g8 - cb.g8)), absi(ca.b8 - cb.b8))
			var plx := (float(x) + 0.5 - ox) / s
			var ply := (float(y) + 0.5 - oy) / s
			var lx := plx - float(CROP_RECT.position.x)
			var ly := ply - float(CROP_RECT.position.y)
			var tx_lo := int(floor(lx - _TEXEL_EPS))
			var tx_hi := int(floor(lx + _TEXEL_EPS))
			var ty_lo := int(floor(ly - _TEXEL_EPS))
			var ty_hi := int(floor(ly + _TEXEL_EPS))
			var tie := tx_lo != tx_hi or ty_lo != ty_hi
			# 四角是否在裁切矩形内 / 是否水面。
			var in_all := true
			var in_any := false
			var w_all := true
			var w_any := false
			for txx in [tx_lo, tx_hi]:
				for tyy in [ty_lo, ty_hi]:
					var txv: int = int(txx)
					var tyv: int = int(tyy)
					var inside: bool = txv >= 0 and tyv >= 0 and txv < CROP_RECT.size.x and tyv < CROP_RECT.size.y
					in_all = in_all and inside
					in_any = in_any or inside
					var mw: bool = _mask_at(mask, txv, tyv)
					w_all = w_all and mw
					w_any = w_any or mw
			# 明确在裁切外（四角都不在矩形内）→ band。
			if not in_any:
				band_max = maxi(band_max, d)
				continue
			# 明确非水面（四角皆非水）。分数缩放时子层 LINEAR 会在水陆边界渗色，
			# 再检查映射点 ±1 纹素邻域：邻域内有水面则视为模糊带，不进 nonwater 硬门。
			if not w_any:
				var near_water := false
				var tx0: int = int(floor(lx))
				var ty0: int = int(floor(ly))
				var nx0 := tx0 - 1
				var nx1 := tx0 + 1
				var ny0 := ty0 - 1
				var ny1 := ty0 + 1
				if tie_aware:
					nx0 = tx_lo - 1; nx1 = tx_hi + 1; ny0 = ty_lo - 1; ny1 = ty_hi + 1
				for ny in range(ny0, ny1 + 1):
					for nx in range(nx0, nx1 + 1):
						if _mask_at(mask, nx, ny):
							near_water = true
							break
					if near_water:
						break
				if not near_water:
					nonwater_max = maxi(nonwater_max, d)
				continue
			# 明确水面且非平局 → 水面变化统计。
			if w_all and not tie:
				water_max = maxi(water_max, d)
				if d > 0:
					water_changed += 1
			# 水陆模糊 / 平局像素：不进 nonwater 硬门，也不要求变化。
	return [nonwater_max, water_max, water_changed, band_max]


## 与 verify_scale_linear.py offset_for 相同：裁切中心靠近视口中心，再加子像素小数。
func _offset_for(s: float, frac: Vector2) -> Vector2:
	var cx := float(CROP_RECT.position.x) + float(CROP_RECT.size.x) * 0.5
	var cy := float(CROP_RECT.position.y) + float(CROP_RECT.size.y) * 0.5
	return Vector2(floor(1672.0 * 0.5 - cx * s) + frac.x, floor(941.0 * 0.5 - cy * s) + frac.y)


func _apply_transform(s: float, offset: Vector2) -> void:
	scale_factor = s
	painting_offset = offset
	_painting.scale = Vector2(s, s)
	_painting.position = offset


func _frame_stats(n: int) -> Dictionary:
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	for _i in n:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - last) / 1000.0)
		last = now
	samples.sort()
	var total := 0.0
	for v in samples:
		total += v
	return {"mean_ms": snappedf(total / n, 0.01), "p50_ms": snappedf(samples[n / 2], 0.01),
		"p95_ms": snappedf(samples[int(n * 0.95)], 0.01), "max_ms": snappedf(samples[n - 1], 0.01)}


## 导出身份：web_export_check.sh 每次导出前写入 res://build_id.txt（不进仓库），随本次 PCK 打包。
## 探针只回报包内读到的值，不读页面地址，所以旧导出无法回显本轮身份。
func _read_build_id() -> String:
	if not FileAccess.file_exists("res://build_id.txt"):
		return ""
	return FileAccess.get_file_as_string("res://build_id.txt").strip_edges()


func _probe_transform_gates(mask: PackedByteArray, s: float, offset: Vector2) -> Dictionary:
	# 单变换硬门：非水面/矩形外 vs 原画 0；0↔TAU 0；strength0 vs 原画 0；半圈水面有变化。不做完整 10×5。
	_apply_transform(s, offset)
	var mat := _material()
	mat.set_shader_parameter("strength", 1.0)
	paused = true; reduced_motion = true; _apply_motion()
	var orig := await _grab()
	reduced_motion = false; _apply_motion()
	var res := {}
	for ph in [0.0, PI * 0.5, TAU]:
		phase = ph; _push_phase()
		res[str(snappedf(ph, 0.0001))] = _diff(await _grab(), orig, mask, s, offset.x, offset.y)
	phase = 0.0; _push_phase()
	var p0 := await _grab()
	phase = TAU; _push_phase()
	var p0_vs_tau := _diff(p0, await _grab(), mask, s, offset.x, offset.y)
	mat.set_shader_parameter("strength", 0.0)
	var s0 := _diff(await _grab(), orig, mask, s, offset.x, offset.y)
	mat.set_shader_parameter("strength", 1.0)
	var ok := true
	for k in res:
		var d: Array = res[k]
		ok = ok and d[0] == 0 and d[3] == 0
	var mid: Array = res[str(snappedf(PI * 0.5, 0.0001))]
	ok = ok and int(mid[2]) > 0
	ok = ok and p0_vs_tau[0] == 0 and p0_vs_tau[1] == 0 and p0_vs_tau[3] == 0
	ok = ok and s0[0] == 0 and s0[1] == 0 and s0[3] == 0
	return {
		"scale": s, "offset": [offset.x, offset.y], "ok": ok,
		"phase_vs_original": res, "phase0_vs_tau": p0_vs_tau, "strength0_vs_original": s0,
		"water_changed_mid": int(mid[2]),
	}


func _run_web_probe() -> void:
	var out := {"web": OS.has_feature("web"), "renderer": RenderingServer.get_video_adapter_name(),
		"vendor": RenderingServer.get_video_adapter_vendor(), "api": RenderingServer.get_video_adapter_api_version(),
		"window": DisplayServer.window_get_size(), "viewport": get_viewport().get_visible_rect().size,
		"base_sample_linear": _material().get_shader_parameter("base_sample_linear"),
		"build_id": _read_build_id()}
	var ok := DisplayServer.window_get_size() == Vector2i(1672, 941) and get_viewport().get_visible_rect().size == Vector2(1672, 941) and scale_factor == 1.0 and painting_offset == Vector2.ZERO
	var mask := _water_mask()
	var mat := _material()
	await _frames(60)
	paused = false; reduced_motion = false; _apply_motion()
	out["frames_running"] = await _frame_stats(300)
	reduced_motion = true; _apply_motion()
	out["frames_reduced"] = await _frame_stats(300)
	reduced_motion = false; _apply_motion()
	# ——— 1:1（既有路径，scale 1、偏移 0）———
	paused = true; reduced_motion = true; _apply_motion()
	var orig := await _grab()
	reduced_motion = false; _apply_motion()
	var res := {}
	for ph in [0.0, PI * 0.5, PI, PI * 1.5, TAU]:
		phase = ph; _push_phase()
		var img := await _grab()
		res[str(snappedf(ph, 0.0001))] = _diff(img, orig, mask)
	out["phase_vs_original"] = res
	phase = 0.0; _push_phase()
	var p0 := await _grab()
	phase = TAU; _push_phase()
	var pt := await _grab()
	out["phase0_vs_tau"] = _diff(p0, pt, mask)
	mat.set_shader_parameter("strength", 0.0)
	out["strength0_vs_original"] = _diff(await _grab(), orig, mask)
	mat.set_shader_parameter("strength", 1.0)
	for k in res:
		var d: Array = res[k]
		ok = ok and d[0] == 0 and d[3] == 0
	ok = ok and int(res[str(snappedf(PI * 0.5, 0.0001))][2]) > 0
	ok = ok and out["phase0_vs_tau"][1] == 0 and out["strength0_vs_original"][1] == 0 and out["strength0_vs_original"][0] == 0
	# 连续暂停 / 减少动态（与 --sequence-check 同一套 P/R 键路径，只比 phase 与可见性）。
	phase = 0.0; paused = false; reduced_motion = false; _apply_motion(); _push_phase()
	await _frames(30)
	var p_run := phase
	await _press(KEY_P)
	var p_pause := phase
	await _frames(30)
	var seq_ok := p_run > 0.0 and paused and phase == p_pause
	await _press(KEY_R)
	await _frames(30)
	seq_ok = seq_ok and reduced_motion and not _crop.visible and phase == p_pause
	var red_img := await _grab()
	var rd := _diff(red_img, orig, mask)
	seq_ok = seq_ok and rd[0] == 0 and rd[1] == 0 and rd[3] == 0
	await _press(KEY_R)
	await _press(KEY_P)
	await _frames(30)
	seq_ok = seq_ok and not paused and _crop.visible and phase != p_pause
	out["sequence_ok"] = seq_ok
	ok = ok and seq_ok
	# ——— 缩放/子像素小子集（对齐桌面硬门，非完整 10×5）———
	# 关闭 WEBPROBE_SCALE=0 可跳过（web_export_check.sh 默认可开）。
	var scale_cases: Array = []
	var do_scale := true
	if OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval("window.location.search", true))
		if q.contains("noscale=1"):
			do_scale = false
	if do_scale:
		var cases: Array = [
			[0.75, _offset_for(0.75, Vector2.ZERO)],
			[2.0, _offset_for(2.0, Vector2(0.37, 0.61))],
		]
		for c in cases:
			var tr: Dictionary = await _probe_transform_gates(mask, float(c[0]), c[1] as Vector2)
			scale_cases.append(tr)
			ok = ok and bool(tr["ok"])
		# 恢复 1:1，避免后续误用。
		_apply_transform(1.0, Vector2.ZERO)
	out["scale_subpixel"] = scale_cases
	out["scale_subpixel_ok"] = (not do_scale) or (scale_cases.size() == 2 and bool(scale_cases[0]["ok"]) and bool(scale_cases[1]["ok"]))
	out["ok"] = ok
	print("WEBPROBE ", JSON.stringify(out))
	if not OS.has_feature("web"):
		get_tree().quit(0 if ok else 1)


## ——— 完整 10×5 缩放/子像素矩阵（Web ?matrix=1；桌面 --web-matrix DIR）———
## 与 verify_scale_linear.py 同一矩阵：缩放 0.5/0.75/1.0/1.5/2.0 × 偏移（居中整数 / +0.37,+0.61）= 10 组变换，
## 每组 phase 0、π/2、π、3π/2、TAU = 50 组合。每组变换另取 R（减少动态原画）、S0（strength 0）、
## NL（strength 1e-4 默认线性底图）、NZ（strength 1e-4 + base nearest）。
## 每帧都是本页真实画布读回，原样编码 PNG（无损），浏览器内算 SHA256，再同步 POST 给本轮自持端口的探针服务器；
## 服务器复算 SHA256，不一致拒收。离线 web_matrix_verdict.py 再按桌面判据逐 PNG 复核。
## 仍只是隔离候选；SwiftShader 帧不代表真实 GPU / 手机 / 宿主。
const MATRIX_SCALES := [0.5, 0.75, 1.0, 1.5, 2.0]
const MATRIX_SUBPIX := [Vector2(0.0, 0.0), Vector2(0.37, 0.61)]


func _sha256(buf: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(buf)
	return ctx.finish().hex_encode()


func _matrix_js_init() -> void:
	if not OS.has_feature("web"):
		return
	# 同步 XHR：上传完成（服务器复核 SHA 并落盘）才继续下一帧，保证顺序与完整性。
	JavaScriptBridge.eval("""
window.__wm_upload = function(name, sha, bid, b64) {
  var bin = atob(b64); var u = new Uint8Array(bin.length);
  for (var i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i);
  var x = new XMLHttpRequest();
  x.open('POST', '/__upload?name=' + encodeURIComponent(name) + '&sha256=' + sha + '&build_id=' + bid, false);
  x.send(u);
  return x.status;
};
window.__wm_env = function() {
  var c = document.createElement('canvas'); var gl = c.getContext('webgl2');
  var r = {user_agent: navigator.userAgent, device_pixel_ratio: window.devicePixelRatio};
  if (gl) {
    r.gl_version = gl.getParameter(gl.VERSION);
    r.gl_shading = gl.getParameter(gl.SHADING_LANGUAGE_VERSION);
    var e = gl.getExtension('WEBGL_debug_renderer_info');
    if (e) { r.unmasked_vendor = gl.getParameter(e.UNMASKED_VENDOR_WEBGL); r.unmasked_renderer = gl.getParameter(e.UNMASKED_RENDERER_WEBGL); }
  }
  var g = document.getElementById('canvas');
  if (g) { r.canvas = [g.width, g.height]; r.canvas_css = [g.clientWidth, g.clientHeight]; }
  return JSON.stringify(r);
};
""", true)


## 返回 {"name","sha256","bytes","status"}；status 200 = 服务器复核 SHA 一致并已落盘（桌面为写文件结果 0）。
func _emit(name: String, data: PackedByteArray) -> Dictionary:
	var sha := _sha256(data)
	var status := -1
	if OS.has_feature("web"):
		var win = JavaScriptBridge.get_interface("window")
		status = int(win.__wm_upload(name, sha, _build_id, Marshalls.raw_to_base64(data)))
	else:
		var f := FileAccess.open(_web_matrix_dir.path_join(name), FileAccess.WRITE)
		if f != null:
			f.store_buffer(data)
			f.close()
			status = 200
	return {"name": name, "sha256": sha, "bytes": data.size(), "status": status}


## 整帧中 bbox 以外的像素是否逐字节相同（原生 PackedByteArray 比较，避免逐像素脚本循环）；
## 不同时再逐像素求最大通道差。返回 [max_diff, differing_rows]。
func _outside_bbox_max(a: Image, b: Image, bbox: Rect2i) -> Array:
	var w := a.get_width()
	var h := a.get_height()
	var da := a.get_data()
	var db := b.get_data()
	var maxd := 0
	var rows := 0
	for y in h:
		var segs: Array = []
		if y < bbox.position.y or y >= bbox.end.y:
			segs.append([0, w])
		else:
			segs.append([0, bbox.position.x])
			segs.append([bbox.end.x, w])
		for sg in segs:
			var x0: int = sg[0]
			var x1: int = sg[1]
			if x1 <= x0:
				continue
			var o0 := (y * w + x0) * 4
			var o1 := (y * w + x1) * 4
			if da.slice(o0, o1) == db.slice(o0, o1):
				continue
			rows += 1
			for x in range(x0, x1):
				var ca := a.get_pixel(x, y)
				var cb := b.get_pixel(x, y)
				maxd = maxi(maxd, maxi(maxi(absi(ca.r8 - cb.r8), absi(ca.g8 - cb.g8)), absi(ca.b8 - cb.b8)))
	return [maxd, rows]


func _scan_bbox(s: float, offset: Vector2, w: int, h: int) -> Rect2i:
	# 与 _diff 扫描范围一致：裁切矩形映射到屏幕再外扩 3 px。
	var x0 := clampi(int(floor(offset.x + float(CROP_RECT.position.x) * s - 3.0)), 0, w)
	var y0 := clampi(int(floor(offset.y + float(CROP_RECT.position.y) * s - 3.0)), 0, h)
	var x1 := clampi(int(ceil(offset.x + float(CROP_RECT.position.x + CROP_RECT.size.x) * s + 3.0)), 0, w)
	var y1 := clampi(int(ceil(offset.y + float(CROP_RECT.position.y + CROP_RECT.size.y) * s + 3.0)), 0, h)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)


func _count_changed(a: Image, b: Image, bbox: Rect2i) -> int:
	var n := 0
	for y in range(bbox.position.y, bbox.end.y):
		for x in range(bbox.position.x, bbox.end.x):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca.r8 != cb.r8 or ca.g8 != cb.g8 or ca.b8 != cb.b8:
				n += 1
	return n


func _full_max(a: Image, b: Image) -> int:
	if a.get_data() == b.get_data():
		return 0
	var r: Array = _outside_bbox_max(a, b, Rect2i(0, 0, 0, 0))
	return int(r[0])


func _run_web_matrix() -> void:
	_build_id = _read_build_id()
	_matrix_js_init()
	if not OS.has_feature("web"):
		DirAccess.make_dir_recursive_absolute(_web_matrix_dir)
	var env := {}
	if OS.has_feature("web"):
		env = JSON.parse_string(str(JavaScriptBridge.get_interface("window").__wm_env()))
	var out := {"web": OS.has_feature("web"), "build_id": _build_id,
		"renderer": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"api": RenderingServer.get_video_adapter_api_version(), "browser_env": env,
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y],
		"engine": Engine.get_version_info().get("string", ""),
		"scales": MATRIX_SCALES, "subpix": [[0.0, 0.0], [0.37, 0.61]],
		"phases": [0.0, PI * 0.5, PI, PI * 1.5, TAU]}
	var size_ok := DisplayServer.window_get_size() == Vector2i(1672, 941) and get_viewport().get_visible_rect().size == Vector2(1672, 941)
	out["size_ok"] = size_ok
	out["near_water_rule"] = "tie_aware: nonwater gate excludes px whose tie corners lo/hi have water within 1 texel (chessboard)"
	var mask := _water_mask()
	var mat := _material()
	await _frames(60)
	var combos: Array = []
	var transforms: Array = []
	var files: Array = []
	var uploads_ok := true
	var n_ok := 0
	for s in MATRIX_SCALES:
		for frac in MATRIX_SUBPIX:
			var off := _offset_for(float(s), frac)
			var tag := "s%s_o%s" % [str(s), "0.0" if frac.x == 0.0 else "0.37"]
			_apply_transform(float(s), off)
			mat.set_shader_parameter("base_sample_linear", true)
			mat.set_shader_parameter("strength", 1.0)
			paused = true; reduced_motion = true; _apply_motion()
			phase = 0.0; _push_phase()
			var R := await _grab()
			var fr := _emit("R_%s.png" % tag, R.save_png_to_buffer()); files.append(fr)
			reduced_motion = false; _apply_motion()
			mat.set_shader_parameter("strength", 0.0)
			var S0 := await _grab()
			var fs := _emit("S0_%s.png" % tag, S0.save_png_to_buffer()); files.append(fs)
			var s0_full := _full_max(S0, R)
			mat.set_shader_parameter("strength", 0.0001)
			var NL := await _grab()
			files.append(_emit("NL_%s.png" % tag, NL.save_png_to_buffer()))
			var nl_d := _diff(NL, R, mask, float(s), off.x, off.y, true)
			mat.set_shader_parameter("base_sample_linear", false)
			var NZ := await _grab()
			files.append(_emit("NZ_%s.png" % tag, NZ.save_png_to_buffer()))
			var nz_d := _diff(NZ, R, mask, float(s), off.x, off.y, true)
			mat.set_shader_parameter("base_sample_linear", true)
			mat.set_shader_parameter("strength", 1.0)
			var bbox := _scan_bbox(float(s), off, R.get_width(), R.get_height())
			var crops := {}
			var phase_rows: Array = []
			for ph in [0.0, PI * 0.5, PI, PI * 1.5, TAU]:
				phase = ph; _push_phase()
				var C := await _grab()
				var pt := "%.4f" % ph
				var fc := _emit("C_%s_%s.png" % [tag, pt], C.save_png_to_buffer()); files.append(fc)
				crops[pt] = C
				var d := _diff(C, R, mask, float(s), off.x, off.y, true)
				var ob := _outside_bbox_max(C, R, bbox)
				var a_ok: bool = int(d[0]) == 0 and int(d[3]) == 0 and int(ob[0]) == 0
				phase_rows.append({"phase": pt, "png": fc["name"], "sha256": fc["sha256"],
					"nonwater_max": d[0], "water_max": d[1], "water_changed": d[2], "band3_max": d[3],
					"outside_scan_max": ob[0], "a_ok": a_ok})
			var loop := _full_max(crops["0.0000"], crops["6.2832"])
			# 半圈变化：与 verify_scale_linear.py 相同，数整帧任一通道有差的像素（×0.5 整数偏移时像素中心全落在纹素边界，
			# 「明确水面且非平局」为空集，所以不用 _diff 的 water_changed 作门）。bbox 外已由 outside_scan 证明与 R 相同。
			var half := _count_changed(crops["3.1416"], crops["0.0000"], bbox)
			var t_ok: bool = s0_full == 0 and int(nl_d[0]) == 0 and int(nl_d[3]) == 0 and int(nz_d[0]) == 0 and int(nz_d[3]) == 0 and loop == 0 and half > 0
			transforms.append({"tag": tag, "scale": s, "subpix": [frac.x, frac.y], "offset": [off.x, off.y],
				"strength0_vs_R_full_max": s0_full, "NL_vs_R": nl_d, "NZ_vs_R": nz_d,
				"phase0_vs_tau_full_max": loop, "half_cycle_changed_px": half, "ok": t_ok})
			for row in phase_rows:
				var c_ok: bool = bool(row["a_ok"]) and t_ok and size_ok
				row["tag"] = tag
				row["transform_ok"] = t_ok
				row["ok"] = c_ok
				if c_ok:
					n_ok += 1
				combos.append(row)
			print("WEBMATRIX-PROGRESS ", tag, " t_ok=", t_ok, " combos_ok=", n_ok)
	_apply_transform(1.0, Vector2.ZERO)
	for f in files:
		uploads_ok = uploads_ok and int(f["status"]) == 200
	out["transforms"] = transforms
	out["combos"] = combos
	out["files"] = files
	out["n_combos"] = combos.size()
	out["n_ok"] = n_ok
	out["uploads_ok"] = uploads_ok
	out["matrix_ok"] = size_ok and uploads_ok and combos.size() == 50 and n_ok == 50
	out["ok"] = out["matrix_ok"]
	var js := JSON.stringify(out, "  ", false).to_utf8_buffer()
	var res_up := _emit("webmatrix_result.json", js)
	# 控制台只打一行短摘要；完整结果以上传的 JSON 为准（摘要带其 SHA256，供 verdict 互证）。
	print("WEBMATRIX ", JSON.stringify({"ok": out["ok"], "build_id": _build_id, "n_combos": combos.size(),
		"n_ok": n_ok, "uploads_ok": uploads_ok, "result_sha256": res_up["sha256"], "result_status": res_up["status"]}))
	if not OS.has_feature("web"):
		get_tree().quit(0 if bool(out["ok"]) else 1)
