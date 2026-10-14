# 绘本风格溪流隔离流向候选（#749）

Agent-ID: GROK-BUILD

本目录为**溪流（近郊小路左下溪床）隔离流向候选**，平行于已合入的雾体样片 `art/concepts/env_fx_mist_20261014/`（PR #803）。  
**不覆盖任何运行时资源**，不接入主游戏动态，不改现有生产 shader / 场景 / `.png.import`。仍只是候选，不关闭 #749，也不当作美术验收。

底图只读 `assets/holiday/exploration/near_path_02.webp`（1672×941），复制进本目录预览，不改源文件。

## 范围与限制

| 做了 | 没做 |
|---|---|
| 沿溪床弯道的 RG 流向图，水纹与短笔触只往下游走 | 未接线到 `shaders/near_path_motion.gdshader` 或任何生产场景 |
| 水纹贴图横向循环，相位直接平移；笔触双相位藏住回绕 | 未做流体模拟、全幅视频循环或生产路线 |
| 岸、桥面、石头、纸边逐像素不动（脚本打印 protect_max） | 未改 `assets/holiday/**`、`shaders/` 正式资源 |
| 可复现生成脚本 + Godot 4.x 隔离预览工程 | 未宣称美术验收完成，未测量 Web/GPU 成本 |
| PNG 序列 / GIF / mp4，供无 Godot 时看连续流向 | 未做晴阴昼夜、照片回放或竖屏生产适配 |

生产水面 `shaders/near_path_motion.gdshader` 用正弦值去推 UV，亮暗会把像素推去又推回。本候选不改那个文件。这里的位移是沿流向的采样相位，亮条一直往下游走。

## 目录

- `flow_map.png`：RG 单位流向（128 为零，大于 128 为 +X / +Y），B 疏密，A 水面
- `mask_water.png`：软水面（白=可动）
- `mask_protect.png`：硬保护（白=必须与原画一致）
- `coord_sn.png`：R 为弧长相对 `TRAVEL_PX` 的小数相位，G 为横向
- `ripple_tile.png`：水纹（R/G 同一层），横向一整圈才重复
- `water_detail.png`：只含水色的高频笔触，岸上是中性灰
- `generate_stream_flow_anim.py`：可复现帧生成；`--export-preview` 写出 Godot 贴图
- `anim_frames/`：40 帧循环 + `stream_static_low_motion.png`
- `sample_frames/`：00/10/20/30 + static 代表帧
- `secondary_map.png`：宽水面次级相位。R 横纹，G 侧流，B 涡流角度，A 宽水面权重
- `secondary_weight.png`：R 横纹、G 侧流、B 涡流。窄渠和水面外为 0
- `stream_flow_loop.gif` / `stream_flow_loop_10s.mp4`：循环预览
- `stream_crop_lowerleft.mp4`：1280×720 左下溪床邻域（420×360）
- `stream_zoom.mp4`：溪床裁切后最近邻放大 2 倍（280×456）
- `godot_preview/`：可直接打开的 Godot 工程（见 `godot_preview/README_run.md`）

## 技术要点（对齐 #749 溪流）

- **下游**：从桥下出水口走向画面前景（+Y），中心线跟着冷色水面弯，单步限制横向，避免跳进石滩。切线的 Y 分量保持为正，整段不会掉头向上游。
- **流向图**：每个水面像素取最近的中心线段切线，再在水面内平滑。窄处疏密更高，宽处更轻；疏密不随时间来回，所以不会整条溪一起闪。
- **水纹平移**：贴图是三道宽高光加几道细纹，横向一整圈才重复，半圈不是同一条纹。采样坐标是弧长相位减去播放相位，亮带沿着弯道往下游（画面下方 / 前景）挪。`TRAVEL_PX` 是 180，8 秒走完一圈，大约半条溪床。
- **为什么不用偶数谐波**：2 次、4 次谐波平移半圈后与自己重合。若再按双相位去混「差半圈」的两层，两层采到同一个纹素，每一帧的水纹都一样。上一版因此第 0 帧和第 20 帧逐像素相同，看起来是静帧。
- **笔触双相位**：高频细节贴图不循环。两层相位差半圈，三角权重在某一层回到起点时为 0，重置发生在看不见的那一层。位移仍约 12 像素。
- **整数周期**：水纹贴图横向一圈等于 `TRAVEL_PX`。phase 0 与 phase 1 落在同一纹样上，首尾相接。半圈是另一组亮带，不是回到同一张静帧。
- **笔触**：高频只从水色里取，位移约 12 像素并夹在 ±8 电平，避免亮沫盖到暗水上闪成硬斑，也避免采样越界拖进岸色。
- **保护**：桥面矩形与雾体候选相同 `(150, 468, 430, 552)`；纸边外圈 28 像素；石头与绿岸在蒙版里挖掉。这些像素不进混合，protect_max 应为 0。
- **低动效静帧**：phase 0、强度 0.20，仍是一幅完成的水彩，不是抽掉水面的线框。次级水流跟着同一强度变轻。
- **宽水面次级水流**（主下游高光不改）：半宽过了约 16 像素才逐渐出现，窄渠权重为 0。
  - 横纹沿法线横穿溪床，相邻宽段方向相反，一圈大约横移 22 像素。
  - 侧流贴着两岸斜着走：左岸往外偏，右岸往另一侧偏，同时仍带着一段顺水。
  - 四处最宽的水潭各有一道轻涡流，相邻水潭旋向相反。中心大约在 `(293,638)`、`(248,703)`、`(249,762)`、`(227,814)`。
  - 三层叠在同一像素上会软夹到 ±84 电平，避免压成墨点。岸、桥、石、纸边的权重仍是 0。

