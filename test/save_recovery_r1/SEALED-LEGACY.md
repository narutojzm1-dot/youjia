# #150 永久旧源保全（CODEX-LEAD）

基线PR251 `39516cb02d491837a6943b01a3a81b157a9dac5d`。本切片修复R1初次导入raw仅存在于根current，第一次正常submit+ack后随parent intent删除而丢失的问题。仍为研发测试namespace，不是生产SaveStore切换或发布。

## 格式与约束

- 普通旧fixture仍使用严格9字段 `youjia.save-envelope/v1`，验证/创建方式保持。它不具备永久旧源保证，不自动重写老fixture数据库。
- 经 `importLegacyV5` / bridge.initializeLegacy 导入的根使用严格10字段 `youjia.save-envelope/v2`：新增 `legacy_sources_sha256`，位于canonical长度前缀摘要中payload_sha256之后、envelope_sha256之前。所有正常后代通过envelope自动继承schema/来源摘要；submit、intent、archive必须保持同一来源及store_id，不能从v2链变成无来源v1链。
- 新record key `legacy_sources` 固定五字段：schema=`youjia.legacy-sources/v1`、store_id、import_payload、payload_sha256、seal_sha256。import_payload保留完整primary/backup原始字符串与selected，不解析后重写源内容。
- payload_sha256=SHA256(UTF8(import_payload))；seal_sha256=SHA256(UTF8(JSON.stringify([schema,store_id,import_payload,payload_sha256])))。固定顺序数组只含字符串，记录类型/keys/摘要/长度/旧源结构均验证；这是意外损坏检测，不是签名或恶意重签防护。
- 根与seal在同一个readwrite事务里写入，并在complete后整体读回。已有任意record拒绝初始化覆盖；abort不会留下孤立root或seal。
- recover先验证v2必须有有效seal、同store_id和来源摘要；v2缺slot一律quarantine；v1出现seal也quarantine。损坏不删除、不重置，不让fixture兼容路径掩盖缺失v2来源。
- submit/ack/recover清理意图均不改seal。总记录JSON字节预算包含seal；source/import/write各自预算保持。永久保全增加空间，预算耗尽拒绝新写而不驱逐旧来源/故障档案。

## 回归与证据

`sealed_suite.html` 使用真实IndexedDB：未知字段及超JS安全整数原文跨3次正常submit+ack并真实location.reload仍完全保全；真实初始化transaction.abort后root/slot均不存在；occupied初始化不覆盖；正常写+ack后删除slot、损坏seal、损坏绑定、两者同时损坏、换另一库合法seal均隔离且写前后证据不变；dense相册配合真实prepared失败归档直到累计预算拒绝，完整来源继续存在。

`budget_suite.html`中的直接导入根明确启用preserveLegacy，不能用普通无来源fixture根代表新迁移链。旧R1/legacy/migration检查仍运行；实际Godot Web启动/旧源读取→真实导入→回执→ack→重载链也复跑。结果汇总见 `sealed-evidence.json`。

```sh
python test/save_recovery_r1/run.py --suite sealed_suite.html --out /tmp/sealed-result.json
```

`initialize(payload,{preserveLegacy:true})`只用于已完成旧源验证的导入。普通`initialize(payload)`保留fixture用途，不构成迁移入口；生产adapter应只开放已经验证的迁移/新档初始化。`abort_initialize`是本隔离候选与已有abort_stage同类的真实事务故障注入，后续生产提取时必须去掉，不能发布Probe/fault入口。

## 生产边界

本次不改SaveStore/Main/Cloud或IDBFS挂载。旧不合作页面隔离、只读旧库事务捕获、异步业务消费和正式shell/发布仍由生产接入切片完成。生产提取与业务接线由Leader按独立范围继续交付。新格式需要独立最终SHA审查；旧测试格式兼容不表示可以忽略生产迁移版本判断。
