# 溪流流向隔离预览（Godot 4.x）

只打开本目录的 `project.godot`。这是 #749 溪流候选预览，不加载主游戏，不改 `assets/holiday` 运行时资源、生产场景、存档或导航。

场景 `stream_flow_preview.tscn` 已经接好：

- 底图 `textures/near_path_base.png`（从已批准 `assets/holiday/exploration/near_path_02.webp` 复制，1672×941）
- 流向 `textures/flow_map.png`（RG 为单位流向，128 为零；+G 是画面下方，即下游）
- 弧长坐标 `textures/coord_sn.png`（R 为沿溪床的周期相位，G 为横向）
- 水纹 `textures/ripple_tile.png`（R/G 同一层，横向一整圈；相位直接平移）
- 笔触 `textures/water_detail.png`（只含水色高频，岸上为中性灰）
- 次级 `textures/secondary_map.png`（R 横纹相位，G 侧流相位，B 涡流角度，A 宽水面）与 `textures/secondary_weight.png`（R 横纹、G 侧流、B 涡流权重）
- 着色器 `stream_flow.gdshader` 的振幅、位移夹紧、双相位权重和次级水流与 `generate_stream_flow_anim.py` 相同

打开后 phase 自动从 0 走到 2π，一圈 8 秒（与 40 帧 @ 5fps 的 PNG 序列同一相位）。溪水里的亮条沿弯道往下游走。宽水面另有侧流、横向涟漪和轻涡流；草地、桥面、石头和纸边保持不动。

本环境若没有 Godot 可执行文件，用同目录上一级的 GIF / mp4 审阅即可。有 Godot 4.7 时再打开本工程。

## 启动命令

在仓库根目录执行。`godot` 换成本机 Godot 4.7 可执行文件名即可。

横屏（与底图同比例）：

```
godot --path art/concepts/env_fx_stream_20261014/godot_preview --resolution 1280x720
```

竖屏窗口（整幅按比例缩进，上下留边）：

```
godot --path art/concepts/env_fx_stream_20261014/godot_preview --resolution 390x844
```

## 暂停和低动效

- `P` 或空格，或「暂停」按钮：停止 phase 累加。
- `L`，或「低动效」按钮：速度 ×0.25，仍往下游走，不改成左右摆。
- 两开关同时开时，暂停优先。

`strength` 默认 1。低动效静帧是生成脚本写出的 `stream_static_low_motion.png`，不是把着色器强度改成 0。

## 重新导出贴图

```
python3 art/concepts/env_fx_stream_20261014/generate_stream_flow_anim.py --frames 40 --export-preview
```

## 本机自检（本环境有 Godot 4.7 时）

```
godot --path art/concepts/env_fx_stream_20261014/godot_preview --headless -- --self-check
```

## 裁切子层 demo（183×302，仍只是候选）

```
godot --path art/concepts/env_fx_stream_20261014/godot_preview res://stream_flow_crop_demo.tscn --resolution 1280x720
```

`P`/空格暂停，`R` 切换减少动态（撤掉子层，只剩原画）。无头自检：

```
godot --path art/concepts/env_fx_stream_20261014/godot_preview --headless res://stream_flow_crop_demo.tscn -- --self-check
```

整幅版与裁切版逐像素对照（需要显示器或 xvfb-run）：

```
GODOT=godot python3 art/concepts/env_fx_stream_20261014/verify_crop_render.py --out /tmp/crop749
```

### 线性过滤与缩放

- 着色器中 `ripple_tile` 与 `water_detail` 使用 `filter_linear`，控制图保持 `filter_nearest`。
- `base_sample_linear` **默认开**（CODEX-LEAD 2026-10-16 11:47 CST，#749）：底图按连续 UV 线性取样，匹配宿主线性原画。控制图仍 nearest。保护区、`strength 0`、减少动态回原画保持。
- 驱动支持 `--scale <float>` 或键盘 `[` `]` 调整 Painting 缩放（0.25–3.0），用于观察不同分辨率下的采样行为。shader 内部仍按裁切像素坐标计算，不随 scale 改变逻辑。
- 示例：`godot --path art/concepts/env_fx_stream_20261014/godot_preview res://stream_flow_crop_demo.tscn -- --scale 1.5`

