# #400 静观天空 → 鹅马预热的镜头交接保底

Agent-ID：CODEX-LEAD；内部实施 `gate130_completion`，独立审阅 `relationship45_qa`。北京时间 2026-10-06；下述日志原始时间采用 UTC。

静观已持有镜头、鹅马仅进入预热时，原代码会提前清掉静观所有权和剩余计时，预热中断后留下旧相机偏移。本切片只将 `YardWorld._tick_quiet_sky_look` 的“实际演出已接管”与“候选预热”分开：预热保留原 hold，移动取消或原计时到期可释放；只有真正 phase ≥ 0 才无 release 地让出给新 focus。没有增加预热开始时回跳或延长静观时间。

按 [Leader 原单协助认领](https://github.com/narutojzm1-dot/youjia/issues/400#issuecomment-6005299861) 实施。GAME-PRODUCER 仍负责 #400 用户原截图、构图、resize、天气及探索返回的总体验收。本条件分支已受控复现，**未证明它就是用户原截图根因，不关闭 #400**。Main、背景、输入、探索和存档生产代码未修改；没有新玩法或资源决定。

## 来源与最小改动

原生产基线 `b300da74bf157de3f152e63331096cb1eb28b3f7`。只读源码身份及其与 9623 的等价记录在 [原始源码索引](readonly-source-index.json)、[基线核对](readonly-b300-source-comparison.json)。World.tick 先运行鹅马，再运行静观，最后处理 focus 倒计时；鹅马 wait < 3.5 时没有发新 focus，原静观却已 yield。后续取消预热不发 release，且静观计时被清掉。这是本次新验证的交接空档，不重复认领原单已有的 -133 条件数学分析。

除文档外，相对已合入 main `49596fa93bff3c29edfe441898017158c6e469a3` 仅六文件：World 的一个方法；新组合测试及 UID；daily 登记；完成行登记；该完成行的 fake process 边界测试。保留 PR464 原作者及最新 main 的真实祖先；[正式 main 整合](official-main-integration.json) 证明整合前后整个 tree 都与实测 `33bd42534d87ebd6e0cb0087d7ee0eaf258f548e` 相同。这里的“正式 main”指已合入基线，不是本候选已发布。

## 原代码红测、修正绿测与独审补覆盖

下表与本页的 v1/v2/组合运行 SHA 是隔离本地测试提交，不承诺这些提交对象已上传 GitHub。最终远端 PR 将按实际 main49596 祖先提交同一候选 tree；须由独立审阅将 remote SHA 与本地最终 tree/实测非文档内容重新绑定。原代码 b300、同一测试 blob、完整红绿日志和最终保留的测试文件可复核；PR464 原作者祖先通过实际 main49596 保留。

| 版本 | 原生产代码 + 测试 | 最小修正 + 同一测试 | 真实结果 |
| --- | --- | --- | --- |
| v1 | `3cdd2439d4a33b7085e00f12b2c42c48c7604355` | `684952ed59c1b2bc5edbe89e0fc4bd71f24e4ae4` | 原红 exit1、160 checks / 30 失败；绿 exit0、160 checks；各 42 条轨迹 |
| v2 | `96612f759eb51c50eebe2f2a4eaf14c6b8ade1e4` | `95b11e8255ee1c9532b6428a0b2914574dec6e97` | 原红 exit1、202 checks / 34 失败；绿 exit0、202 checks；各 54 条轨迹 |

v1 原件在 [红测](before-fix-suite.log)、[绿色专项](green-specialized/camera400_handoff-engine.log)。独审发现 v1 的实际接管场景静观只余 3.25 秒，短于 3.5 秒鹅马预热，因此观察到的是先 release 再 focus，不能证明“旧 quiet 仍 active 时同 tick 不误 release”。旧报告已收窄表述，保留日志，不冒补测覆盖。

v2 在正常与低动效各增加较早 quiet 开始的真实组合：接管前 `phase=-1`、`wait≈3.5`、`quiet_active=true`、`focus_seconds≈0.4`，下一次实际 Main tick 只增加新 focus，没有 release；新目标为 `(14.875,46.375)`，随后取消归零。两组测试 blob 均为 `2a4da8d81264db1e5e902e5502ef27cfd49d35da`，原生产代码在新增前置条件也失败。见 [v2 来源](v2-source-pair.json)、[完整红日志](v2-pair/red-v2.log)、[绿日志](v2-pair/green-v2.log)、[54 条绿轨迹](v2-pair/green-v2-traces.json)。独立审查逐条复核了该缺口的解除。

最初 runner 估算 204，真实红测完整结束为 202 后才在 runner 错误预期上停止，未进入绿测；[修正记录](v2-pair/runner-count-correction.json) 保留错误和续跑经过。没有重跑红测或更改断言凑数量，随后只运行绿色与 mock。日志/预检里的 `expected_*`、`not yet run` 与 `engine_executed=false` 是各阶段开始时的快照，完成结果以其后的真实日志及 process-results 为准，不倒改历史。

测试实例化真实 Main/World，使用 `Input.action_press` 并驱动原 `Main._process`，信号消费及插值保持真实代码。固定种子、时间、演员和玩家位置、手动推进 tick 是明确的 native 夹具，不是普通玩家自然遇见。断言覆盖目标偏移和足够平滑后实际 `_cam_offset`、Camera2D.position 恢复；[控制样本比较](camera-position-control-comparison.json) 是对象位置，**不把它当渲染像素/画布变换证明**。移动意图可能受碰撞挡住，不能将此说成实际走路舒适度体验。全部使用独立 XDG 与 `YOUJIA_TEST_ISOLATED_DATA`，未写其他候选或试玩存档。

## 完整组合回归与 Web 导出

实际运行源 `33bd42534d87ebd6e0cb0087d7ee0eaf258f548e`，tree `d629f692a58a2abfb847078fb8e9bac472833b49`，保留 v2 修正与 PR464 `b472b6a59f214da5716c87567baac77533edc0eb` 双方真实祖先。Godot 4.7.2。

| 实际执行 | UTC 时间 | 结果 |
| --- | --- | --- |
| 完整 daily | 2026-10-05 23:41:52–23:49:12 | exit0；75 套测试 + import = 76 次 Godot 启动；包含 camera202、photo039 1290、mat550、disabled4400；两项 Node 程序完成 |
| 完成行 mock | 包含于 daily；此前 v2 独立运行亦 exit0 | 新格式 14 项，合计 64 项 |
| 保留策略 Python | 23:49:12 | 11 tests，exit0 |
| 原 publisher 本地 fixture | 23:49:12–23:49:13 | 临时 bare repo、两构建及旧版本模块保全，exit0；不是正式发布 |
| 严格 Web release export | 23:49:13–23:49:19 | 既有低层进程/日志 guard 通过，exit0；import/export 不伪造 suite 完成行 |

实际导入有 36 条 `Missing UID recreated` warning；逐路径与[独立清理清单](generated-cleanup-before-integration.json)的 36 个自动生成、未跟踪 UID 对应，源码原本未跟踪这些 `.uid`。这不是零警告运行，没有因此省略原件或重导出；独审核对通过，未见对应 ERROR。

直接进程退出码、完整原始日志及 SHA256 在 [process-results](combined/process-results.json)、[结果](combined/result.json)、[daily](combined/daily.log)、[逐套完成审计](combined/daily-completion-audit.json)、[导出](combined/export-engine.log)。daily 内逐套成功由现有 fail-fast wrapper 与外层真实 exit0 支持，并逐块核对完整完成行；没有额外采集每个 Godot PID 的退出码，不能冒直接逐 PID 遥测。

完成行要求严格整行、正数 checks 和空失败数组。新增 14 个 fake executable 例实际调用同一个 wrapper，见 [原件](v2-pair/gate-contract-v2.log)；零计数、非空失败、缺/错/截短标记、同一行前后缀或拼接、非零进程退出和末尾 ERROR/FAIL 均拒绝。**两条分别合法的独立完成行仍可接受**，既有通用契约只保证至少一条；本次每 suite 实际一条是观测结果，不是唯一性承诺。历史 50 项日志仍属于旧版本，不拿它冒新增覆盖；fake 的 204 只是合法正数样例，不是原生断言数。

候选 PCK **27,090,748 bytes**，SHA256 **`89e2e1e3b0b224a1ccd9e9e245addab2233eb3b351a01b1efb25f871f15556e3`**。九个原始导出文件在 [导出 manifest](combined/candidate-release.json)；按同源 Git 内容补十个存档 `.mjs` 与许可页后的有限试玩包在 [preview manifest](combined/candidate-preview-release.json)。这是本地候选，不是 Pages release manifest。引擎窗口已释放，清理自身 ignored 导入缓存有 [记录](cleanup-after-engine.json)，原始日志和 PCK 保留。

## 浏览器、审查与发布边界

独立 QA `hotspot36_qa` 于 2026-10-05 23:52:22–23:53:29 UTC，在唯一 Chromium 的一个 fresh context 中实际完成 390×844 / DPR1 / 中文正常动效：标题进院→普通静站两帧→真实 ArrowRight 按下 450ms 后松开→回稳。驱动 exit0，context 于 23:53:14 关闭；page error/crash 未见。前后两次 HTTP 实取 manifest、HTML、PCK、十模块和许可页，同源/长度/哈希通过；实际导航 HTML 与所核字节一致，loaded resources 均 200。完整 [QA报告](browser-candidate/README.md)、[结果](browser-candidate/result.json)、[退出与关闭](browser-candidate/execution.json)、[原图校验](browser-candidate/SHA256SUMS) 均逐字节保留。许可页只单独 HTTP 核对，不冒打开许可 UI。

**普通返回路径有限通过，构图仍有遗留。** 原图 [01 基线](browser-candidate/portrait-01-entered.png)、[02 静观](browser-candidate/portrait-02-stillness-a.png)、[03 静观](browser-candidate/portrait-03-stillness-b.png)、[05 回稳](browser-candidate/portrait-05-settled.png) 可见静观后建筑下移，输入后回到基线高度。固定烟囱纹理离线近似匹配给 02/03 的 `(0,+112)` / `(0,+138)`、05 的 `(-28,0)` 像素位移；这是有非零 MAE 的图像辅助测量，不是内部 camera 值或准确因果证明，横向跟随不能误算静观残留。

静观时背景上边缘下移至约 y112/y138，HUD 下方露出浅纸色空带，**不通过自然构图验收**。root 与实施者均亲看原图；保留给 #400 原 Owner GAME-PRODUCER 与 Leader 后续协作，不扩大本 PR 的一个 World 方法修复范围，不声称画面自然或构图全部通过，也不据此断言原用户 2444×1502 截图同因。

浏览器没有注入 camera/随机种子/日序/时间/存档等业务状态；也没有达到 45 秒鹅马预热条件，因此不能把这次普通静观→移动称为交叉状态链的 Web 端到端证明。未追加 1280、未测降低动态/英文/真机触屏/听验/完整存档链；没有从图像排除所有自然计时因素。#400 原图来源、resize/天气/探索返回总体验收仍未完成，不要求制作人重复批准已授权的共享框架修复。

本归档提交尚待最终 SHA 独立审核及真实 PR CI；合入、公开 manifest/PCK 核验和正式浏览器结果由 Leader 分阶段记录。本页不声明本候选已合入或已发布。原始浏览器 before/after `index.html` 自带 EOF 空行，完整 `git diff --check` 仅报这两项；为保 HTTP 字节哈希不改原件，排除这两份 raw HTML 后其余全部改动无空白错误，见 [文档检查](docs-validation.json)。运行驱动在 [drivers](drivers/) 中保留当时隔离路径与失败预期；它们是历史复现实验脚本，常规维护入口是生产目录中的 `test/camera400_handoff_suite.gd` 和严格 daily。
