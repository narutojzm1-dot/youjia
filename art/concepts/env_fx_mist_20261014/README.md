# 绘本风格雾体隔离候选（#749）

Agent-ID: GROK-BUILD

本目录为**雾体（湖雾/山雾）隔离候选**，平行于已合入的云体样片 `art/concepts/env_fx_cloud_mist_20261011/`（PR #755 → merge `34740e7e55ab0faebf7b2a2af3d2edf75600c2f7`）。  
**不覆盖任何运行时资源**，不接入主游戏动态，不改现有生产 shader / 场景 / `.png.import`。

## 范围与限制

| 做了 | 没做 |
|---|---|
| 1–2 层手绘薄雾层（由已批准 `mist_candidate.png` 派生） | 未接线到 `near_path_mist.gdshader` / 生产场景 |
| 多尺度连续噪声调制 alpha + 微形变；可选小幅平移 | 未做体积雾 / 流体模拟 / 全幅视频循环作生产路线 |
| 空间包络限制山谷/湖面；保护小路、木屋、桥、纸边 | 未改 `assets/holiday/**` 正式资源 |
| 可复现生成脚本 + Godot 4.x 隔离预览工程 | 未宣称美术验收完成 |
| PNG 序列 / 循环样片供无 Godot 时对照 | 未合并溪流切片（仍留给后续） |

## 目录

- `mist_far_layer.png` / `mist_near_layer.png`：远/近手绘薄雾层
- `mask_envelope.png`：空间包络（白=允许雾，黑=保护）
- `generate_mist_density_anim.py`：可复现帧生成；`--export-preview` 写出 Godot 贴图
- `anim_frames/`：40 帧循环 + `mist_static_low_motion.png`
- `sample_frames/`：00/10/20/30 + static 代表帧
- `mist_density_loop_10s.mp4` / `mist_density_loop.gif`：循环预览（若已编码）
- `godot_preview/`：可直接打开的 Godot 工程（见 `godot_preview/README_run.md`）

## 技术要点（对齐 #749 正文）

- **局部浓淡聚散**：phase 驱动多尺度 sin/cos，远近层相位错开（+1.7），避免全场同步呼吸。
- **远/近薄厚**：远层强度 ×0.85、更大尺度；近层更密、更靠前景谷底。
- **空间包络**：中景山谷/湖面软带；前景小路椭圆、木屋矩形、桥区与纸边挖空后再高斯模糊。
- **可选平移**：`far_drift_px=6`、`near_drift_px=-4`，幅度克制，主运动仍是内部聚散与微形变。
- **可读性**：保护区内跨帧像素差应为 0（脚本自检打印）；避免白色贴片、矩形边、全幅泛白。

## 复现命令（仓库根）

```bash
python3 art/concepts/env_fx_mist_20261014/generate_mist_density_anim.py --frames 40 --export-preview

ffmpeg -y -framerate 5 -i art/concepts/env_fx_mist_20261014/anim_frames/mist_frame_%02d.png \
  -c:v libx264 -pix_fmt yuv420p -vf "scale=1280:720" \
  art/concepts/env_fx_mist_20261014/mist_density_loop_10s.mp4

ffmpeg -y -framerate 5 -i art/concepts/env_fx_mist_20261014/anim_frames/mist_frame_%02d.png \
  -vf "scale=640:360,fps=5" -loop 0 \
  art/concepts/env_fx_mist_20261014/mist_density_loop.gif

godot --path art/concepts/env_fx_mist_20261014/godot_preview --resolution 1280x720
# 或
godot --path art/concepts/env_fx_mist_20261014/godot_preview --headless -- --self-check
```

底图只**复制**进 `godot_preview/textures/`，不修改 `assets/holiday/exploration/near_path_02.webp`。

## 请审阅

请 ART-DIRECTOR / CODEX-LEAD 基于本目录样片与 Godot 预览评价：聚散是否可辨、岸/脊是否可读、是否出现贴片/矩形边/洗白。仍只是候选，待方向确认后再谈生产接入。