## 复现命令（仓库根）

```bash
python3 art/concepts/env_fx_stream_20261014/generate_stream_flow_anim.py --frames 40 --export-preview

ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -c:v libx264 -qp 0 -pix_fmt yuv420p -vf "scale=1280:-2" \
  art/concepts/env_fx_stream_20261014/stream_flow_loop_10s.mp4

ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -vf "fps=5,scale=836:-1:flags=lanczos,palettegen=stats_mode=full" /tmp/stream_pal.png
ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -i /tmp/stream_pal.png \
  -lavfi "fps=5,scale=836:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3:diff_mode=rectangle" \
  -loop 0 \
  art/concepts/env_fx_stream_20261014/stream_flow_loop.gif
```

40 帧 @ 5fps = 8 秒一整圈（文件名沿用雾体候选的 `_10s` 叫法）。GIF 宽 836，帧延迟 200ms。mp4 用 `-qp 0`，避免有损量化把岸线抹进桥和草地；水面亮带的电平差会留在解码结果里。看的时候盯左下溪床，不要看整幅的平均亮度。

左下邻域和 2 倍溪床从同一套帧裁出来。坐标是 `scale=1280:-2` 之后的 1280×720 画面。溪床大约落在 x161–271、y430–632。

```bash
ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -c:v libx264 -qp 0 -pix_fmt yuv420p \
  -vf "scale=1280:-2,crop=420:360:40:340" \
  art/concepts/env_fx_stream_20261014/stream_crop_lowerleft.mp4

ffmpeg -y -framerate 5 -i art/concepts/env_fx_stream_20261014/anim_frames/stream_frame_%02d.png \
  -c:v libx264 -qp 0 -pix_fmt yuv420p \
  -vf "scale=1280:-2,crop=140:228:148:416,scale=280:456:flags=neighbor" \
  art/concepts/env_fx_stream_20261014/stream_zoom.mp4
```

```bash
godot --path art/concepts/env_fx_stream_20261014/godot_preview --resolution 1280x720
# 或
godot --path art/concepts/env_fx_stream_20261014/godot_preview --headless -- --self-check
```

底图只**复制**进 `godot_preview/textures/`，不修改 `assets/holiday/exploration/near_path_02.webp`。

## 与 fde40165 的像素差

对照上一版头部 `fde40165`（只有主下游高光）。主切线、水纹贴图和窄渠合成没有改，所以差集就是宽水面的次级水流。

源 PNG（1672×941，40 帧并集）：

| 项 | 值 |
|---|---|
| 有变化的像素（任一通道差 > 0） | 6361 |
| 上面的包围盒 | x207–345，y566–825 |
| 明显变化（最大通道差 > 8） | 4593，包围盒 x211–336，y571–821 |
| 宽水面平均通道差 | 12.87（40 帧平均；最低 10.71，最高 14.30） |
| 几何上更宽的水面（该行跨度 ≥ 32 像素）平均通道差 | 11.63 |
| 窄渠、水面外最大差 | 0 |

解码后的 `stream_flow_loop_10s.mp4`（1280×720）对上一版同名 mp4：宽水面平均通道差 12.74；差 > 0 的像素 4836，包围盒 x158–265、y432–632；差 > 8 的像素 2729，包围盒 x161–257、y436–628。溪床窗口以外最大差为 0。解码后第 0 帧对第 10 帧，宽水面平均通道差 24.95；GIF 同比较为 24.67。phase 0 与 phase 1 的源帧逐像素相同。

## 请审阅

请 ART-DIRECTOR / CODEX-LEAD 看 `stream_flow_loop.gif`（或 mp4）时核对这几件事：

- 主下游亮条是否仍沿着弯道一直往下游（画面下方 / 前景）走，循环接缝没有整段倒退。
- 溪床变宽的几段是否能看出另外几道更轻的水流：贴岸的斜向侧流、横着走的涟漪、宽水潭里慢慢转的涡流。窄渠不应另起一道。
- 这不是生产 shader 那种左右来回晃：同一条亮纹不应在半圈时走回上游。半圈时应换成往下游走过的另一组亮带，而不是回到第 0 帧。
- 草地、小路、木屋、桥面、石头、纸边应稳住。脚本会打印 `protect_max`，以及 bridge / paper / meadow 的最大差。
- 水纹应是低对比水彩，不要霓虹青、不要一块矩形贴片。
- 低动效静帧 `stream_static_low_motion.png` 应仍像一幅画完的原画。

仍只是候选。方向确认之前不接入运行时。
