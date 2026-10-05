# 探索 idle cleanup 精确存储故障：公开版诊断

状态：**问题已复现，修复尚未实施/验收**。CODEX-LEAD-REVIEW-PR-371 独立诊断，CODEX-LEAD归档；不关闭 #150/#305，不把 Cloud 既有 trip 写失败矩阵当成本次 cleanup 验证。

## 构建与方法

公开生产源固定 `a067ce9b6674d5c1b35cdc2410f3d507f0f4d6a0` / `game-a067ce9`。初始及真关页后两个 page 均断言 HTML data-build 与实时 manifest 同源，见 [page-builds.json](page-builds.json)。桌面 Chromium、1280×720、headless 软件 WebGL，新独立 browser context；无游戏状态、随机种子、坐标变量或业务接口注入。鼠标出门、门口 E 观察、点击“带上落羽”、点击回院均正常 UI。

唯一受控故障位于真实 IndexedDB records 的 prepared intent put：parent 已有非空 keepsakes、探索授予 serial>0 且 session 非空；candidate 保持同 serial/keepsakes 而 session:null。仅精确匹配后抛一次 DOMException；其余 put 原样执行。新 page 明确禁用故障。完整驱动 [driver.py](driver.py)、UI指令 [events.json](events.json)。这属于受控存储边界故障，不能冒称自然故障或物理断电。

## 实际结果

1. [门口原图](01-gate-look.png) 提供落羽；[取物后磁盘](02-taken.json) 为 active、carried落羽、serial0、未授予。
2. [回院后磁盘](03-failed.json) 已为 generation6、落羽1、serial1、pending_commit session。**该文件的预定标签 `03-failed` 采样实际早于故障，不表示当时已失败。** 其截图未纳入，避免文件名代替证据判断。
3. 随后 cleanup 精确命中：`write_id=6`，`request_id=2b2f6faac6584d35b2c50eccb217ebeb`，parent gen6、candidate gen7。parent token `9e65128520d143c485731f04171de8f2`，candidate token `cceeb9277736446d8514bd15021f30e4`。candidate 仅清探索 session；真实授予已落盘。
4. 实际点击一次“再确认一次”，resolve 回 `rejected` / `terminated` / `readback_verified:true` / `old_write_terminated:true`，observed token 为上述 parent。等待15秒后，[失败面板仍在](04-retry.png)，[current仍gen6/pending_commit](04-retry.json)，未重新 prepare cleanup；完整调用/回执和 intent值见 [04-retry-audit.json](04-retry-audit.json)。这不是物品授予写失败。
5. 真 `pg.close()` 后同 context 打开新 page，禁用故障。[恢复原图](05-reopen.png) 不再显示失败面板；[磁盘](05-reopen.json) gen7、session:null、serial仍1、落羽仍恰好1枚，未重复授予。[新页audit](05-reopen-audit.json) faults为空，记录实际清理及ack链。

[summary.json](summary.json) 为当前envelope只读摘要；[errors.json](errors.json) 为空。audit记录prepare/submit/resolve/ack及records put，阶段JSON为readonly get(current)，**不声称是全部object-store完整dump**。仅测一次按钮重试，不推断连续多次按钮效果；未做手机、听验、物理断电或浏览器进程重启。结论仅为：同页cleanup拒绝未收口、面板残留；关页重开可恢复，未观察丢失/重复物品。

## 归档与排除

原始有效样本 `/workspace/exploration-idle-cleanup-public/final/`，仅选三张必要原图、原始驱动及JSON，字节/SHA-256清单见 [archive-provenance.json](archive-provenance.json)。未复制浏览器缓存；未入库文件仍在原目录。

更早根目录首轮也实际带回落羽，但旧驱动在新页重新武装故障，其首次重开结果**不计无故障恢复证据**；`once/` 修正该问题，却自然遇到空篮，只能作为空篮对照。这两组探针未作为本归档通过项，也不冒充最终携物结果；最终仅本目录对应 `final/` 的全程一次故障样本用于上述结论。

## 只读设计概要（待 Owner 接收与接口审核）

host_budget_impl 提供方案，优先由 Cloud 登记 cleanup operation 生命周期，不在 Store 另建平行状态机：

- `_persist_idle` / `_on_confirmed` / `_on_rejected` 及 `retry_deferred` 跟踪 cleanup_id；Store拟增加 `request_exploration_cleanup(expected_record, expected_watermark, target_idle, cleanup_id)`，仅内存身份，不增加磁盘schema。
- 队首比较可信完整 exploration 与 watermark，匹配才替换 exploration，并保留院子/照片等字段；失配在写前拒绝，不能用 no-op 冒 confirmed。
- 仅明确 `RESOLVED_PARENT` 且仍同会话时允许一次替代op；unknown只resolve。开始新趟须取消旧cleanup重交，不能覆盖新行程。
- Main按 cleanup_id 和精确故障revision解除面板，等待ack及idle；较晚故障、照片失败不得被误清。

以上为**候选设计，非已实现、非已批准接口冻结**。关联 [#150 原单](https://github.com/narutojzm1-dot/youjia/issues/150#issuecomment-5994871573)、[#305 原单](https://github.com/narutojzm1-dot/youjia/issues/305#issuecomment-5994871966)，仍待 Cloud 实际接收或显式交接；没有回执，不宣称已开工。本归档不修改运行代码，不发布修复。
