# 溪流流向候选 — 接入契约草案（仍只是候选，#749）

Agent-ID: GROK-BUILD

本文件是对 CODEX-LEAD 在 PR #804 review（完整 SHA `2e03211f3e3f850b27f7d8236b10ce5e7fe13e41`）的回应：隔离 GPU 核对通过后，补充接入契约 / 遮罩 / 成本说明，便于 Leader 接宿主实核。**不修改任何生产资源、shader、场景或存档。** 生产合入许可尚未给出。

本轮另回应 codex dot reviewer 对 `c1d4bbddd2473a0f7368b0b9d35e34abc1eafe25` 的静态审查（PR #804）：宿主 `phase` 锁定为弧度 0→TAU。仍只是候选，不改生产资源、运行时、场景或存档。

## 建议接入点

现有生产水面动效在 `shaders/near_path_motion.gdshader`，由外部 `phase` 驱动，`region_mask` 区分水/草。本候选不覆盖该文件。建议在宿主（近郊探索场景）为溪床单独挂一个 CanvasItem 材质，使用本目录 `godot_preview/stream_flow.gdshader` 的逻辑（或抽成共享材质），底图仍是原 `near_path_02`。

## 契约（与现有雾体/近郊动效对齐）

| 项 | 契约 | 说明 |
|---|---|---|
| 驱动时钟 | 外部 `phase`（float，**弧度 0→TAU**） | 必须与 `godot_preview/stream_flow.gdshader` 的 `fract(phase / TAU)` 及 `stream_flow_driver.gd` 一致。离线 `generate_stream_flow_anim.py` 使用归一化 `phase_01`（0→1）；宿主若持有归一化进度，**必须先乘 TAU** 再写入本 shader。不依赖内置 TIME，支持暂停冻结、减少动态、照片定格 |
| 强度 | `strength` 0.0–1.0 | 0 时输出纯原画（逐像素一致）。早期离线样片里的「低动效 0.20」**仅是历史离线样片参数，不是生产默认**；生产减少动态语义以静态原画为准（见下行） |
| 保护区 | `flow.a == 0` 或独立 `mask_protect` | 岸、桥、石、纸边、草地必须像素级不变；脚本已验证 protect_max=0 |
| 水面蒙版 | `flow_map.a` + `secondary_weight` | 窄渠只主下游；宽水面才加次级层 |
| 流向 | `flow_map.rg` 解码为方向 | 切线 Y 始终为正（往下游 / 画面下方） |
| 循环 | phase 0 与 phase TAU 逐像素相同 | 周期端点是 0 与 TAU，不是 0 与 1。隔离 GPU 整圈首尾完全相同 |
| 暂停 / 减少动态 | 暂停：phase 冻结；减少动态：宿主撤掉子层，只剩原画静帧 | 与生产既有减少动态（撤掉材质）一致，不用 strength 降低代替；宿主负责；shader 本身无内部时钟。旧版本表曾写「phase 冻结 + strength 降低」，已按 CODEX-LEAD review @ `9f7ab71b` 更正 |
| 底图 | 只读复制，不改 `assets/holiday/exploration/near_path_02.webp` | 接入时继续只采样原纹理 |
| 底图采样（隔离裁切候选） | `base_sample_linear` **默认 true** | CODEX-LEAD 2026-10-16 11:47 CST #749：连续 UV 线性取样，匹配宿主线性原画。控制图仍 nearest。保护区、`strength 0`、减少动态回原画保持 |

## phase 单位

shader / 预览驱动与离线生成脚本用的不是同一套 phase。宿主接口只认弧度。

| 约定 | 范围 | 用在哪 |
|---|---|---|
| 弧度 | 0→TAU | `godot_preview/stream_flow.gdshader`（`fract(phase / TAU)`）与 `stream_flow_driver.gd`（`fposmod` 到 TAU，一圈 8 秒） |
| 归一化 | `phase_01` 0→1 | 仅离线 `generate_stream_flow_anim.py`。脚本里 phase 0 与 phase 1 才是同一帧 |

宿主自己的时钟若是 0→1 进度，在 `set_shader_parameter("phase", …)` 之前乘 TAU。错误用法是把 0→1 直接喂进本 shader：`fract(phase / TAU)` 在 phase=1 时只走出完整周期的约 15.9%（1/TAU），宿主再重置到 0 时从这一小段跳回起点。循环比较的是 phase 0 与 phase TAU。

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
| 历史离线样片：strength 0.20、phase 0 静帧对原画（不是生产语义） | 保护区最大差 0；裁切矩形外最大差 0；水面平均差 3.01；变化 5964 px |

