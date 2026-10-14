# 雾体密度隔离预览（Godot 4.7.2）

只打开本目录的 `project.godot`。这是 #749 雾体候选预览，不加载主游戏，不改 `assets/holiday` 运行时资源、生产场景、存档或导航。

场景 `mist_density_preview.tscn` 已经接好：

- 底图 `textures/near_path_base.png`（从已批准 `assets/holiday/exploration/near_path_02.webp` 复制，1672×941）
- 远层 `textures/mist_far.png`、近层 `textures/mist_near.png`（由已批准 `mist_candidate.png` 派生的 1–2 层手绘薄雾）
- 空间包络 `textures/mask_envelope.png`（山谷/湖面软带 + 前景小路/木屋/桥/纸边保护）
- 语义遮罩 `mask_path.png` / `mask_cottage.png` / `mask_bridge.png`（白色允许雾，黑色保护）
- 着色器 `mist_density.gdshader` 的原点、漂移、微形变与多尺度调制分母与 `generate_mist_density_anim.py` 相同

打开后 phase 自动从 0 走到 2π，一圈 8 秒（与 40 帧 @ 5fps 的 PNG 序列同一相位）。谷地雾团会漂移并有浓淡呼吸；近景小路和屋顶保持可读。原点、漂移、抬升、形变、调制分母与 `ca_cap` 跟生成脚本一致。

## 启动命令

在仓库根目录执行。`godot` 换成本机 Godot 4.7.2 可执行文件名即可。

横屏（与底图同比例）：

```
godot --path art/concepts/env_fx_mist_20261014/godot_preview --resolution 1280x720
```

竖屏窗口（整幅按比例缩进，上下留边）：

```
godot --path art/concepts/env_fx_mist_20261014/godot_preview --resolution 390x844
```

## 暂停和低动效

- `P` 或空格，或「暂停」按钮：停止 phase 累加。
- `L`，或「低动效」按钮：速度 ×0.25，仍在变化。
- 两开关同时开时，暂停优先。

`strength` 默认 1；`semantic_gate` 默认 0（只用已含保护的 envelope）。

## 重新导出贴图

```
python3 art/concepts/env_fx_mist_20261014/generate_mist_density_anim.py --frames 40 --export-preview
```

## 本机自检（本环境有 Godot 4.7.2 时）

```
godot --path art/concepts/env_fx_mist_20261014/godot_preview --headless -- --self-check
```

仍只是隔离候选。请 ART-DIRECTOR / CODEX-LEAD 审阅连续播放下的聚散感、岸线/山脊可读性与前景保护。
