# #749 启动帧核对（2026-10-17，GROK-BUILD）

Agent-ID: GROK-BUILD。仅隔离预览 `godot_preview/` 的录制行为核对；不是美术验收、不是宿主接线、不是 GPU/手机性能。
环境：作者侧 box，Godot 4.7.2.stable、xvfb + Mesa llvmpipe 软件 GL，Movie Maker `--fixed-fps 30`。

## 结论

(a)（原速录屏第 1 圈第 2–4 帧与后面各圈最多差 3 个电平）和 (b)（`--toggle-sequence` 首帧 delta 0.025）是**同一个原因**：
Godot 主循环 `MainTimerSync` 的 **physics jitter fix**（项目默认 `physics/common/physics_jitter_fix = 0.5`，`physics_ticks_per_second = 60`）。
在 Movie Maker 固定 30fps 下，引擎把每帧请求的 1/30 秒按物理步长（1/60）对齐并限幅在 ±0.5×1/60 = ±1/120 秒内；
启动时物理步数历史还没填满，前 6 帧的 `_process(delta)` 不均匀，之后才稳定为精确 1/30。

不是着色器/纹理预热：同一工程只改这一项设置后，第 0 帧起就与第 2 圈逐像素一致（见 B/C）。

## 实测（`analyze_startup.py`，270 帧 = 第 1 圈 + 第 2 圈前 30 帧）

| 情况 | override | 前几帧 delta×60 | 非 1/30 的帧 | 累计时间偏差 | 第 1 圈 vs 第 2 圈 max / 有差帧 |
|---|---|---|---|---|---|
| A 默认 | 无 | 1.5, 2, 2.5, 1.75, 1.8, 1.95, 2, 2… | 0, 2, 3, 4, 5 | −1/120 s（−8.333 ms，之后恒定） | 3 / [2, 3, 4] |
| B | `physics_jitter_fix=0.0` | 全部 2 | 无 | 0 | 0 / [] |
| C | `physics_ticks_per_second=30` | 全部 2 | 无 | 0 | 0 / [] |

A 逐帧（phase 由驱动按实际 delta 累加，第 k+240 帧已处于稳态）：

| 帧 | delta | 相对稳态的时间差 | 第 1 圈 vs 第 2 圈 phase 差 (rad) | 像素 max / 变化像素 |
|---|---|---|---|---|
| 0 | 0.025 | 0 | ~2e-14 | 0 / 0 |
| 1 | 1/30 | 0 | ~2e-14 | 0 / 0 |
| 2 | 0.041667 | 8.333 ms | 6.545e-3 | 3 / 2910 |
| 3 | 0.029167 | 4.167 ms | 3.272e-3 | 2 / 1990 |
| 4 | 0.03 | 0.833 ms | 6.545e-4 | 2 / 391 |
| 5 起 | 0.0325，之后 1/30 | 0 | ~2e-14 | 0 / 0 |

解释：第 0 帧被限幅成 1/30 − 1/120 = 0.025，欠下的 1/120 秒此后一直留在 `time_deficit` 里（|deficit| ≤ jitter_fix × 物理步长），
所以从第 5 帧起整条时间线恒定落后帧号/30 恰好 1/120 秒——这对所有圈都一样，故稳态循环 0 差；
第 0、1 帧的累计偏差也正好是 −1/120，所以和稳态同位帧一致；只有第 2、3、4 帧在过渡中累计偏差分别是 0 / −4.167 ms / −7.5 ms，与稳态 −8.333 ms 不同，
phase 差越大像素差越多（2910 > 1990 > 391），与此前报告的「第 2 帧 2910 像素」一致。

附带：原 1200 帧录屏报告的全片相邻帧水面差极值 0.9505 / 0.6565 也来自这里（A 的 1→2、3→4 两步）；B 同段为 0.7596 / 0.731，
B 全 270 帧范围 0.6998–0.8963。

(b) 补正：此前 README 写「首帧 0.025，之后都是 1/30」不完整——实测第 0、2、3、4、5 帧都不是 1/30（第 1 帧恰好是），第 6 帧起才全是 1/30。
`verify_toggle_sequence.py` 按每帧实际 delta 算期望步长，所以原结论不受影响；默认配置重跑仍 `ok=true`，
B 配置（jitter fix 0）下 `--toggle-sequence` 重录 360 帧（D）：首帧 delta = 1/30、360 帧无一帧非 1/30，`verify_toggle_sequence.py` ok=true（见 `verify_toggle_D_jitterfix0.txt`、`toggle_seq_D_jitterfix0.jsonl`）。

## 是否改代码

不改。驱动用真实 delta 累加 phase 是预期行为，这个启动过渡来自引擎主循环，不是 shader 或驱动逻辑错误；1/120 秒（≈0.0065 rad）的偏移肉眼不可见。
如果以后录制需要「phase 严格等于帧号/30」，可在 `/tmp` 临时副本里加 `override.cfg`（B 或 C 任一，均实测 0 差），不必改 `godot_preview/project.godot` 默认值。
宿主运行时是否受同样的启动过渡影响未在本次范围内（只核对隔离预览录制）。

引擎源码出处：`main/main_timer_sync.cpp` 的 `MainTimerSync::advance_checked`（固定 fps 时 `p_process_step = 1.0 / fixed_fps`，
`max_clock_deviation = physics_jitter_fix * p_physics_step` 限幅，`time_deficit` 结转；`typical_physics_steps` 初值 0,1,2…）。
源码是在 godotengine/godot 4.5-stable 上读的；4.7.2 行为由上表实测。

## 文件

- `delta_log.gd`：临时 autoload，每帧打印 `DELTA_LOG`（delta、驱动 phase、物理帧数），process_priority 排在驱动之后。只经 override.cfg 挂到 /tmp 副本。
- `run_case.sh`：复制 `godot_preview/` 到 `/tmp/startup749/<name>/proj`，写 override.cfg，按 README 同参数 Movie Maker 录 N 帧。
- `analyze_startup.py`：逐帧对照第 k 帧与 k+240 帧像素差和 phase 差，输出 `startup_cases.json`。
- `override_*.cfg`、`movie_log_*.txt`、`delta_log_*.jsonl`：三种情况的覆写、录制日志与每帧原始输出。
- `verify_realtime_subset_270.txt`：既有 `verify_realtime_movie.py --expect-frames 270` 对 A/B/C 的原始输出（均 ok=true；A 的 first_cycle 仍 [2,3,4]，B/C 为 []）。
- `diff_x80_A_f0002_vs_f0242_crop.png`：A 第 2 帧 vs 第 242 帧差（×80，左下溪床裁切 x 60–480、y 470–830），只在水面细线。
- 270/360 张原 PNG 未入库，可按命令确定性重录。