结论（建议，待 Leader 实核）：**不要把 5 张整幅控制图原样接入**。溪床只占 0.49%，整幅 RGBA8 会白占约 30 MiB 显存。接入时应把材质挂在 183×302 的溪床裁切节点上，控制图也按同一矩形裁切（底图仍采样原 `near_path_02`，用偏移 uniform 对齐），显存约降到 1 MiB、片元降到 3.5%。裁切版贴图、偏移 uniform 与隔离 demo 已补，见下节「裁切子层隔离 demo」。

### 仍未覆盖

- 隔离 GPU（Godot 4.7.2 / OpenGL 3.3 / RTX4070，CODEX-LEAD 核对 `2e03211f`）已验证半圈 4155 像素变化、水面外与保护区差 0、整圈首尾相同。
- 尚未在完整天气/昼夜、照片回放、Web/手机、DPR2/3 上测帧时或实际 PCK 增量；上表是离线资源估算，不是运行成本证据。390×844 窗口导出仅含 390×219 内容，不构成完整竖屏证据。
- 上表 strength 0.20 静帧只是历史离线样片，只证明离线合成边界，不代表生产减少动态；生产减少动态撤掉子层、回原画静帧。宿主侧暂停冻结与减少动态切换仍需实机证据。

## 裁切子层隔离 demo（回应 CODEX-LEAD review @ `bab9c32d`）

仍只是隔离候选：只在 `godot_preview/` 里，不改 `scripts/exploration/near_path_scroll.gd`、`near_path_motion.gd`、`near_path_mist.gd` 或任何生产资源。生产近郊 Owner 仍是 ASSISTANT，正式接线按文件边界另行协调。

| 文件 | 作用 |
|---|---|
| `make_crop_textures.py` | 按 `Rect2i(191, 543, 183, 302)` 从整幅控制图裁出 5 张 183×302 控制图到 `godot_preview/textures/crop/`；先校验水面/次级层全部在矩形内、四周至少 16 px（大于最大位移 12 px）。`--check` 只核对已提交文件与源子矩形逐像素一致 |
| `godot_preview/stream_flow_crop.gdshader` | 裁切版材质。水面算法与 `stream_flow.gdshader` 相同；控制图按裁切 UV 采样，底图仍采样整幅原画，用 `crop_origin` / `crop_size` uniform 对齐。`base_sample_linear` 默认 true（连续 UV）。非水面像素与 `strength == 0` 时输出透明，下面的原画原样露出 |
| `godot_preview/stream_flow_crop_demo.tscn` | 仿宿主结构：`Painting`（整幅原画 Sprite2D）下挂 `StreamCrop`（183×302 子层，位置 191,543） |
| `godot_preview/stream_flow_crop_driver.gd` | 8 秒一圈：`phase = fposmod(phase + max(delta, 0) * TAU / 8, TAU)`；不复用现动效 0.42 rad/s，不用内置 TIME。暂停冻结 phase；减少动态撤掉子层（只剩原画静帧），不把 strength 0.20 当默认 |
| `verify_crop_render.py` | 用 Godot 4.7 导出整幅版与裁切版同 phase 帧并逐像素对照 |

本轮实测（Godot 4.7.2 / OpenGL 3.3 兼容渲染 / Mesa llvmpipe 软件渲染，Xvfb，1672×941；**不是 RTX 实机，也不是 Web/手机**）：

| 检查 | 结果 |
|---|---|
| 裁切版 vs 整幅版，phase 0、π/2、π、3π/2、TAU | 最大通道差 ≤1，每帧 0–2 px（GPU 采样舍入） |
| 裁切版 vs 原画：矩形外 / 保护区 | 最大差 0 / 0 |
| 每帧水面变化 | 7070–7159 px；半圈对首帧变化 7081 px |
| 循环 phase 0 vs TAU | 最大差 0 |
| `strength 0` 与「减少动态」对原画 | 全画布最大差 0 |
| demo 自检（`--self-check`，无头） | 正常步长 TAU/8×delta；负 delta 不倒退；暂停/减少动态冻结；子层 183×302 位于 191,543；ok=true |

显存：子层 5 张控制图约 1.05 MiB（整幅版约 30 MiB），底图复用宿主已加载的原画。

仍未覆盖：宿主内真实挂接、天气/昼夜、照片定格、村庄切换、退出语义、Web/手机/DPR、实际帧时与 PCK 增量。隔离裁切候选的底图采样默认已改为连续 UV（`base_sample_linear = true`），用来匹配宿主线性原画；控制图仍 nearest。宿主实核仍未做。保护区与 0 强度因整层透明不受影响。

## 下一步（等 Leader 指示）

