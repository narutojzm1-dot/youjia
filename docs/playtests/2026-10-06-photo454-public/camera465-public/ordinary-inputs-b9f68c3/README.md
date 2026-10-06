# PR #465 正式 Pages：普通静观与移动返回后验

执行者：CODEX-LEAD 委派 hotspot36_qa。本包为正式公开页面独立复验，不复用 camera400 本地候选原图，不宣称 #400 整体已修复。

## 来源与实际运行

- URL：<https://narutojzm1-dot.github.io/youjia/>
- sourceCommit：`b9f68c3c5c4e70e16cefde9b4400bb1d553ff915`
- 正式 entry：`game-b9f68c3`；存档模块：`save-b9f68c3`
- 实际动态 PCK：27,090,748 B，SHA256 `2b719ae25bb58d91f4742e998faff212a3410a5ac1ecf47ed50c3fc7dbf0ca1f`
- 许可证：147,966 B，SHA256 `9215f5fdd50039a9b6f3d8f0271cbc21bbdf64b917fb118dd29c8a16b9974e00`
- 2026-10-06 UTC 00:25:35Z 开始，00:27:03Z 全部 context/browser CLOSED，实际驱动 exit 0。

before（00:26:05Z）/after（00:27:03Z）实际读取公开 manifest、HTML、动态 PCK、十个版本存档模块和许可证，全部 HTTP、源码与摘要通过，来源前后一致。实际导航 HTML 字节 SHA 与 before 相同，data-build=game-b9f68c3。实际页面加载 JS、WASM、PCK、十模块共13 responses 均200。许可证为单独 HTTP 校验，未操作许可 UI。没有新增发布动作或重导出。

## 普通路径：有限 PASS

唯一 browser、fresh 390×844 context/page、DPR1、正常中文、no-preference（实际只读 matchMedia reduce=false）。普通标题点“走进院子”，静站，真实 ArrowRight 按下450ms再松开，等待回稳。无动物招呼、照片、相册或其它焦点来源操作，也没有强制状态或随机种子。

| 原图 | 直接观察 |
| --- | --- |
| portrait-title.png | 实际标题入口 |
| portrait-01-entered.png | 院子基线与站立角色 |
| portrait-02-stillness-a.png | 站立后院屋整体下移，视野抬向天空 |
| portrait-03-stillness-b.png | 第二静观帧继续显示变化 |
| portrait-04-after-movement.png | 实际移动后，角色响应、院屋高度接近基线 |
| portrait-05-settled.png | 院屋垂直高度回稳；普通横向角色跟随保留 |

输入后普通画面可返回，未发现本有限窗口内冻结、崩溃或 page error。console 为引擎信息与加载时序，无错误。配置等待700/4700/100/450/300/1500ms及截图自身耗时均留 result.json；不把这些值当精确引擎时钟。命令为一批顺序执行，未夹人工读图延时来错失短窗口。

离线原图烟囱纹理近似匹配给出的相对位移为：02 `(0,+123)`、03 `(0,+142)`、04 `(-26,+7)`、05 `(-27,0)` 像素。详见 landmark-analysis.json 的基准框与MAE。该值是图像地标辅助，不是读取引擎camera offset=0，也不把普通横向跟随视为静观残留。普通按键后回稳可见；没有读取引擎信号断言具体退场分支或排除所有自然计时因素。

## 自然构图：遗留 FAIL

02/03 中院子背景上边缘分别在约 y=123 /142，顶部 HUD 下留出浅纸色空带。04 缩至约7px，05 顶部恢复背景。故静观“可以退出”与“自然构图通过”必须分列：本公开版本顶部空带仍是具体可复现的构图缺陷，不能写成整个 #400 已解决。

保留 Producer 对背景/布局原 Owner 与 Leader 协作后续范围，本包不临时改 Main 布局或扩展 #465 World 交接修复。#400 原用户2444×1502截图及先行操作没有复现，其因果仍未证。

## 明确未覆盖

- 初次入院短窗口，没有等待 `_day_elapsed >= 45.0` 秒鹅马预热，没有普通同tick quiet→goose 接管证据；独立受控原生202checks不能冒充本普通浏览器路径。
- 未读取/写入 quiet_active、phase、camera、存档、时间、随机种子；初始化脚本只监听first-frame完成事件，其余为普通鼠标/键盘输入与只读来源/系统偏好。驱动有只读DB能力，本次并未调用。
- 未追加1280宽屏、未刷新重试稀有事件；原2444×1502、真人触屏、英文/降低动态、#459键盘焦点、音频听验、完整存档可靠性或全玩法没有本包结论。
- 原图6张全部完整保留，无裁剪、修补或背景清理，不把候选图当正式图。

## 归档与资源

run.py 为实际驱动；result.json 含所有命令、截图请求/完成UTC及单调时钟、前后绑定、实际加载responses、console/errors与关闭时刻；execution.json 记录实际执行器exit及内存样本。expected-release.json是root授权期望值，真正读取结论以result.json为准；predeclared-plan.md保留执行前原案。SHA256SUMS覆盖除自身以外全部文件。

启动前内存样本15,825,960,960 B，已观测最高样本16,951,836,672 B，关闭后15,608,950,784 B；未连续测量，不称严格峰值。仅一 Chromium/SwiftShader/renderer-process-limit=1；无本地Godot或第二browser。关闭后只离线整理。
