# REQ-019 集成候选验收

CODEX-LEAD；2026-10-03。保留 GROK 的 PR113 原提交 e8045c76beac63fabf452f14eec8365983431cfe；独立审核 CODEX-LEAD-REVIEW-PR-113 REQUEST CHANGES：daily脚本从100755退为100644，npm标准入口退出126。独立集成分支只恢复可执行属性并补实际绘制夹具/证据，不改写GROK分支，不接管PR99资源。

修复后标准 `GODOT=... npm run verify:daily` 在 Godot4.7.2 退出0，未检出SCRIPT ERROR/ERROR/FAIL；完整回归包含新增目标脉动5项。此前显式bash诊断执行不当作标准入口通过。

普通 Web release 导出成功，Chromium1280×720标题进入院子，无页面/控制台错误。[正常入口截图](2026-10-03-REQ-019-integration/normal-web.png)。候选 PCK 13,815,648字节，SHA256 `f55e00b634e44797c2da9cb9c4421cbc2a7b0beb3855b0e27c81d5b8f8cbbed6`，仅本地候选，不是正式发布。

[受控实际绘制](2026-10-03-REQ-019-integration/controlled-web.png)：夹具 tools/verify_target_pulse_render.gd/.tscn 实例化真实YardWorld并指定pet:cow，将玩家置于50px，调用真实_update_effects_overlay获取透明度，再交给独立SubViewport绘制。0.2/0.8两个时刻比较实际图像字节：低动效目标/庆祝像素相同，普通模式不同，四种状态均可见；另8项确认真实世界每次解析目标，合计16项零失败，Chromium无页面/控制台错误。这里只验证固定目标位置，不声称自然钓鱼或所有距离实玩。

受控Web临时切换project主入口并移除tools导出排除，之后完整恢复；正常导出仍排除tools/docs，夹具不进入玩家包。未尝试原生图形像素，原生覆盖为headless完整回归。此处为合入前候选记录；最终独立审核及正式发布结果见下节。

整合最新 main `7e02a7db873014ca25152141df1e8985511339d3`（PR114草堆低动效）时手工保留REQ019/020两行需求和两套daily套件。上述Web证据已重新导出；完整标准回归重新执行，最终结果与SHA审查写入集成PR门禁。PR114原独立审核记录已核对，不重做其功能。

## 最终审查、主线与首次发布

独立 CODEX-LEAD-REVIEW-PR-115 APPROVE 最终 `884b0b57bde43f37e4efd058d679bd16c681eb83`；独立重跑上述两个Web入口，并审查有效最终标准回归日志。有效整合后全量回归退出0，无SCRIPT ERROR/ERROR/FAIL，含目标5项、草堆4项、物理院子658项和viewport/loader。审核指出原PR113带入REQ016优先级降级，已恢复主线原值，不扩大本任务。

一次整合后的回归曾被维护者在测试期间restore自动import侧车干扰，后续资源路径失效；该次作废，不计通过。停止后从重新导入开始完整重跑并保持工作树稳定，以上有效结果来自这次运行。

PR115合入 `664dfdeb3151165502f0159402089cd556318e30`，原PR113因提交已在主线自动标合入。Actions [37119052380](https://github.com/narutojzm1-dot/youjia/actions/runs/37119052380) 回归/导出/发布成功，Pages [37119238179](https://github.com/narutojzm1-dot/youjia/actions/runs/37119238179) 成功。

公开game-release.json指向 `game-664dfde` / 同源commit。公开与raw gh-pages独立下载PCK均13,815,648字节，SHA256 `ec653674a078d3ae4e3b2887c5bbb19d7e72aab6ce962e05ab7bb31f31b9b2bf`；正式哈希与本地候选不同，明确区分。

公网Chromium1280×720核对HTML data-build=game-664dfde、首帧和标题进入院子，页面/控制台错误为0。[公网画面](2026-10-03-REQ-019-integration/public-yard.png)。公网这里只覆盖版本/启动，目标稳定的实际像素证据来自同运行时受控候选，不伪称自然钓鱼/全部距离或原生图形通过。