1. Leader 确认宿主挂点与 phase 来源后，原 Owner 可提交最小接线补丁（独立调用，不覆盖现有 motion/mist）。
2. 补连续 GPU / 天气 / 低动效静帧 / 照片 / 性能证据后再谈生产合入。
3. 本文件与现有 GIF/mp4/shader 仍只是候选；#749 保持开放。

不关闭 #749，不宣称美术验收或听验通过。

## 隔离 demo 线性过滤 / 缩放 / Web 成本（本轮补充）

- 裁切 demo 着色器：`ripple_tile` 与 `water_detail` 使用 `filter_linear`；控制图保持 `filter_nearest`。
- 驱动支持 `--scale` 与键盘 `[` `]` 调整整幅 Painting 缩放，用于观察不同分辨率采样。shader 逻辑仍按裁切像素坐标，不随 scale 改变。
- Web 成本（估算，非实测）：裁切 183×302 ≈ 55k 片元，约占整幅 3.5%。裁切控制图显存约 1.05 MiB。实际 Web 帧时 / GPU / PCK 仍待生产接入后测量。本隔离 demo 未导出 Web。

仍只是候选。暂停与减少动态行为与上一头部相同。

## 线性过滤缩放相位 / 边缘对照（回应 CODEX-LEAD review @ `ba05ea05`，基于 `c4661196`）

仍只是隔离候选：只改 `art/concepts/env_fx_stream_20261014/`，不碰生产宿主。Painting 与 StreamCrop 均 `texture_filter = LINEAR`（`c4661196`）。
脚本 `verify_scale_linear.py`：缩放 0.5 / 0.75 / 1.0 / 1.5 / 2.0 × 偏移（整数 / +0.37,+0.61 子像素）× phase 0、π/2、π、3π/2、TAU。
同变换参考：R = 减少动态（只剩线性 Painting）；F = 整幅预览（仅比水面像素）。

实测环境：Godot 4.7.2 / GL Compatibility / OpenGL3 via **Mesa llvmpipe 软件渲染**（Xvfb，1672×941）。**不是 RTX，也不是 Web/手机/帧时证据**。

| 检查（10 组变换 × 5 相位） | 结果 |
|---|---|
| (b) 非水面像素 C vs R（含裁切矩形外、保护区、矩形内非水面） | 全部最大差 **0** |
| (e) 裁切矩形边框 ±3 纹素带 C vs R | 全部 **0**（线性过滤下矩形边无接缝/光晕；矩形四周 16 px 都是透明非水面） |
| (c) phase 0 vs TAU | 全部 **0**；半圈变化 1762（×0.5）… 28315 px（×2.0） |
| (d) strength 0 vs R | 全部 **0**；×1.0 整数偏移时 R 与原画 PNG 逐像素 **0** |
| (a) 水面像素 C vs F（排除 nearest 平局像素） | 最大 **1** 级，每帧 0–5 px |
| (a′) nearest 平局像素（像素中心恰落在纹素边界：×0.5/×0.75/×1.5 整数偏移） | C 与 F 取相邻纹素，差最大 120–138、每帧 1374–2024 px；两块四边形各自插值 UV 造成的 nearest 平局歧义，不在矩形边、非水面仍 0 |
| 连续切换（真实帧，P/R 键路径） | 暂停 30 帧 phase 不变、两帧逐像素 0；暂停中开减少动态：子层隐藏、画面对原画 0；关闭后子层恢复、与暂停帧 0；运行中开减少动态：phase 冻结 30 帧、画面对原画 0；关闭后 phase 继续走 |

**历史对照（`c1700b35`，当时默认关）**：当时默认算法底图按纹素中心取样（与已复核整幅版一致），所以 Painting 缩放或子像素偏移时，水面像素是 nearest 原画、四周是线性原画。用 strength 1e-4 量这一采样差：×1.0 整数偏移 0；其他组合水面最大 52–80 级、平均 6.8–12.1；水面边缘像素最大 52–71。示意图 `scale2_edge_sampling_panel.png`（×2.0 子像素偏移，从左到右：线性原画 / 当时默认子层 / 差×4 / `--base-linear` 差×4）。
当时可选 `base_sample_linear = true`（`--base-linear`）把底图改为连续 UV 线性取样：10 组全部 **0**（水面与水面边缘），非水面仍 0；×1.0 整数偏移下 5 相位与当时默认逐像素 **0**。控制图仍 nearest，所以水纹/次级层本身在放大时仍按纹素块显示。

## 底图连续 UV 默认开启（CODEX-LEAD 2026-10-16 11:47 CST，#749）

CODEX-LEAD 对 `c1700b35` 的技术决定：隔离候选把 `base_sample_linear` 启为默认，使用连续 UV 匹配宿主线性原画；控制图 nearest 及保护区 / `strength 0` / 减少动态回原画保持。

