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

## 成本与限制

### 资源与遮罩实测（离线，`measure_stream_cost.py`，非运行时帧时）

在仓库根运行 `python3 art/concepts/env_fx_stream_20261014/measure_stream_cost.py` 可复现，只读、不写文件：

| 项 | 实测 |
|---|---|
| 画布 | 1672×941（与 `near_path_02` 同尺寸） |
| 水面像素（`mask_water` / `flow_map.a`） | 7769 px，占 0.49%，bbox x207–358、y559–829 |
| 次级层像素（`secondary_weight`） | 6685 px，bbox x207–347、y565–826 |
| 保护区（`mask_protect`） | 占 99.51%；与水面/次级层重叠 **0 px** |
| 建议显式裁切矩形（外扩 16 px） | x191–374、y543–845 = **183×302**，占画布 3.5% |
| 5 张整幅贴图 RGBA8 显存估算 | 6.00 MiB/张，共 **30.0 MiB** |
| 同 5 张按裁切矩形 | 0.211 MiB/张，共 **1.05 MiB** |
| `ripple_tile` | 256×96，约 96 KiB |
| 6 张贴图 PNG 字节 | 共 144,310 B（未导入、未压缩为 PCK 格式） |
| 片元数 | 整幅四边形 1,573,352；裁切四边形 55,266（3.5%） |
| 低动效静帧（strength 0.20，phase 0）对原画 | 保护区最大差 0；裁切矩形外最大差 0；水面平均差 3.01；变化 5964 px |

结论（建议，待 Leader 实核）：**不要把 5 张整幅控制图原样接入**。溪床只占 0.49%，整幅 RGBA8 会白占约 30 MiB 显存。接入时应把材质挂在 183×302 的溪床裁切节点上，控制图也按同一矩形裁切（底图仍采样原 `near_path_02`，用偏移 uniform 对齐），显存约降到 1 MiB、片元降到 3.5%。裁切版贴图与偏移 uniform 本轮**未制作**，等 Leader 确认宿主挂点后随最小接线补丁一起交。

### 仍未覆盖

- 隔离 GPU（Godot 4.7.2 / OpenGL 3.3 / RTX4070，CODEX-LEAD 核对 `2e03211f`）已验证半圈 4155 像素变化、水面外与保护区差 0、整圈首尾相同。
- 尚未在完整天气/昼夜、照片回放、Web/手机、DPR2/3 上测帧时或实际 PCK 增量；上表是离线资源估算，不是运行成本证据。390×844 窗口导出仅含 390×219 内容，不构成完整竖屏证据。
- 低动效静帧上表只证明离线合成边界；宿主侧暂停冻结与低动效切换仍需实机证据。

## 下一步（等 Leader 指示）

1. Leader 确认宿主挂点与 phase 来源后，原 Owner 可提交最小接线补丁（独立调用，不覆盖现有 motion/mist）。
2. 补连续 GPU / 天气 / 低动效静帧 / 照片 / 性能证据后再谈生产合入。
3. 本文件与现有 GIF/mp4/shader 仍只是候选；#749 保持开放。

不关闭 #749，不宣称美术验收或听验通过。
