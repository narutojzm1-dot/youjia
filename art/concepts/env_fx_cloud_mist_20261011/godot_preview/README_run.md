# 云密度隔离预览（Godot 4.7.2）

只打开本目录的 `project.godot`。这是候选预览，不加载主游戏，不改 `assets/holiday` 运行时资源、生产场景、存档或导航。

场景 `cloud_density_preview.tscn` 已经接好：

- 底图 `textures/yard_sunny.png`（从 `assets/holiday/environment/yard_sunny.png` 复制，1920×1080）
- 云图 `textures/cloud_scaled.png`（`cloud_candidate.png` 的 LANCZOS 1.8 倍，贴在底图 (180, 30)）
- 合成遮罩 `textures/mask_combined.png`（天空渐变 + 屋顶/雪峰/树冠挖空后再高斯模糊）
- 语义遮罩 `textures/mask_roof.png`、`textures/mask_snow_peaks.png`、`textures/mask_canopy.png`（白色允许云，黑色为保护区，已绑到 ShaderMaterial）
- 着色器 `cloud_density.gdshader` 的缩放、原点、调制分母与 `generate_cloud_density_anim.py` 相同

打开后 phase 自动从 0 走到 2π，一圈 8 秒（与 40 帧 @ 5fps 的 PNG 序列同一相位）。乘积调制的视觉重复是 4 秒，所以 8 秒里能看到两圈浓淡。

## 启动命令

在仓库根目录执行。`godot` 换成本机 Godot 4.7.2 可执行文件名即可。

横屏 1280×720（与底图同为 16:9，整幅小院，含屋顶和雪峰）：

```
godot --path art/concepts/env_fx_cloud_mist_20261011/godot_preview --resolution 1280x720
```

竖屏 390×844（窗口 390×844，画面按比例缩进窗口，上下留边，屋顶和雪峰仍在画面内）：

```
godot --path art/concepts/env_fx_cloud_mist_20261011/godot_preview --resolution 390x844
```

`--resolution` 会覆盖窗口大小。若不用命令行，可在本目录 `project.godot` 的 `[display]` 里写入下面其中一组后再打开工程：

```
window/size/window_width_override=1280
window/size/window_height_override=720
```

```
window/size/window_width_override=390
window/size/window_height_override=844
```

逻辑视口保持 1920×1080，`canvas_items` + `keep`，两种窗口都显示完整小院，而不是把原帧裁成窄条。

## 暂停和低动效

- `P` 或空格，或画面下方「暂停」按钮：停止 phase 累加，云层定住。再按一次继续。
- `L`，或「低动效」按钮：phase 速度变为 0.25 倍（8 秒一圈变为 32 秒一圈），仍然在变化。再按一次恢复正常速度。
- 两个开关同时打开时，暂停优先，phase 不动。

着色器的 `strength` 默认 1，与 PNG 生成脚本一致。`semantic_gate` 默认 0，合成只用已经包含三处保护的 `mask_combined`。

## 重新导出贴图

遮罩和缩放云由生成脚本写出。在仓库根目录：

```
python3 art/concepts/env_fx_cloud_mist_20261011/generate_cloud_density_anim.py --export-preview
```

该命令会对照 `anim_frames/cloud_frame_00.png` 与 `cloud_frame_10.png`。公式不一致时会直接退出。

## 本机已做的对照

在 Godot 4.7.2.stable（`ed1daf0bf`，Compatibility）里，1920×1080 窗口、隐藏按钮后的视口与 `anim_frames/cloud_frame_00.png`、`cloud_frame_10.png` 逐像素最大差为 0。1280×720 窗口为整幅缩小；390×844 窗口按比例把整幅放进画面（上下留边），屋顶和雪峰仍在画面内。暂停与低动效的相位步进已用固定 delta 核对：暂停增量为 0，低动效为正常速度的 0.25。Leader 仍须在本机复看连续播放。
