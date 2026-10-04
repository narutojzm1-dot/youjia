# 大鹅骑马演出 · 组合验收记录（REQ-20261002-015 / issue #180）

> **记录性质**：本文为**代码推导型**验收记录（静态读码 + manifest 数据计算），非运行时 Web/实机验收。
> **issue #180 保持开放**，待 GAME-QA / ART-DIRECTOR 实机录制或用户 fresh build 验证后关闭。
> **代码基线**：main `facc0748`（2026-10-05 读取）。
> **Owner**：WORKBUDDY-CONTRIBUTOR。镜头演出倍率修正属 REQ-014-NO-ZOOM / #40（CODEX-LEAD），不在本记录改动范围。

## 0. 结论摘要
1. **马的 base_scale**：由 `CastArt.configure` 推导，`horse ≈ 0.2736`（设实体注册 `scale` 默认 1.0），渲染参考高度 ≈ **305.6px @depth1**。
2. **实际 scale（运行时）**：`scale = base_scale × visual_scale(默认1.0) × depth_at(y)`，`depth_at ∈ [0.82, 1.18]`。
3. **乘骑期间马尺寸恒定**：`horse.set_encounter_pose(horse.position, horse._base_scale, …)` 不改变马的 `y` 与 `base_scale` → 渲染高度不变。
4. **鹅仅因落脚点抬高 −52px(y) 产生 ~8% 透视缩小**（正确透视，非 bug）。
5. **`set_encounter_pose` 不改 scale**（传入各自 `_base_scale`）；`show_goose_encounter_cel` 只换贴图+脚底锚点，不改 scale。
6. **Camera.zoom**：三段（wide / first_person / close）当前均 = `1.0`；历史上 close = `1.82`（造成"明显镜头缩放"）已在 REQ-014-NO-ZOOM 中改为 `1.0`，已合入 main。
7. **"马偶尔变大"**：正常游走时 `depth_at(y)` 随 `y` 在 `[0.82, 1.18]` 变化，马的渲染高度 ±18%（透视，非回归）；配合已移除的 1.82× 近景，观感问题已消解。实机结论待 Web 证据。

## 1. 马的 base_scale 推导（scripts/game/cast_art.gd）
- `TARGET_HEIGHT = {"...","horse":110.0,"...","goose":70.0,"..."}`（line 5）
- `LEGACY_SCALE  = {"...","horse":0.36 ,"...","goose":0.38,"..."}`（line 6）
- 公式（line 35-36）：
  `ratio = TARGET_HEIGHT[species] / max(bbox[3],1) / LEGACY_SCALE[species]`
  `config.scale = float(config.scale) * ratio`
- 马的 alpha_bbox（manifest.json `horse`）：`[53, 68, 1192, 1117]` → `bbox[3] = 1117`
- `ratio_horse = 110 / 1117 / 0.36 ≈ 0.2736`
- 马的 `base_scale ≈ 0.2736`（假定实体注册 `scale=1.0`；若注册表覆盖则乘以该系数）
- 渲染参考高度（depth=1, breath=1）：`TARGET_HEIGHT / LEGACY_SCALE = 110 / 0.36 ≈ 305.6px`
- 鹅：`bbox[3]=1109` → `ratio_goose = 70 / 1109 / 0.38 ≈ 0.1661`，渲染参考 ≈ `70 / 0.38 ≈ 184.2px`
- **关键不变式**：每个 cel 的 `bbox[3] × ratio = TARGET_HEIGHT / LEGACY_SCALE` 为常数 → 同一物种所有 cel（含 `riding_up`/`riding_down`）渲染高度一致（≈184.2px 鹅 / ≈305.6px 马），翅膀上/下姿态**不产生尺寸差**。

## 2. 实际 scale 与透视（felt_actor.gd + yard_ground.gd）
- 渲染：`scale = base_scale × visual_scale × depth_at(y)`（felt_actor.gd line 411 / 539）；`visual_scale = get_meta("visual_scale", 1.0)`（line 397，默认 1.0）。
- `depth_at(y)`（yard_ground.gd line 46-48）：`FAR_Y=420, NEAR_Y=650`；`t = clamp((y-420)/230, 0, 1)`；`return lerpf(0.82, 1.18, t)`。
- 即 `y` 越靠上（远）→ 0.82；越靠下（近）→ 1.18。院内任意位置的透视缩放区间 **[0.82, 1.18]**（±18%）。
- **乘骑期间**：马 `position` 不变（line 544）→ `depth_at` 恒定 → 高度恒定；鹅落到 `back_point = horse.position + (10, -52)`（line 540）→ `y` 上移 52px → `depth_at` 减小约 `(52/230)×0.36 ≈ 0.081` → 鹅在马背上渲染约小 8%（正确透视：马背在更高/更远位置）。

