# PR465 正式公开普通静观/移动后验预案（执行前）

执行者：CODEX-LEAD 委派 hotspot36_qa。预期源码 b9f68c3c5c4e70e16cefde9b4400bb1d553ff915；本稿不表示已发布或已体验。必须等待 root 的实际 Pages/manifest/PCK/十模块/许可绑定和唯一 browser 授权；当前只编译驱动，不启动 browser/Godot，不额外下载大 PCK。

## 来源与资源

驱动 `/tmp/camera465-public-driver.py`，新原件目录 `/dev/shm/camera465-public-qa`，绝不覆盖 camera400 候选或 photo464 公开资料。参数 URL/runtime/entry/PCK bytes/SHA/license bytes/SHA 均取 root 正式许可，不硬用候选 index 或旧公开包。只一 Chromium browser、fresh 390×844 context/page、DPR1、正常中文 no-preference，renderer-process-limit=1，实际内存样本记实，不开引擎。

每context before/after重新读取 game-release.json，核 sourceCommit、game-{source7}、save-{source7}；实取 HTML、动态 PCK、10 个版本存档模块和许可证，实际导航 HTML 与读取摘要一致、data-build 正确，保 loadedresponses。若来源改变或摘要不符，保存失败、关闭窗口通知 root，不替换来源掩盖差异。

## 唯一有限普通路径

正常标题“走进院子”→等约700ms与完整基线图→等约4700ms→两张短间隔静观原图→真实 ArrowRight 按下450ms再松开→约300ms后原图→约1500ms回稳图。输入以一批顺序命令执行，不把人工读图延迟混进短窗口。700/4700/100/450/300/1500ms是配置等待，真实点击及截图耗时由日志给出，不称精确引擎时钟。

仅本次普通静观和移动响应，不等待45秒鹅马预热、不改日序/时间/随机种子、存档、camera offset或 phase，不为稀有事件无限刷新。若一次未见静观，保原件写NOT VERIFIED，不扩第二轮刷样本，不新增横屏。本计划不做相册、照片、音频、#459键盘焦点、全存档恢复或实体手机结论。

## 独立结果栏

1. 可见自然静观→实际移动后普通视景回稳：按真实完整原图给结果。静态建筑位移作离线辅助，不将像素匹配当作读到引擎 camera offset=0；不把常规角色跟随横移当残留。
2. 顶部浅纸色空带：若仍出现明确记录“自然构图FAIL/遗留”，绝不与返回功能PASS混为整项通过。root已要求另在#400保留Producer背景/布局Owner，当前PR不扩大Main布局范围。
3. 同tick quiet→goose交接仅引用独立原生受控202checks，普通短路径没有交叉状态链证据。#400原用户2444×1502截图原因继续未证，不能称整个#400已修复。

结束after绑定→明确context和browser CLOSED→确认实际driver exit，立即给root释放窗口及内存/原PNG位置，随后离线README、analysis、execution、原预案及完整SHA256SUMS。不得自行开启下一项browser。
