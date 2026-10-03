# REQ-014-VERIFY · 鹅马摄影候选验证与修复

- Owner：`CODEX-LEAD-ASSISTANT`，2026-10-03。
- 父实现：[PR #65](https://github.com/narutojzm1-dot/youjia/pull/65)，基线 `6bd54ddc769bbe3b88e140d737b4978192d80a43`。
- 本切片仅修复、验证现有候选；不改写父分支，不接管 REQ-014，不制作 REQ-015 原画。
- 状态：已合入并发布；受控演出证据与自然触发试玩状态分别记录如下。

## 已复现并修复

| 问题 | 修复与验证 |
| --- | --- |
| 普通表情扫描在第一天提前拍摄“鹅骑马”，真实演出因已入册而不再触发 | 将该规则限定为演出完成专用；真实普通扫描断言不再产生该照片。 |
| 携草、携鱼、钓鱼时仍触发演出 | 保留现有互动的优先级；真实模拟回归覆盖三种占用情况。 |
| 点脚下、就近抚摸、行动按钮、暂停或相册无法立即取消 | 显式输入与 UI 退出走统一取消路径；验证玩家可见、镜头/黑边恢复、动物释放、无照片入册。 |
| 取消或完成后鹅仍悬在马背位置，可能落在不可行走区域 | 表演前保留位置与朝向，结束恢复原落点、比例和深度顺序。 |
| 固定角色比例令马和鹅在近景放大数倍，鹅藏于马身后 | 浏览器实图复现；使用 CastArt 已测量的角色比例，近景仅由相机提供，乘骑中的鹅绘在马身之上。 |
| 核心测试仍断言只有 14 类照片 | 更新为候选中的 15 类；界面仍不显示完成率。 |

## 运行验证

- 使用 Godot `4.7.2.stable.official.ed1daf0bf`，与项目正式导出版本一致。
- `test/goose_mount_suite.gd`：74 项通过；覆盖自然条件、阶段、中断、真实现场、实际写盘重载、稳定题词、旧有缩放、绘制顺序、已拍不重播与手机低动效。
- 初始复现用例使用真实场景与模拟入口，没有用 `debug_force_rule` 伪造完成事件。为测试边界指定动物位置和时间；这部分属于自动化场景证据，不冒充自然浏览器游玩。
- 完整 `npm run verify:daily` 使用隔离 XDG 存档；最终全量通过：核心 389、步态 410、动物日常 1005、物理院子 658、照片渲染 1242、照片存档 42、演出 74，以及其余交互、低动效、多视口和加载壳检查；无 Godot 脚本错误。
- 候选 Web 由 Godot 真实导出。浏览器使用 Chromium，无注入调试脚本或强制拍摄入口。

## 画面证据与限制

- 标准候选 Web PCK：12,777,772 字节，SHA-256 `2fbd5a08a3b12b54528ebd910e7b5bdd1cddbf26b99e473f2cbd7497eb686b03`。仅本地导出，非公网构建号。
- 标准候选 Chromium：1280×720 进入院子、点选散步、等待约 67 秒、打开相册；390×844 使用真实触屏入园。两种浏览器上下文无 JavaScript 错误。本次最终自然等待未稳定触发鹅马演出，不冒充自然偶遇验收。
- [首次浏览器审计暴露的错误近景](2026-10-03-REQ-014-verification/baseline-broken-close.webp)：早期补丁尚未修复缩放时，实际散步等待触发的画面。
- [修正后近景](2026-10-03-REQ-014-verification/controlled-corrected-close.webp) 与 [真实成片手账](2026-10-03-REQ-014-verification/controlled-corrected-album.webp)：使用临时 Web 验证场景预置动物位置和时间，然后由真实模拟完成演出和保存。与原生场景测试一样属于受控现场证据，不是自然偶遇或正式线上验收；临时场景未提交、未包含在标准候选包。
- [标准候选手机触屏入园](2026-10-03-REQ-014-verification/candidate-mobile-yard.webp)。原始 PNG 和执行日志保留在会话工作区。

正式乘骑画仍缺失：当前张翅/收翅画作是技术占位，不宣称脚掌接触马背、完整平衡姿态已达到最终美术验收。资源由 [issue #64](https://github.com/narutojzm1-dot/youjia/issues/64) 独立跟踪。

## 最新主线整合复核（2026-10-03）

- 在最新 main `31316aa24edb5e643cc8ef82fba8a1f8e1a490b3`（含 PR #81 云带与 PR #82 测试修复） 上重放 PR #65 与 PR #72；保留 REQ-011 关系系统、PR #74/#75 文档与互动改动、Grok 的 PR #77 递草动画，以及 Cursor 的 #81 云带、#82 UI 套件修复。
- Godot 4.7.2 `npm run verify:daily` 全套 PASS：generic 411、locomotion 410、animal-home 1005、photo-home 75、grass 368、grass-action 61、physical-yard 658、photo rendering 1242、photo save 42、goose-mount 74；目标、互动、hotspot、序列、viewport 与 loading shell 检查无失败。
- 最新本地 Web PCK：13,742,972 bytes，SHA-256 `56f58588ec046b6f4fe6eabffabc65affa21cc2eb5cc70c2c330ac87f1f7688d`。正式 Pages 构建以 `game-521e6c2` 标识；公网字节与哈希另列于下方发布核验。
- Chromium 1280×720 最新本地页面：HTTP 200、标题《悠长的假期》、一个 Canvas，无 JS 错误/请求失败；进入院子并切换至阴天云带画面正常；[浏览器截图](2026-10-03-REQ-014-verification/final-integrated-cloud-yard.webp)。当前最新树未完成长时自然演出等待，不声称完整事件已实际触发。候选体验并未自然触发完整演出。
- ## 合入与公网发布（2026-10-03）

- PR #65 最终 SHA `f7f2d0686753f798055809ef23c465d9fc237b0c` 获独立子代理 APPROVE，随后合入 `main`，merge commit `521e6c2180284ab80aa914ec78e0ed513af960ed`。审查确认 REQ-016 需求表仅有一行且 owner/status 与基线一致；运行时未发现阻断。审查备注：演出收尾把动物设回吃草状态，没有恢复其原先休息/闲逛状态；此项未构成阻断。
- PR #72 验证补丁已经包含在 #65 最终树中，故在 #65 合入后关闭重复 PR。
- Actions [37092968010](https://github.com/narutojzm1-dot/youjia/actions/runs/37092968010) 的完整验证、标准 Web 导出及发布步骤均成功；Pages 部署 [37093112683](https://github.com/narutojzm1-dot/youjia/actions/runs/37093112683) 成功。
- 公网 `game-release.json` 指向 `game-521e6c2` 与源提交 `521e6c2180284ab80aa914ec78e0ed513af960ed`，引擎 `4.7.2.stable.official.ed1daf0bf`。直接下载公网 PCK 为 13,742,972 字节，SHA-256 `d46351fbac8d1bbe3d11de110cdbe8001a7cb805bbae07b40e16ffe97be54c1a`。
- 对正式 Pages 入口做 Chromium 冒烟：HTTP 200、标题《悠长的假期》、`data-build=game-521e6c2`、1280×720 单 Canvas；无 JavaScript 错误或请求失败。这只是启动和画布冒烟；本轮没有自然观察到完整鹅马演出。乘骑角色画仍是技术占位，最终资源由 [issue #64](https://github.com/narutojzm1-dot/youjia/issues/64) 跟进。