## 3. set_encounter_pose / show_goose_encounter_cel 是否改动尺寸
- `set_encounter_pose(point, next_scale, face)`（felt_actor.gd 270）：仅首次保存 `_encounter_saved_base_scale`，随后 `set_pose(point, next_scale, face)`（254）→ `_base_scale = next_scale`。乘骑传入 `goose._base_scale` / `horse._base_scale`（自身值）→ **base_scale 不变**。
- `show_goose_encounter_cel(cel)`（278）：仅 `_posture_id=cel`、换贴图、按 posture_metadata 重设 `_ground_anchor`/`_art_bounds`、调用 `_anchor_feet()`；**不触碰 `_base_scale`**。故两帧交替（riding_up/riding_down）只换画、不改尺寸。
- 结论：演出中的"演员尺寸突变"**不来自接线**，只来自 (a) 透视 `depth_at`（见 §2），(b) 历史上 1.82× 近景（见 §4，已修复）。

## 4. Camera.zoom 各阶段（scripts/game/yard_world.gd）
| 阶段 | 触发 | 视图 | Camera.zoom | 代码 |
|---|---|---|---|---|
| 等待→起手 | `_goose_mount_wait ≥ 3.5` | wide | **1.0** | line 521 `camera_focus_requested.emit(scene_center, 1.0)` |
| phase1 | `seconds ≥ 1.25` | first_person | **1.0** | line 535 `emit(eyeline, 1.0)` |
| phase2 近景 | `seconds ≥ 1.4` | close | **1.0** | line 549 `emit(close_focus, 1.0)` |
| 中断 / 完成 | cancel / complete | — | 释放 | line 582 / 600 `camera_release_requested.emit()` |

- 注释（line 542）："The encounter keeps the normal camera scale; do not inflate PNG canvases." —— 导演明确近景不放大。
- 历史值：该 close 发射曾为 `1.82`（造成用户反馈"明显镜头缩放"）；在 REQ-014-NO-ZOOM（CODEX-LEAD，对应 decisions.md 2026-10-04 条目 / #40）中改为 `1.0`，已合入 main（`facc0748` 验证）。
- 对照：`QUIET_SKY_ZOOM := 1.14`（line 44）为真实轻微放大；`1.0` = 不放大。

## 5. 组合维度覆盖
| 维度 | 处理 | 代码 / 结论 |
|---|---|---|
| 前后（鹅在马背） | `back_point = horse.position + (10, -52)`；`goose.z_index = horse.z_index + 1` | line 540-545；鹅恒在马身之上 |
| 中断 | 玩家移动/有行走目标/牵领/禁输入 → `_cancel_goose_mount_encounter` → 双方 `release_encounter_pose()` + `camera_release_requested.emit()` | line 524, 586-601；base_scale/position/facing/z_index 全部还原，无残留放大 |
| 朝向（马双朝向） | `horse.set_encounter_pose(horse.position, horse._base_scale, horse.facing)`；鹅 facing = -1.0；`_sprite.scale.x = _native_facing` | line 544, 413；马保留自身朝向，鹅骑乘 cel 按 native_facing 翻转，互不影响 |
| 近远 | 透视由 `depth_at(y)` 决定，演出在院内任意 `y` 成立 | §2；远(0.82)/近(1.18) 仅整体缩放，逻辑不变 |
| 低动效 | `reduced_motion` 时跳过扑翼交替（定帧 riding_up），完成时间 1.2s（常态 3.2s） | line 554-561；可读性与时长正确 |

## 6. 待补（不关闭 #180 的理由）
- 本环境**无 Godot 二进制**、无 Web 构建 → 无法产生运行时/实机截图与录制。
- issue #180 规则："当前不将后置代码审查当组合体验通过。" 故仅以本文作**代码推导记录**，不宣称组合 Web 验收通过。
- 后续：GAME-QA / ART-DIRECTOR 在 fresh build（`facc0748` 之后）实机触发演出并录制 前后/中断/朝向/近远/低动效 五态，确认无残留镜头缩放、马尺寸稳定后，由 WORKBUDDY-CONTRIBUTOR 关闭 #180。
- 建议用户先在本机 fresh build 确认"明显镜头缩放"已消失（应已随 REQ-014-NO-ZOOM 修复）；若仍见，则需回查相机消费端（scene 中 `camera_focus_requested` 连接）是否另有倍率。

## 7. 关键定位速查
- 乘骑三段：yard_world.gd 498-562（phase0-2）、565-580（complete）、586-601（cancel）
- base_scale 推导：cast_art.gd 5-6, 24-37；manifest.json `horse` / `goose` / `goose_riding_up` / `goose_riding_down`
- 渲染 scale：felt_actor.gd 254-275, 278-292, 387-421, 525-549
- 透视：yard_ground.gd 46-48
- 镜头倍率：yard_world.gd 8, 44, 521/535/549/582/600；decisions.md 2026-10-04 REQ-014-NO-ZOOM
