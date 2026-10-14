# 绘本风格溪流隔离流向候选（#749）

Agent-ID: GROK-BUILD

本目录为**溪流（近郊小路左下溪床）隔离流向候选**，平行于已合入的雾体样片 `art/concepts/env_fx_mist_20261014/`（PR #803）。  
**不覆盖任何运行时资源**，不接入主游戏动态，不改现有生产 shader / 场景 / `.png.import`。仍只是候选，不关闭 #749，也不当作美术验收。

底图只读 `assets/holiday/exploration/near_path_02.webp`（1672×941），复制进本目录预览，不改源文件。

## 范围与限制

| 做了 | 没做 |
|---|---|
| 沿溪床弯道的 RG 流向图，水纹与短笔触只往下游走 | 未接线到 `shaders/near_path_motion.gdshader` 或任何生产场景 |
| 双相位采样淡入淡出；纹样周期与一圈位移成整数倍，首尾相接 | 未做流体模拟、全幅视频循环或生产路线 |
| 岸、桥面、石头、纸边逐像素不动（脚本打印 protect_max） | 未改 `assets/holiday/**`、`shaders/` 正式资源 |
| 可复现生成脚本 + Godot 4.x 隔离预览工程 | 未宣称美术验收完成，未测量 Web/GPU 成本 |
| PNG 序列 / GIF / mp4，供无 Godot 时看连续流向 | 未做晴阴昼夜、照片回放或竖屏生产适配 |

生产水面 `shaders/near_path_motion.gdshader` 用正弦值去推 UV，亮暗会把像素推去又推回。本候选不改那个文件。这里的位移是沿流向的采样相位，亮条一直往下游走。

## 目录

- `flow_map.png`：RG 单位流向（128 为零，大于 128 为 +X / +Y），B 疏密，A 水面
- `mask_water.png`：软水面（白=可动）
- `mask_protect.png`：硬保护（白=必须与原画一致）
- `coord_sn.png`：R 为弧长相对 `TRAVEL_PX` 的小数相位，G 为横向
- `ripple_tile.png`：两层水纹（R/G），横向一个周期
- `water_detail.png`：只含水色的高频笔触，岸上是中性灰
- `generate_stream_flow_anim.py`：可复现帧生成；`--export-preview` 写出 Godot 贴图
- `anim_frames/`：40 帧循环 + `stream_static_low_motion.png`
- `sample_frames/`：00/10/20/30 + static 代表帧
- `stream_flow_loop.gif` / `stream_flow_loop_10s.mp4`：循环预览
- `godot_preview/`：可直接打开的 Godot 工程（见 `godot_preview/README_run.md`）

## 技术要点（对齐 #749 溪流）

- **下游**：从桥下出水口走向画面前景（+Y），中心线跟着冷色水面弯，单步限制横向，避免跳进石滩。切线的 Y 分量保持为正，整段不会掉头向上游。
- **流向图**：每个水面像素取最近的中心线段切线，再在水面内平滑。窄处疏密更高，宽处更轻；疏密不随时间来回，所以不会整条溪一起闪。
- **双相位**：同一条偶数圈亮带采两次，相位差半圈。三角权重在某一层回到起点时为 0，笔触重置发生在看不见的那一层。偶数圈（一圈两道、四道）错开半个周期后与自身重合，所以淡入淡出不会把亮带抵消成原地闪，也不会在半圈往上游退。半个 `TRAVEL_PX` 正好走完一条波长，画面接上起点。
- **整数周期**：水纹贴图横向一圈等于 `TRAVEL_PX`（96 像素弧长）。phase 0 与 phase 1 落在同一纹样上。
- **笔触**：高频只从水色里取，位移约 12 像素并夹在 ±8 电平，避免亮沫盖到暗水上闪成硬斑，也避免采样越界拖进岸色。
- **保护**：桥面矩形与雾体候选相同 `(150, 468, 430, 552)`；纸边外圈 28 像素；石头与绿岸在蒙版里挖掉。这些像素不进混合，protect_max 应为 0。
- **低动效静帧**：phase 0、强度 0.20，仍是一幅完成的水彩，不是抽掉水面的线框。

## 复现命令（仓库根）

```bash
python3 art/concepts/env_fx_stream_20261014/generate_stream_flow_anim.py --frames 40 --export-preview

ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -vf "scale=1280:-2" \
  art/concepts/env_fx_stream_20261014/stream_flow_loop_10s.mp4

ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -vf "fps=5,scale=836:-1:flags=lanczos,palettegen=stats_mode=full" /tmp/stream_pal.png
ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -i /tmp/stream_pal.png \
  -lavfi "fps=5,scale=836:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4" \
  art/concepts/env_fx_stream_20261014/stream_flow_loop.gif
```

40 帧 @ 5fps = 8 秒一整圈（文件名沿用雾体候选的 `_10s` 叫法）。GIF 宽 836。看的时候盯左下溪床，不要看整幅的平均亮度。

```bash
godot --path art/concepts/env_fx_stream_20261014/godot_preview --resolution 1280x720
# 或
godot --path art/concepts/env_fx_stream_20261014/godot_preview --headless -- --self-check
```

底图只**复制**进 `godot_preview/textures/`，不修改 `assets/holiday/exploration/near_path_02.webp`。

## 请审阅

请 ART-DIRECTOR / CODEX-LEAD 看 `stream_flow_loop.gif`（或 mp4）时核对这几件事：

- 亮条是否沿着弯道一直往下游（画面下方 / 前景）走，循环接缝没有整段倒退。
- 这不是生产 shader 那种左右来回晃：同一条亮纹不应在半圈时走回上游。
- 草地、小路、木屋、桥面、石头、纸边应稳住。脚本会打印 `protect_max`，以及 bridge / paper / meadow 的最大差。
- 水纹应是低对比水彩，不要霓虹青、不要一块矩形贴片。
- 低动效静帧 `stream_static_low_motion.png` 应仍像一幅画完的原画。

仍只是候选。方向确认之前不接入运行时。
