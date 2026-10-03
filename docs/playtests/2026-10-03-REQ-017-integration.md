# REQ-017-VERIFY · 低动效道具集成验证

日期：2026-10-03。Owner：`CODEX-LEAD-ASSISTANT`。父需求与原绘制实现归 `GROK-CONTRIBUTOR`，保留 PR #93 的原提交。

## 审查与修复

原候选 `ac0049e45db0d8940b760ac69c2233ae10b4cd87` 经独立 reviewer `CODEX-LEAD-ASSISTANT-REVIEW-PR-93` REQUEST CHANGES。切换全局低动效会改变已保存照片中的花姿、水圈与提示透明度，且直接引用 Autoload 导致标准独立脚本测试编译失败。

世界传入当前布尔状态；道具只读捕获状态，JSON 清理保留该字段。缺省旧照按普通相位绘制；非法类型拒绝。未改玩法计时或主存档版本。原 PR 基于旧 main 时全量验证还命中后来已修复的仰望天空中断问题，已合入最新主线 `6d1e8a6` 再验。

## 已执行证据

- Godot 4.7.2 `tools/verify_daily_life.sh` 全量日常回归退出 0，含照片渲染 1332 项、照片保存 42 项、鹅马 74 项与加载壳检查。
- Godot 4.7.2 标准 `test/interaction_photo_suite.gd`：90 项通过。覆盖现场两类道具、两种动效设置、真实捕获 → JSON → 清理 → 相册回放、拍摄后切换设置、旧照缺省和非法状态。
- 原生 X11 / OpenGL Compatibility / Mesa llvmpipe：`tools/verify_still_props_render.tscn` 20 项通过。嫩芽、开花、收获、水圈、咬钩各验证低动效跨时间像素不变、普通动效跨时间像素变化、两种捕获模式切换偏好后像素不变。
- Chromium 受控 Web 入口：同一 20 项真实像素检查通过，页面错误和控制台错误均为 0；[画面](2026-10-03-REQ-017-integration/controlled-web-props.webp)。
- 普通 Web 包以正式主场景导出；Chromium 1280×720 从标题点击进入院子成功，页面/控制台错误为 0。此项仅验证启动，未宣称自然开花或咬钩验收。
- 真渲染使用受控状态构造，不冒充自然等待到开花或咬钩。正常入口与受控入口分开导出；工具不随正式 Web 包发布。

最终 SHA 审核、正式部署与公网版本尚未在本记录中宣称完成。
