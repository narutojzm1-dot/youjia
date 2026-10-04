# REQ-005 · 同构图阴天运行时兼容盘点（未接图）

- 日期：2026-10-04
- Agent-ID：`CURSOR-CONTRIBUTOR-LOCAL`
- 关联：[#168](https://github.com/narutojzm1-dot/youjia/issues/168)、[#51](https://github.com/narutojzm1-dot/youjia/issues/51)、[sky-cloud-plan.md](sky-cloud-plan.md)
- 状态：**只盘点，不改运行时。** ART-DIRECTOR 对 PR #202 候选 `a347079` 结论为「需修改、暂不可接入」。GROK-BUILD 修天空灰块/雪坡/地表受光后再审。正式 `preload` 换图须等明确「可接入」。

## 当前运行时（main）

| 点 | 现状 |
| --- | --- |
| 阴天院子 | `YardWorld.OVERCAST` → `res://assets/holiday/environment/yard_overcast.png`（旧构图） |
| 阴云带 | `CLOUD_OVERCAST` → `cloud_band_overcast.png`；阴天不换晨/晚/夜云帧 |
| 滤色 | 阴天院子与云带共用 `_backdrop.modulate` |
| 低动效 | 云带静止；底图仍切阴天贴图 |
| 照片 | `PhotoMoment` 把 `_backdrop.texture` 记成资源描述回放；旧阴天照依赖**旧路径字节不变** |
| 导出 | `tools/verify_exported_pack.gd` 点名包含 `yard_overcast.png` |

## 接入时必须做（等可接入）

1. **新路径**：把通过审的 PNG 复制到 `assets/holiday/environment/` 下**新文件名**（例如 `yard_overcast_aligned.png`），再让 `OVERCAST` 指向它。禁止覆盖旧 `yard_overcast.png`。
2. **旧图仍导出**：旧路径、原字节留在 PCK，供历史 `PhotoMoment` 回放。
3. **候选目录**：`art/concepts/yard_overcast_aligned_v1/` 保持 `.gdignore`，不进可玩包。
4. **云带/TOD/低动效**：不因换底图改晨晚夜晴天云逻辑；阴天继续阴云带 + 现有滤色。白盒：`ui_interaction_suite` 阴天贴图断言、低动效静止、夜里阴天仍阴云。
5. **天气切换**：晴↔阴连续切、暂停恢复、混合中拍照后重启，底图应是拍摄时那张路径。
6. **PCK**：正式 Web 导出报新旧阴天都在包内的增量，不以候选 PNG 字节代替。

## 明确不做（本盘点）

- 不把未通过审的 `yard_overcast_aligned.png` 接进 `YardWorld`
- 不改雨雪、季节整层、REQ-012 D
- 不改 GROK 候选像素
