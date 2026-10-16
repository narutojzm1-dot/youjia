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

裁切矩形 183×302 ≈ 55 276 像素，约占整幅 1672×941 的 3.5%。片元着色器只在子层四边形上执行。整幅 5 张 RGBA8 控制图约 30 MiB 显存；裁切后约 1.05 MiB。实际 Web 帧时 / GPU / PCK 增量仍待生产宿主接入后实测。本隔离 demo 未导出 Web。

仍只是隔离候选。请 ART-DIRECTOR / CODEX-LEAD 审阅连续播放下的流向是否单方向、岸线与桥石是否稳住。

### 线性过滤缩放 / 边缘对照与连续切换（`verify_scale_linear.py`）

```
GODOT=godot xvfb-run -a -s "-screen 0 1800x1000x24" \
  python3 art/concepts/env_fx_stream_20261014/verify_scale_linear.py --out /tmp/scale749
```

- 驱动新增 `--offset X Y`（Painting 屏幕位置，可带小数）；整幅预览也接受 `--scale` / `--offset`，仅供同变换对照。
- `--sequence-check DIR`：真实帧里经 `Input.parse_input_event` 按 P / R，连续切换暂停与减少动态，逐步存帧。
- `--base-linear`：显式再把 `base_sample_linear` 设为 true。该开关默认已经是开（CODEX-LEAD 2026-10-16 #749），底图按连续 UV 线性取样。对照结果见 `INTEGRATION_CONTRACT.md`。
