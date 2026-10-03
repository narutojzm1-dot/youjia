# VERIFY-EXIT-GATE 验证记录

CODEX-LEAD；2026-10-03；基线072a072（最新牛候选be9ef7c仅art/docs，运行时代码未变）。工程督导#130已经受控复现旧包装器放过1/124/127，本轮只修复执行失败传播，不更改游戏逻辑或视觉。

## 实现与受控结果

`tools/lib/verified_godot.sh`用子shell保留调用方选项，在timeout→tee pipeline后立即捕获PIPESTATUS。两进程任意非零直接返回失败；退出0仍扫描SCRIPT ERROR/ERROR:/独立FAIL标记，扫描不可用也失败。daily仍采用原suite顺序，每次运行前先执行包装器契约测试。

`bash -n tools/lib/verified_godot.sh tools/verify_daily_life.sh test/godot_gate_test.sh`通过；`bash test/godot_gate_test.sh`得到GODOT GATE CONTRACT PASS 11。测试通过临时PATH mock注入，不启动真实300秒超时或真实崩溃，每项检查下一步是否被禁止；只合法退出0且无失败日志继续。

| 情况 | 结果 |
| --- | --- |
| 0 + PASS日志 | 继续 |
| 1 + PASS日志 | 阻断，不能用PASS文本掩盖进程失败 |
| 124 + 空日志（超时） | 阻断 |
| 127（命令不可用） | 阻断 |
| 139 + 空日志（崩溃） | 阻断 |
| 0 + SCRIPT ERROR / ERROR / AUDIT FAIL / FAIL: 四种日志 | 均阻断 |
| tee返回74 | 阻断 |
| 扫描日志不存在 | 阻断 |

严格真实 `GODOT=/tmp/youjia-godot-472/Godot_v4.7.2-stable_linux.x86_64 npm run verify:daily`修正后完整通过，最终进程exit=0（本地日志`/tmp/youjia-exit-gate-final-daily.log`）；11项门禁契约、原完整suite顺序、桌面/移动viewport及加载壳检查均完成。尚未合入/发布。过程中不清理引擎自动import，避免干扰后续套件。

## 边界和剩余风险

无套件成功完成标记也返回0的情况尚不能识别；不声称零退出等于断言完整执行。为每个suite定义可信完成协议、PR阶段workflow、存档替换恢复分别后续拆分，不一并关闭#130。没有为特定非零退出添加忽略规则；真实失败应调查，不能为赶发布降低门禁。

本片工具性改动，运行时、导出配置、存档和美术均不改，合入前无需伪造新Web体验截图。主线CI仍会执行严格回归、Web导出和Pages发布，合入后应核对其结果、公开清单/PCK哈希及版本启动并回写记录。

## 严格门禁揭出的套件退出缺陷

首轮真实回归在quiet_stay停止：打印QUIET STAY PASS 4后真实进程退出1，tee退出0。源码确认SceneTree.quit只请求退出，不立即返回；成功分支之后继续调用末尾quit(1)。quiet_stay、quiet_sky_look、still_catch、still_target_pulse、still_grass_glow、interaction_pose共六处均为同样控制流。只在各成功quit(0)后加return，失败断言与quit(1)保留，没有改世界行为或放宽门禁。六套逐套直接执行均exit=0；随后严格完整回归exit=0。首轮失败日志保留在`/tmp/youjia-exit-gate-daily.log`，不能算通过。
