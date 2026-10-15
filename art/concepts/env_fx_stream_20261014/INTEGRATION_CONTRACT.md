# 溪流流向候选 — 接入契约草案（仍只是候选，#749）

Agent-ID: GROK-BUILD

本文件是对 CODEX-LEAD 在 PR #804 review（完整 SHA `2e03211f3e3f850b27f7d8236b10ce5e7fe13e41`）的回应：隔离 GPU 核对通过后，补充接入契约 / 遮罩 / 成本说明，便于 Leader 接宿主实核。**不修改任何生产资源、shader、场景或存档。** 生产合入许可尚未给出。

## 建议接入点

现有生产水面动效在 `shaders/near_path_motion.gdshader`，由外部 `phase` 驱动，`region_mask` 区分水/草。本候选不覆盖该文件。建议在宿主（近郊探索场景）为溪床单独挂一个 CanvasItem 材质，使用本目录 `godot_preview/stream_flow.gdshader` 的逻辑（或抽成共享材质），底图仍是原 `near_path_02`。

## 契约（与现有雾体/近郊动效对齐）

| 项 | 契约 | 说明 |
|---|---|---|
| 驱动时钟 | 外部 `phase`（float，建议 0–TAU 或归一化） | 与 `near_path_mist.gd` / 现有 motion 相同，不依赖内置 TIME，支持暂停冻结、减少动态、照片定格 |
| 强度 | `strength` 0.0–1.0 | 低动效时降到 0.20 仍是完整绘本；0 时输出纯原画 |
| 保护区 | `flow.a == 0` 或独立 `mask_protect` | 岸、桥、石、纸边、草地必须像素级不变；脚本已验证 protect_max=0 |
| 水面蒙版 | `flow_map.a` + `secondary_weight` | 窄渠只主下游；宽水面才加次级层 |
| 流向 | `flow_map.rg` 解码为方向 | 切线 Y 始终为正（往下游 / 画面下方） |
| 循环 | phase 0 与 phase 1 逐像素相同 | 已在隔离 GPU 整圈首尾完全相同 |
| 暂停 / 减少动态 | phase 冻结 + strength 降低 | 宿主负责；shader 本身无内部时钟 |
| 底图 | 只读复制，不改 `assets/holiday/exploration/near_path_02.webp` | 接入时继续只采样原纹理 |

## 所需贴图（已在本目录生成，可直接引用或导入为资源）

- `flow_map.png`、`coord_sn.png`、`ripple_tile.png`、`water_detail.png`
- `secondary_map.png`、`secondary_weight.png`
- 底图：运行时采样原 near_path，或继续用预览副本

导入时保持无损或与现有近郊纹理一致；不要为候选引入新的无损大图到正式 PCK 除非明确批准。

## 成本与限制（本轮未实测生产）

- 额外一次全屏或局部采样 + 若干 texture2D；建议宿主把材质挂在溪床裁切节点上，而不是整幅背景。
- 隔离 GPU（Godot 4.7.2 / OpenGL 3.3 / RTX4070）已验证半圈 4155 像素变化、水面外与保护区差 0、整圈首尾相同。
- 尚未在完整天气/昼夜、照片回放、Web/手机、DPR2/3 上测帧时或 PCK 增量。390×844 窗口导出仅含 390×219 内容，不构成完整竖屏证据。
- 低动效静帧与暂停冻结仍需宿主侧证据。

## 下一步（等 Leader 指示）

1. Leader 确认宿主挂点与 phase 来源后，原 Owner 可提交最小接线补丁（独立调用，不覆盖现有 motion/mist）。
2. 补连续 GPU / 天气 / 低动效静帧 / 照片 / 性能证据后再谈生产合入。
3. 本文件与现有 GIF/mp4/shader 仍只是候选；#749 保持开放。

不关闭 #749，不宣称美术验收或听验通过。
