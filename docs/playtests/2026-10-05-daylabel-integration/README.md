# REQ-20261005-027 天数标签集成验证

- 作者：GROK-CONTRIBUTOR，PR #345 `7944d1f5618f76a79a54e50676430a126e39d86c`；来源 #338。
- 集成基线：main `d2425099947b7ca7d17e8ea0cbd928e477e3ebf1`；本地组合提交 `8d33c495be0002e90acdc14a69df8f55c18d81cf`。Leader 按作者请求只补 daily 测试入口、REQ027 登记和本证据，无额外运行实现修改。
- Godot：4.7.2.stable.official.ed1daf0bf。独立运行 `test/day_label_layout_suite.gd`：173 checks passed。完整 `tools/verify_daily_life.sh` 退出码 0，包含新 `day_label_layout` 173 项；完整日志见 `daily.log`。
- Web release 导出成功；本地 `index.pck` SHA256：`71575e84c22d74b6766f092179e16321bfeda72593f33d999aefae30debf2205`。未上传/未部署，此哈希不是公开版本验收。

## 浏览器实际覆盖

独立 Chromium/Playwright context，分别使用 390×844、844×390 CSS 视口与 DPR2、DPR3。通过普通鼠标从标题进入院子，点击暂停，Escape 恢复，普通院子坐标点击，再旋转视口；未注入游戏状态。`result.json` 保存实际 canvas backing dimensions、DPR 和 console/pageerror（四组均为空）。截图按 CSS 尺寸保存，DPR由 JSON 实测而非截图像素推断。驱动 `browser.py` 仅用于本地候选测试。

亲看四组 `yard` 和四组 `resize`：天数深色字在浅纸底上可读，位于暂停按钮下方、同宽，无目标纸片重叠或屏外裁切。`pause` 显示实际暂停菜单；恢复后 `animal`/`resize` 为正常院子。坐标点击不保证每次都命中动物，因此不以这些帧宣称动物交互功能全覆盖。

## 边界

这不是实际手机硬件或听觉验收。未测试未合入 #322 的探索入口；其接入后需补入口与天数布局共存。中文自然截图；中英文、长天数和五视口几何由 173 项原作者测试覆盖，不冒称英文浏览器截图。没有扩大为既存竖屏场景构图裁切的修复。

待独立最终 SHA 审查，再由主负责人安排合入与公开发布验证。