### Web 成本估算（隔离，非实测）

裁切矩形 183×302 ≈ 55 276 像素，约占整幅 1672×941 的 3.5%。片元着色器只在子层四边形上执行。整幅 5 张 RGBA8 控制图约 30 MiB 显存；裁切后约 1.05 MiB。隔离 Web 导出与 `?probe=1`（含缩放/子像素小子集）见仓库旁 `web_export_check.sh` 与 `INTEGRATION_CONTRACT.md`。 真实玩家浏览器 / 手机 / DPR 帧时仍待生产宿主接入后实测。

仍只是隔离候选。请 ART-DIRECTOR / CODEX-LEAD 审阅连续播放下的流向是否单方向、岸线与桥石是否稳住。

### 线性过滤缩放 / 边缘对照与连续切换（`verify_scale_linear.py`）

```
GODOT=godot xvfb-run -a -s "-screen 0 1800x1000x24" \
  python3 art/concepts/env_fx_stream_20261014/verify_scale_linear.py --out /tmp/scale749
```

- 驱动新增 `--offset X Y`（Painting 屏幕位置，可带小数）；整幅预览也接受 `--scale` / `--offset`，仅供同变换对照。
- `--sequence-check DIR`：真实帧里经 `Input.parse_input_event` 按 P / R，连续切换暂停与减少动态，逐步存帧。
- `--base-linear`：显式再把 `base_sample_linear` 设为 true。该开关默认已经是开（CODEX-LEAD 2026-10-16 #749），底图按连续 UV 线性取样。对照结果见 `INTEGRATION_CONTRACT.md`。
- `--base-nearest`：强制 `base_sample_linear=false`（仅 legacy 与整幅 nearest 预览对照；不改默认）。

### 隔离 Web 导出实测（`web_export_check.sh`，回应 CODEX-LEAD 11:47 CST 回执）

```
GODOT=godot CHROME=google-chrome bash art/concepts/env_fx_stream_20261014/web_export_check.sh /tmp/web749
```

- `export_presets.cfg`：只导出 `stream_flow_crop_demo.tscn` 及依赖（`export_filter="scenes"`），模板为官方同版 `web_nothreads_release.zip`（`custom_template` 留空，装到 `~/.local/share/godot/export_templates/4.7.2.stable/`）。导出物写 `/tmp`，不进仓库。
- `project.godot` 加 `run/main_scene.web`，Web 下主场景是裁切 demo；桌面打开仍是整幅预览。
- 驱动 `--web-probe`（Web 页面 `?probe=1`）：读回本页真实画布；先跑 1:1（1672×941、scale 1、偏移 0）像素/暂停，再默认跑缩放/子像素小子集（0.75 居中、2.0+0.37/0.61），硬门对齐桌面线性对照。 URL 加 `noscale=1` 或脚本 `WEBPROBE_SCALE=0` 可跳过缩放子集。只打印一行 `WEBPROBE {...}`，不存文件。
- 实测在 `435cc826`（`base_sample_linear` 已默认开）之上重跑；1:1 下默认与关闭逐像素相同（见 `INTEGRATION_CONTRACT.md`），所以本表也覆盖新默认。
- 版本身份（回应 CODEX-LEAD 对 `b36731af` 的复核）：
  - 服务器改用同目录 `web_probe_server.py`：它自己 `bind(127.0.0.1, 0)` 并一直持有该监听 socket，把实际端口写进 `$OUT/server.port`，没有先探端口再交给另一进程的窗口；`GET /__probe_server_id` 回本轮随机 id，脚本只在 id 相符且子进程仍活着时才算就绪，浏览器跑完后再查一次子进程。所有应答带 `Cache-Control: no-store`。
  - 去掉从页面地址反射的 nonce。脚本每次导出前把随机 `build_id` 写进 `godot_preview/build_id.txt`（`.gitignore` 忽略，导出后即删），`export_presets.cfg` 的 `include_filter="build_id.txt"` 把它打进本次 PCK；探针从包内 `res://build_id.txt` 读回并报告，脚本要求与本轮值一致，否则判失败。
  - 反证：把上一次导出复制出来单独服务，并在地址里塞入新的随机值，探针仍报告该旧包里的旧 `build_id`，不会回显地址，所以旧导出过不了本轮校验。
