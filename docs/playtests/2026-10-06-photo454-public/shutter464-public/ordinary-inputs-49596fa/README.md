# PR #464：正式 Pages 快门题词暖纸底普通路径后验

执行者：CODEX-LEAD 委派 `hotspot36_qa`。本包为真正公开页面的两次独立普通首照，未复用 #461 本地候选截图。运行 2026-10-05 UTC 23:56:21–23:58:54，实际驱动退出码 0，全部 context/browser CLOSED。

## 实际来源

- 页面：<https://narutojzm1-dot.github.io/youjia/>
- sourceCommit：`49596fa93bff3c29edfe441898017158c6e469a3`
- entry：`game-49596fa`；存档模块目录：`save-49596fa`
- 动态实际 PCK：27,090,652 B；SHA256 `c851ac2b66ef6bba5211b7ba8488173c6b6a336ee7508d6150a5f5ccd488f930`
- 许可证：147,966 B；SHA256 `9215f5fdd50039a9b6f3d8f0271cbc21bbdf64b917fb118dd29c8a16b9974e00`

每个 context before / after 都重新读取公开 game-release.json、HTML、实际动态 PCK、10 个带版本目录的存档模块和许可证。四次来源一致、HTTP及哈希全部通过；每次实际导航 HTML 字节哈希等于当次 before，html data-build 等于 game-49596fa。两个页面实际 loaded JS/WASM/PCK/10模块 response 均 200。许可证是单独下载验证，未声称操作许可 UI。完整绑定、请求 URL、console 和输入时间都在 result.json；包体下载后已释放，归档保真实摘要与原 HTML/manifest，不存大 PCK/WASM 副本。

## 普通执行与结果

单一 Chromium browser，390×844 与 568×320 两个 fresh context 严格串行，任何时候仅一 context/page。前者 23:57:38Z 关闭；后者 23:58:19Z ready，23:58:54Z 关闭。两者 DPR1、中文、no-preference，实际系统偏好只读 reduce=false。使用原普通标题“走进院子”→点击近羊→自然新照片；连续完整原图捕捉后，只等待自然退场，再实际“翻开手帐”看照片、点“合上”回院。

| 范围 | 竖屏 | 短横屏 |
| --- | --- | --- |
| 标题/院子普通入口 | portrait-title / portrait-01-yard-before | landscape-title / landscape-01-yard-before |
| 清晰题词暖纸底与完整新照片 | portrait-02-arrival-03、04 | landscape-02-arrival-04 |
| 自然退场，无关闭照片输入 | portrait-03-after-natural-dismiss | landscape-03-after-natural-dismiss |
| 手帐里同一新照片可见 | portrait-04-album | landscape-04-album |
| 普通合上返回院子 | portrait-05-album-closed | landscape-05-album-closed |

上述有限路径 **PASS**。所有列出的文件均为 `.png` 原图，无裁剪或人工清理；早帧、淡出帧、自然背景变化也全部保留，共 37 张。捕捉批次实际为竖屏12帧、横屏15帧，30/50ms仅为额外等待，截图本身耗时明显，不声称这是精确引擎帧间隔或完整帧率录像。早/淡出画面不当作完整 hold 的纸底判据。

照片题词“旅人随手拍下了这一刻。”在选中完整帧呈现暖纸底、深色文字。原图像素辅助值见 analysis.json：竖屏(195,232)在完整03/04为RGB(252,240,224)，短横(284,13)完整04为(254,246,232)；这只是截图实际采样，不宣称等于源码平涂色或整个面板每点一致。

只读 IndexedDB 为每个 fresh context 保存一个不同 store_id，均 generation=2，album 和 photo_moments 含 `sheep_pet_gentle`，day1/sun。它仅辅助支持普通操作产生了新照片；实际手帐原图是用户可见验收证据，DB 不替代视觉判断。本次没有关页再开恢复步骤，不冒充恢复/完整存档可靠性验收。

## 短横重叠和边界

568×320 完整帧中题词纸条约 x=183–386，确实叠在目标提示背景的右侧；本次“目标：窗台花箱 / 看看花箱·空格/按钮”的字位于左侧，实测文字没有被遮。结论仅针对这段实际短文本。更长目标文案、英文和普通 UI 内降低动态均 **NOT COVERED**，不使用内部 locale、motion 或强制 play 调用补齐。不以“背景区域有重叠”误写这次实际文字已遮，也不据短文本通过宣称所有长文本无冲突。

保留原页其它可见布局：竖屏自然静观可出现顶部浅色空带，短横院子画面较小。这些不是本次题词变化的全局画面验收，camera400诊断及旧 #400 原截图因果不纳入本包；没有执行 #459 键盘焦点诊断。

无声音听验、无实体手机/触摸、无旧存档迁移/并发/后台恢复、无全相册照片种类覆盖。无业务状态、存档、种子、时钟写入；操作仅真实鼠标输入、截图与只读来源/DB。初始化脚本只监听 first-frame 完成事件。

## 原件与关闭

run.py 为实际驱动；result.json 含输入、截图请求/完成的UTC与单调时钟、源绑定和实际响应；两份 `*-04-album-db.json` 为只读原始值；analysis.json 是离线图像采样与边界；execution.json 留执行器退出、关闭与资源样本。预案保留原“未执行”文案作为执行前原件。

Chromium 使用 SwiftShader 和 renderer-process-limit=1；启动前内存样本15,706,345,472 B，最高已记录样本17,048,829,952 B，关闭后15,677,206,528 B，非连续测量故不称真正峰值。后续整理不启动新浏览器或引擎。SHA256SUMS 覆盖除自身外全部原件与报告。
