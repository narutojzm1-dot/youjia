# REQ-019 集成候选验收

CODEX-LEAD；2026-10-03。保留 GROK 的 PR113 原提交 e8045c76beac63fabf452f14eec8365983431cfe；独立审核 CODEX-LEAD-REVIEW-PR-113 REQUEST CHANGES：daily脚本从100755退为100644，npm标准入口退出126。独立集成分支只恢复可执行属性并补实际绘制夹具/证据，不改写GROK分支，不接管PR99资源。

修复后标准 `GODOT=... npm run verify:daily` 在 Godot4.7.2 退出0，未检出SCRIPT ERROR/ERROR/FAIL；完整回归包含新增目标脉动5项。此前显式bash诊断执行不当作标准入口通过。

普通 Web release 导出成功，Chromium1280×720标题进入院子，无页面/控制台错误。[正常入口截图](2026-10-03-REQ-019-integration/normal-web.png)。候选 PCK 13,815,648字节，SHA256 `f55e00b634e44797c2da9cb9c4421cbc2a7b0beb3855b0e27c81d5b8f8cbbed6`，仅本地候选，不是正式发布。

[受控实际绘制](2026-10-03-REQ-019-integration/controlled-web.png)：夹具 tools/verify_target_pulse_render.gd/.tscn 实例化真实YardWorld并指定pet:cow，将玩家置于50px，调用真实_update_effects_overlay获取透明度，再交给独立SubViewport绘制。0.2/0.8两个时刻比较实际图像字节：低动效目标/庆祝像素相同，普通模式不同，四种状态均可见；另8项确认真实世界每次解析目标，合计16项零失败，Chromium无页面/控制台错误。这里只验证固定目标位置，不声称自然钓鱼或所有距离实玩。

受控Web临时切换project主入口并移除tools导出排除，之后完整恢复；正常导出仍排除tools/docs，夹具不进入玩家包。未尝试原生图形像素，原生覆盖为headless完整回归。正式发布及独立最终SHA审核待完成，不能宣称已上线。

整合最新 main `7e02a7db873014ca25152141df1e8985511339d3`（PR114草堆低动效）时手工保留REQ019/020两行需求和两套daily套件。上述Web证据已重新导出；完整标准回归重新执行，最终结果与SHA审查写入集成PR门禁。PR114原独立审核记录已核对，不重做其功能。
