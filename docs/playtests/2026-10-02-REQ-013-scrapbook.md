# 2026-10-02 · REQ-013 偶遇抓拍与旅人手账体验复核

**阶段：** 已合入并发布至 GitHub Pages。基线为正式 `game-e2d12b7`，它已有可打断的拍立得显影、11 类事件和三列滚动相册。此次改动只在确实遇见的画面中增加 3 类记忆、受约束的一次性题词变体，并把相册改为可翻的手账；不实现 REQ-011 世界回响或另一个 REQ-012 天空/自由构图。

## 验收步骤和结果

| 场景 | 观察与结果 |
| --- | --- |
| 大鹅卧姿 | 第一天、站姿、远处或草地上休息均不触发；第二天鹅实际位于 `pond` 区域，玩家靠近、实际完整卧姿 `rest` 帧出现时才入册。照片中为同一幅伏卧原画。 |
| 两只羊 | 分开不触发；真实位置接近且旅人在旁时照片同时含 `sheep_a` 和 `sheep_b`。 |
| 池边鸭鹅 | 第三天前、鹅/鸭不在池边、鸭子离鹅远或玩家只看见另一只鸭时都不触发；第三天**真正被取景的最近鸭**与鹅均在 `pond` 区域、相互邻近且旅人看见这同一对动物时才拍。同规则重复不新增照片。 |
| 题词和存档 | 成片保存按**所属规则的实际短句数**限制的 `caption_variant`；两句羊驼规则拒绝值 2，三句鹅规则接受值 2，越界/小数被拒；旧无变体照片维持原句，旧无日期照片只显示原标题。照片重开相册、磁盘重载、中英切换均不重新抽签；真实马照片不捏造“生气”。 |
| 手账操作 | 桌面双页有书脊与页码，390×844 竖屏单页；只有真实已拍记忆，空页不显示未解锁目标。鼠标/触屏按钮、触屏横扫和键盘左右键可翻；合上归还院子输入与 HUD。低动效静态换页。 |
| 回归 | 修复独立 reviewer 的三项问题后，`test/scrapbook_encounter_suite.gd` **20/20**；`test/photo_moment_render_suite.gd` **1162/1162**；`test/photo_moment_save_suite.gd` **42/42**；更新后的 `test/ui_interaction_suite.gd` **无失败**。修正后 `npm run verify:daily` 完整通过（基本 389、走路 410、动物家园 1005、物理院子 640，以及书页/旧场景和多视口测试）；Godot 没有脚本解析错误。 |
| Web 发布 | [GitHub Actions run 37025345857](https://github.com/narutojzm1-dot/youjia/actions/runs/37025345857) 对合并提交 `b560dec94f08a1597e2b834e74c41841893ba36b` 的完整验证、Godot 4.7.2 Web 导出和 Pages 发布均成功。正式清单 `game-release.json` 的 `sourceCommit` 为 `b560dec94f08a1597e2b834e74c41841893ba36b`、入口 `game-b560dec`、时间 `2026-10-02T15:15:56Z`。公开 Pages 实际下载的 `game-b560dec.pck` 为 **12,776,620 字节**，SHA-256 `e5b9c3f931b957ac4dd288e1c6786f6b9fc1d9ace946eac711e3bed723ac3d58`。本地候选导出为 12,776,636 字节，SHA-256 `8d473f93e958a15512b84c1b4b88205ea879861a275066a9ff82dc8d6cfae857`；正式哈希以 Pages 实际下载字节为准。 |
| Chromium 正式版 | 真实 Pages 页面返回 HTTP 200，`<html data-build="game-b560dec">`；版本化 JS/WASM/PCK 均返回 200。Chromium 以 1280×720 进入院子并打开手账，控制台无 JavaScript 错误。另用 390×844 查看新包的进入院子/打开手账路径，也无 JS 错误。新浏览器上下文没有历史存档，因此本次仅确认公开版启动和相册路径，**没有声称在此次公开版浏览器运行中再次自然遇到新事件**。第 8 天自然记录两羊靠近的既有截图仍是更早候选证据，不冒充正式版本次复验。 |

## 可视证据

所有原生图由 `test/scrapbook_visual_preview.gd` 在 Xvfb 中运行真实主场景和 YardWorld 抓拍采集；只使用仓库已有水彩纸、拍立得框和动物完整画作，不复印外部参考图片。

- [桌面：新羊群与鸭塘记忆双页](2026-10-02-REQ-013-scrapbook/desktop-sheep-book.png)
- [桌面：池边鸭鹅同框与留白末页](2026-10-02-REQ-013-scrapbook/desktop-duck-goose-book.png)
- [手机：鸭鹅照片中文单页](2026-10-02-REQ-013-scrapbook/mobile-duck-goose-zh.png)
- [手机：同一鸭鹅照片英文单页](2026-10-02-REQ-013-scrapbook/mobile-duck-goose-en.png)
- [Chromium 最终候选：自然抓到假期第 8 天两羊的末页](2026-10-02-REQ-013-scrapbook/web-candidate-last-spread.webp)
- [Chromium 候选：从院子打开相册后底层 HUD 隐藏](2026-10-02-REQ-013-scrapbook/web-yard-album.webp)

**遗留与下一步：** 旧规则的早期固定题词及旧存档无世界照片时沿用原有卡片降级展示，不能反写历史现场；更自由的玩家角度/构图属于并行 REQ-012，不在本切片。独立最终 SHA `bdd087a886b184a8f8f86dc30a8844b67ba7a593` 已批准；本地及 Actions `37025345857` 全量回归通过，正式 Pages 清单、实际下载 PCK 哈希和公开浏览器启动/手账路径已核对。
