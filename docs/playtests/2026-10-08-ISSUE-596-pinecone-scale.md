# issue #596 近郊松果显示比例过大 · 代码推导根因与最小修复

- **issue**: [#596](https://github.com/narutojzm1-dot/youjia/issues/596) — [玩家反馈][BUG] 近郊松果显示比例过大，与人物和场景尺度不协调
- **日期**: 2026-10-08
- **分析人**: `WORKBUDDY-CONTRIBUTOR`（用户授权认领并无主 bug 继续贡献）
- **方法**: 静态读码 + manifest 推导。**本环境无 Godot / Web 构建**，运行时 Web 像素证据待补（同 #180 缺口）。
- **结论**: 根因定位为「近郊地面可拾取实体与拾取展示共用同一个 `1.6` 放大系数」。已提出最小修复（命名常量 `FIND_GROUND_SCALE` 取代字面量 `1.6`，落地为 `1.0`），提交 PR 待制作人/美术按实景校准；**#596 保持开放**直至实机录制或用户 fresh build 验证。

---

## 1. 现象（来自 #596 正文）

用户 2026-10-08 实玩截图反馈：近郊小路下方的松果显示得过大，与人物和周边物件（圆石、地面）尺度明显不协调，原话「显示的松果太大了，这个不正常」。issue 正文已点明排查方向：**「排查场景实体与拾取展示是否共用错误尺寸」**——下文证明这正是问题所在。

## 2. 尺度链路（逐文件读码）

### 2.1 地面 finds 的绘制入口
`scripts/exploration/near_path_scroll.gd`

- **场景实体（静止在地面的可拾取物）**，`_draw_items()` 第 571 行：
  ```gdscript
  KeepsakeArt.draw(items, find_id, anchor, 1.6 * depth, true)
  ```
  其中 `depth = layout.depth(anchor.y)`，`anchor` 为停留点 `item` 原画坐标。
- **拾取飞行动画（带上时从地面飞向提篮）**，`_start_reveal()` 第 395 行：
  ```gdscript
  reveal.play(find_id, art_to_screen(anchor), top, _basket.position + Vector2(24 + slot * 16, 22),
      1.6 * layout.depth(anchor.y) * _cam_zoom, _find_name(find_id), reduced_motion())
  ```
  即**同一字面量 `1.6`** 同时作用于「场景实体」与「拾取展示」两处——正是 issue 正文所疑的「共用错误尺寸」。

### 2.2 KeepsakeArt 的尺度换算
`scripts/exploration/keepsake_art.gd`

- `TEXTURE_SPAN := 30.0`（注释：「贴图在 size 1 时的长边」）。
- `draw()` 纹理路径（第 22-33 行）：
  ```
  长边 px = TEXTURE_SPAN(30) * size / max(tex.w, tex.h) * max(tex.w, tex.h)
          = 30 * size
  ```
  故地面 finds 渲染长边 = `30 * 1.6 * depth` ≈ **48 × depth px**。
- 占位画法 `_pine_cone`（第 53-64 行）局部外接约 30 单位（顶部茎 -16、底部圆 +13），同样经 `draw_set_transform(at, -0.5, Vector2.ONE * s)` 以 `s = size = 1.6 * depth` 缩放 → 同样约 **48 × depth px**。无论用贴图还是占位画法，松果屏幕高度都≈ 48×depth。

### 2.3 透视 depth(y)
`scripts/exploration/painted_path.gd` 第 87-88 行（由 `NearPathLayout` 透传）：
```gdscript
func depth(y): return lerpf(DEPTH_FAR, DEPTH_NEAR, clampf((y - DEPTH_FAR_Y)/(DEPTH_NEAR_Y - DEPTH_FAR_Y), 0, 1))
# DEPTH_FAR_Y=530, DEPTH_NEAR_Y=845, DEPTH_FAR=0.45, DEPTH_NEAR=1.35
```
brook 停留点 `item = Vector2(880, 752)` →
`depth(752) = lerpf(0.45, 1.35, (752-530)/(845-530)) = lerpf(0.45, 1.35, 0.705) ≈ 1.084`。

### 2.4 参照物尺度
- **人物**：`NearPathLayout.WALKER_BOX := Rect2(-24, -108, 48, 108)`（`near_path_layout.gd` 第 39 行），高 108，经 `walker.advance(..., layout.depth(foot().y), ...)` 以 `depth` 渲染 → **108 × depth px**。
- **落叶堆**（同场景共存的地面物，独立画法，`near_path_scroll.gd` 第 556 行）：
  `leaf_size = leaf_texture.get_size() * (56.0 / leaf_texture.get_width()) * depth` → 长边 **56 × depth px**（不走 KeepsakeArt，故不受 1.6 影响）。

## 3. 数值对比（brook 停留点，depth≈1.084）

| 对象 | 公式 | 屏幕高度（≈） | 相对人物身高 |
| --- | --- | --- | --- |
| 人物（WALKER_BOX） | 108 × depth | 117 px | 100% |
| 松果（修复前，`1.6`） | 30 × 1.6 × depth | 52 px | **≈44%** |
| 松果（修复后，`1.0`） | 30 × 1.0 × depth | 33 px | ≈28% |
| 落叶堆（独立 56 公式） | 56 × depth | 61 px | ≈52% |

修复前松果≈人物身高的 44%，且≈落叶堆的 86%——一个松果接近一整堆落叶的大小，正是「与人物和周边物件尺度明显不协调」的量化来源。落地到 `TEXTURE_SPAN` 基线（`1.0`）后，松果≈28% 身高、≈54% 落叶堆，主次关系正确。

## 4. 修复

`scripts/exploration/near_path_scroll.gd`：

1. 新增命名常量（与既有视觉常量同区）：
   ```gdscript
   const FIND_GROUND_SCALE := 1.0
   # 地面可拾取实体的显示系数：对齐 KeepsakeArt TEXTURE_SPAN(30) 基线，去掉原 1.6 过度放大（issue #596）
   ```
2. 第 571 行：`1.6 * depth` → `FIND_GROUND_SCALE * depth`。
3. 第 395 行：`1.6 * layout.depth(anchor.y) * _cam_zoom` → `FIND_GROUND_SCALE * layout.depth(anchor.y) * _cam_zoom`（保证拾取飞行起点与地面上尺寸一致，无跳变）。

**可发现性不受损**：点击命中区为 `press_at()` 第 503 行固定 `point.distance_to(art_to_screen(entry.item)) <= 28.0`（28px 屏幕半径），与绘制尺寸无关；缩小美术不放大大击区，正符合 #596「可通过交互热区实现，不靠过度放大美术图」的验收建议。圆石/落羽同走 KeepsakeArt，等比缩小，相对比例保持不变。

**未改**：落叶堆（独立 `56/width*depth` 公式）、提篮内绘制（`:880` 用 `size=0.9`）、`TurtleArt` 等其它所有者逻辑，切片范围仅限近郊地面 finds 的显示系数。

## 5. 待办 / 边界

- 精确最终显示系数（1.0 为保守首刀；若制作人希望更接近真实比例可进一步降到 ~0.7 → ≈20% 身高）由 **Leader / ART-DIRECTOR 按实景校准**——`near_path_layout.gd` 注记明确「道路宽度和远景比例由 Leader 按实景校准」。
- **本环境无 Godot / Web 构建**，无法复现截图或录屏；运行时 Web 像素证据待 GAME-QA / ART-DIRECTOR 实机或用户 fresh build 验证（同 #180 缺口）。故 **#596 不关闭**，待上述验证。
- 关联：#152 / #153 / #565（近郊呈现与拾取体验）。
