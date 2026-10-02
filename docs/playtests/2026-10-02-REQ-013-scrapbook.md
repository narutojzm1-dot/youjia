# 2026-10-02 · REQ-013 偶遇抓拍与旅人手账体验复核

**阶段：** 原生与候选 Web 完成，正式 GitHub Pages 尚待独立审查、合并和发布。基线为正式 `game-e2d12b7`，它已有可打断的拍立得显影、11 类事件和三列滚动相册。此次改动只在确实遇见的画面中增加 3 类记忆、受约束的一次性题词变体，并把相册改为可翻的手账；不实现 REQ-011 世界回响或另一个 REQ-012 天空/自由构图。

## 验收步骤和结果

| 场景 | 观察与结果 |
| --- | --- |
| 大鹅卧姿 | 第一天或站姿/远处不触发；第二天玩家靠近、鹅的实际完整卧姿 `rest` 帧出现时才入册。照片中为同一幅伏卧原画。 |
| 两只羊 | 分开不触发；真实位置接近且旅人在旁时照片同时含 `sheep_a` 和 `sheep_b`。 |
| 池边鸭鹅 | 第三天前、鸭子离鹅远、玩家不在旁时都不触发；第三天真实鸭鹅临近且玩家可见时拍下最近的鸭与鹅。同规则重复不新增照片。 |
| 题词和存档 | 成片保存 `caption_variant` 0–2，越界/小数被拒；旧无变体照片维持原句，旧无日期照片只显示原标题。照片重开相册、磁盘重载、中英切换均不重新抽签；真实马照片不捏造“生气”。 |
| 手账操作 | 桌面双页有书脊与页码，390×844 竖屏单页；只有真实已拍记忆，空页不显示未解锁目标。鼠标/触屏按钮、触屏横扫和键盘左右键可翻；合上归还院子输入与 HUD。低动效静态换页。 |
| 回归 | `test/scrapbook_encounter_suite.gd` **16/16**；`test/photo_moment_render_suite.gd` **1162/1162**；`test/photo_moment_save_suite.gd` **41/41**；更新后的 `test/ui_interaction_suite.gd` **无失败**。`npm run verify:daily` 完整通过（包括基本 389、走路 410、动物家园 1005、物理院子 640、书页/真实新照/旧场景和多视口测试）。 |
| Web 导出 | Godot 4.7.2 Web 导出 `dist/index.html` / `dist/index.pck` 成功；候选 PCK 12,775,740 字节，SHA-256 `8d2ea0182f3ff7e0d81f535eaadf67b0f205efc616d5ffcfc45dffe5a10fa562`。这是候选包**不是正式发布包**。 |
| Chromium 候选 | 公网临时测试服务器能加载 WASM 游戏。浏览器实际历史存档已有旧照片，标题页与院子 HUD 均能打开手账；翻到第 3/4 页和合上都可用。旧快照无日期只显示旧标题，未伪造“第一天”；院子打开手账时 HUD 确实隐藏。Web 候选未使用人为新照注入，三种新增事件的实际画面见下面的原生现场 fixture。 |

## 可视证据

所有原生图由 `test/scrapbook_visual_preview.gd` 在 Xvfb 中运行真实主场景和 YardWorld 抓拍采集；只使用仓库已有水彩纸、拍立得框和动物完整画作，不复印外部参考图片。

- [桌面：新羊群与鸭塘记忆双页](2026-10-02-REQ-013-scrapbook/desktop-sheep-book.png)
- [桌面：池边鸭鹅同框与留白末页](2026-10-02-REQ-013-scrapbook/desktop-duck-goose-book.png)
- [手机：鸭鹅照片中文单页](2026-10-02-REQ-013-scrapbook/mobile-duck-goose-zh.png)
- [手机：同一鸭鹅照片英文单页](2026-10-02-REQ-013-scrapbook/mobile-duck-goose-en.png)
- [Chromium 候选：标题页旧照片翻至最后双页](2026-10-02-REQ-013-scrapbook/web-candidate-last-spread.webp)
- [Chromium 候选：从院子打开相册后底层 HUD 隐藏](2026-10-02-REQ-013-scrapbook/web-yard-album.webp)

**遗留与下一步：** 旧规则的早期固定题词及旧存档无世界照片时沿用原有卡片降级展示，不能反写历史现场；更自由的玩家角度/构图属于并行 REQ-012，不在本切片。下一步待本 PR 最终 SHA 独立审查通过，再合并并核对 GitHub Actions、公开 release 清单及 PCK 字节哈希，用户届时在正式 Pages 试玩。
