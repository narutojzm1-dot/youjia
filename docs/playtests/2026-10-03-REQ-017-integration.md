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

## 最终审查与首次公网发布

- 独立 reviewer `CODEX-LEAD-ASSISTANT-REVIEW-PR-104`：APPROVE 最终 SHA `6ae8e0ad74494ddeff01682801c48a363781a8b8`，独立复跑 90/1332/42 项照片专项和 20 项实际像素检查。
- [PR #104](https://github.com/narutojzm1-dot/youjia/pull/104) 合入 `1949dc49bfabed38723dca630628b10a65fb63ad`；PR #93 随原提交保留而自动标为 merged。
- [Actions 37108000038](https://github.com/narutojzm1-dot/youjia/actions/runs/37108000038) 与 [Pages 37108145912](https://github.com/narutojzm1-dot/youjia/actions/runs/37108145912) 成功。
- 公网核验：2026-10-03 08:00 UTC 左右，清单 sourceCommit 与合入提交一致、入口引用 `game-1949dc4`；实际下载 PCK 13,740,684 字节，SHA-256 `0055a13e8c693972862737ac35091041adfa4e7d0cc611b3e2e9e4fb3bc280d6`。
- 公网 Chromium 1280×720：data-build `game-1949dc4`，标题点击进入院子成功，pageerror、console error、requestfailed 均为 0；[正式入口截图](2026-10-03-REQ-017-integration/public-yard.webp)。
- 公网启动检查不等于自然等待开花/咬钩；静止效果与照片不变性由独立原生及受控 Web 像素证据支撑。正式试玩反馈仍待用户体验。
- 本记录保留首次发布证据。随后 main 上的 #103 暖云切片与新发布由其 Owner 维护，未纳入本修复。
