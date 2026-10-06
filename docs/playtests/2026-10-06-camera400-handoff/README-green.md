# #400 预热镜头交接：最小方法修正与专项绿测

接续 `README-before-fix.md` 的真实红测。原单已授权 Leader 在共享关系框架内，仅修改 `YardWorld._tick_quiet_sky_look`：只有鹅马 `phase>=0`（已经发新 focus）才 yield；`wait>0` 的预热仍阻止新静观，但保留已有 quiet active 与剩余 hold，允许既有移动取消及自然到期。没有改 Main、鹅马事件方法、参数时长、缩放、输入、背景、探索、存档或资源。

最小修正源 `684952ed59c1b2bc5edbe89e0fc4bd71f24e4ae4`，tree `d7903a378c372259ebd5ba118cbe26347dc7a2d7`。仅该 World 方法、新组合测试/UID、daily 入口及准确正计数整行完成映射；测试 `.gd` 与原红测 `3cdd2439d4a33b7085e00f12b2c42c48c7604355` 的 blob **完全相同**。新自动生成 UID 单独列入，未把其它 Godot 自动 import/UID 修改 stage。

2026-10-05 23:32:20–23:32:40 UTC，在独占 Godot 4.7.2 窗口依次实际执行，所有子进程和外层 runner exit 0：

| 检查 | 实际完成行 |
| --- | --- |
| 严格门禁 mock | `GODOT GATE CONTRACT PASS 50` |
| 新交接组合 | `[camera400-handoff] PASS: 160 checks []` |
| 旧静观天空 | `QUIET SKY LOOK PASS 15` |
| 旧鹅马场景 | `[goose-mount] PASS: 92 checks []` |
| 旧静候 | `QUIET STAY PASS 4` |
| 旧低动效 | `MOTION PREFERENCE NATIVE PASS 18` |

所有神态/时钟/位置设置均为明确受控 native fixture；没有浏览器或普通玩家复现声明。每个专项使用独立 `/tmp/camera400-green-state/<suite>/{data,config,cache}`，匹配 `YOUJIA_TEST_ISOLATED_DATA`，没有复用红测或其它试玩存档。

新套件由真实 Main._process 读取 Input 动作、推进 World.tick 并消费实际 focus/release，持续推进至旧 hold 之后，同时检查目标与实际插值偏移。42 条实际轨迹还保存 `Camera2D.position`。在每种 reduced 设置内，以 quiet-only 正常恢复控制为基准、实际人物坐标一致的各场景对比，绿测 Camera2D.position 最大差 **0.00019301011123806517 world px**；红测短预热中断后保留了旧的 `(19.25,-52.5)` 目标和实际插值偏移。计算依据是实际轨迹，不是重新实现相机公式；输出 `camera-position-control-comparison.json`。这项是引擎对象位置观察，不冒充截图、渲染后 viewport canvas transform 或自然游玩证据。

当时 160 项覆盖：仅静观取消；预热中移动；鹅马距离失去资格后静观剩余时间不中断、之后正常释放；剩余 hold 在预热内自然结束；旧静观先自然到期后，phase 0 新焦点建立且移动取消正常。**独立 reviewer 指出这份 160 项证据没有覆盖旧静观仍 active 时的同 tick 接管**：quiet 从 6.25 秒开始观测，hold 只剩约 3.25 秒，小于 3.5 秒预热。原轨迹明确是先 release 再新 focus，不能称 active-to-active 接管已验；后续新增正例另绑定新测试 SHA/计数，不把新断言套到本历史日志。

原始证据在 `green-specialized/process-results.json`、各 suite 原日志/engine 日志、`camera400-traces.json` 和 `result.json`；所有红日志原样保留。**完整 native daily 和 Web 导出尚待与 PR464 最终源码组合后一次执行**，没有拿旧 73 套基线作为最终全回归。独立终审、PR、正式发布、普通 Web 体验均尚未执行。本切片不关闭 #400，Producer 对用户原截图、天气/resize/探索返回的验收保持开放。
