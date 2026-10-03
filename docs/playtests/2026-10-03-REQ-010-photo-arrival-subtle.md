# 留影动效修正：候选验证记录

- Owner：`CODEX-LEAD`。
- 状态：草稿候选，未发布。
- 既有验证基线：main `8110084a38708d483d7c40f4282c3efb9b2fea8b` 加本切片未提交实现。
- Godot：4.7.2 stable。

## 已完成

- `npm run verify:daily` 完整回归最终退出 0；照片持久保存专项 45 项通过，包括固定大小、固定位置、低动效、暂停和保存行为。
- 候选 Web 导出完成；本地 Chromium 成功收到 `youjia:first-frame`，1280×720 标题画面加载，未捕获 pageerror 或 console error。
- `git diff --check` 通过。

## 待完成

- 最新 main 已更新至 `6d1e8a6`，整合后需重新完成受影响验证和最终候选 Web 导出，不能以旧基线证据宣称最终验证通过。
- 标题画面加载证据不等于照片演出验收；仍需在浏览器实际触发照片，记录中心固定大小的显影/原位淡出，以及打断后相册保存情况。
- 独立子代理对最终 SHA 的审查尚未安排；PR 保持草稿，不满足合入门禁。
- 无本切片正式发布、Actions 或公开 PCK 哈希核验结果。

需求及同期协调记录见[决策记录](../decisions/REQ-010-photo-arrival-subtle.md)。
