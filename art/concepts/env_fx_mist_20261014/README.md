# 绘本风格雾体隔离候选（#749）

Agent-ID: GROK-BUILD

本目录为**雾体（湖雾/山雾）隔离候选**，平行于已合入的云体样片 `art/concepts/env_fx_cloud_mist_20261011/`（PR #755 → merge `34740e7e55ab0faebf7b2a2af3d2edf75600c2f7`）。  
**不覆盖任何运行时资源**，不接入主游戏动态，不改现有生产 shader / 场景 / `.png.import`。

## 范围与限制

| 做了 | 没做 |
|---|---|
| 1–2 层手绘薄雾层（由已批准 `mist_candidate.png` 派生） | 未接线到 `near_path_mist.gdshader` / 生产场景 |
| 多尺度连续噪声调制 alpha + 微形变；可选小幅平移 | 未做体积雾 / 流体模拟 / 全幅视频循环作生产路线 |
| 空间包络只留湖面与溪水；保护草地、小路、木屋、桥、纸边 | 未改 `assets/holiday/**` 正式资源 |
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

- **局部浓淡聚散**：整数谐波（1× 大团、2× 细团）。半频项会在 2π 接缝跳变，已去掉。远近层相位错开（+2.1）。
- **看得见的漂移**：手绘层横向几乎均匀，所以漂移带动的是浓淡波，不是一块平移的平板。`far_drift_px=150`、`near_drift_px=-120`；大团一圈走一个波长，中点与起点错开约半个波长。
- **密度呼吸 / 抬升**：`far_lift_px=48`、`near_lift_px=62`，雾带中点抬起、循环结束落回。覆盖度只与包络相乘一次（不再把 alpha 平方），峰值用 `ca_cap=170` 封顶。
- **远/近薄厚**：远层强度 ×0.90、更大尺度、原点更高；近层更密、略低。
- **空间包络**：雾贴着湖面（约 x 590–870、y 410–470，并略向上抬）和左下溪水。中央草地挖空。近景小路、木屋含屋顶、桥面与纸边再挖空。不再使用整条谷地软带（旧 y 430–740 会铺在草坪上）。
- **可读性**：小路与屋顶跨帧应几乎不动（脚本打印 protect_max）；不是风暴，也不是铺满画面的死白雾。

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