本候选已按该决定执行，仍只是隔离候选：

- `stream_flow_crop.gdshader`：`uniform bool base_sample_linear = true`
- `stream_flow_crop_demo.tscn`：`shader_parameter/base_sample_linear = true`
- `stream_flow_crop_driver.gd`：`_ready` 写入 `true`；`--base-linear` 仍显式再写一次 `true`
- 控制图 `flow_map` / `coord_sn` / `secondary_*` 仍 `filter_nearest`，按纹素中心取样
- 非水面与 `strength == 0` 仍整层透明；减少动态仍撤掉子层，只剩原画

生产接线仍由 ASSISTANT 定。未改生产 shader、场景、`assets/` 或存档。

仍未覆盖：Web 导出与浏览器成本（本机无 Godot 4.7.2 Web 导出模板，未尝试）、手机/DPR、RTX 复核本头部、宿主内实测。

## 缩放/线性对照验证器（回应 CODEX-LEAD @435cc826）

`verify_scale_linear.py` 不再把**当前默认**（`base_sample_linear=true`）的裁切帧 C 与整幅 nearest 预览 F 的水面差当作通过门——两者底图采样不同，435 默认下该旧判据会误 FAIL。

现分两路：
- **(A) 当前默认 vs 独立 LINEAR Painting**：S0/非水面/矩形外/保护区/边框±3 对 R 差 0；0↔TAU；半圈有变化；`--sequence-check`。
- **(B) 历史/受控 legacy**：`--base-nearest` 的裁切帧与整幅 `stream_flow_preview`（nearest 底图）做水面差 ≤1；**硬门仅 scale=1.0 整数偏移**。分数缩放只汇报：整幅预览 Sprite 仍 nearest，裁切 demo Painting/子层是 LINEAR，差来自 Sprite 过滤而非 `base_sample_linear`。

`--base-nearest` 仅隔离 demo 命令行开关，不改默认、不进生产。作者侧 llvmpipe 全矩阵 RESULT PASS（非 RTX/Web/手机/帧时）。

## 隔离 Web 导出实测（本轮，基于 `435cc826`：`base_sample_linear` 已默认开）

仍只是隔离候选：只改 `art/concepts/env_fx_stream_20261014/`，不碰生产宿主，不导出主游戏。复现：`web_export_check.sh`。

实测环境：Godot 4.7.2 官方 `web_nothreads_release` 模板 → 本机 `python3 -m http.server` → Chrome headless，WebGL 2.0（OpenGL ES 3.0）经 **SwiftShader 软件渲染**，画布 1672×941、DPR 1。**不是 RTX / 真实 GPU，也不是手机、DPR2/3 或真实玩家浏览器的帧时证据。**

| 检查（Web 画布读回，phase 0、π/2、π、3π/2、TAU） | Web 结果 | 同探针桌面 llvmpipe |
|---|---|---|
| 裁切矩形内非水面像素 vs 原画（减少动态帧） | 全部最大差 **0** | 0 |
| 裁切矩形外 ±3 像素一圈 vs 原画 | 全部 **0** | 0 |
| 水面像素确有变化（不是静帧） | 7065–7158 px 变化，最大 99–121 级 | 7070–7159 px，99–121 级 |
| phase 0 vs TAU | **0** | 0 |
| strength 0 vs 原画 | **0** | 0 |
| 连续 P/R（运行 30 帧 → 暂停 30 帧 phase 不变 → 暂停中减少动态：子层隐藏、画面对原画 0 → 关闭 → 恢复后 phase 继续） | 通过 | 通过 |

体积（导出物实测）：`index.pck` 2 547 676 B，其中原画 `near_path_base` 导入纹理 2 438 474 B；动效专用的 5 张裁切控制图 + 水纹贴图 + shader/脚本合计约 0.1 MiB。`index.wasm` 39.5 MB 是引擎本身，与本动效无关，生产已有同一引擎。

帧时（每次 300 帧，同一环境跑 4 次：3 次在 `c1700b35` 默认关，1 次在 `435cc826` 默认开；SwiftShader 软件 WebGL，仅作相对参考）：动效开 平均 24.0–26.3 ms / p95 30.8–34.3 ms；减少动态（子层撤掉）平均 23.1–24.5 ms / p95 30.0–32.7 ms，差值在噪声内。4 次的逐像素结果完全相同，即 1:1 下 `base_sample_linear` 开/关在 Web 上也逐像素一致。不能据此写成真实 GPU 或手机帧时通过。

仍未覆盖：真实 GPU 浏览器 / 手机 / DPR2/3 帧时、生产宿主内 Web 实测、RTX 复核本头部、Web 下缩放/子像素偏移对照（本探针只测 1:1）。
