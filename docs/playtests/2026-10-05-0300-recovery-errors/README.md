# 隔离恢复夹具错误路径补证

CODEX-LEAD-ASSISTANT，2026-10-05北京时间03:00前后实际执行。夹具来源main73fe3d5cbf8637b88e05e214a5549a93741c96e0（含PR257 final47838bf962e87c6566dfa24e728d7e933224001d）；Gate f096a4a927c164c4bf70acc403a826a2074d2362；R1 Bridge/Probe 2edb2e72d64f8de97887e5840ccaf1967bef8598。

不重复此前12场景，不修改Cloud或Leader实现。复用现有隔离构建脚本，略去末尾完整矩阵，Godot4.7.2严格import/export通过，[构建日志](build.log)。Linux Chromium两个独立临时上下文、同origin每场景独立youjia-recovery-test命名空间。首个脚本使用错误测试库前缀未启动成功，修正为既有要求后下述完整测试通过；此驱动错误不计产品缺陷。

## 两条实际错误路径

1. 持续resolve失败：真实commit阶段abort注入后，在浏览器测试侧替换公开bridge.resolve，使其返回持续错误；这部分是人为回执故障，不是浏览器存储天然损坏。Godot夹具最多发出5次resolve调用，等待后仍5次，pending=true/ready=false且拒绝grant102。新页重载恢复旧watermark0，无授予，ready=true，verdict=restored_parent_intent_rejected。
2. acknowledge失败：测试拦截真实IDBObjectStore.delete('intent')并在该交易上调用abort，不伪造成功回执。水位101及grants[101]已提交；ack返回aborted后ready=false，pending=false，intent保留，新grant102拒绝。卸除注入（重载新页）恢复candidate、保持grants[101]仅一次、intent清除、ready=true。

[原始JSON](result.json)与[驱动](driver.cjs)保留状态、snapshot、事件及调用数；[断言结果](checks.json)15项通过。页面pageerror为空；本轮未采集runtime console，不能声称全部引擎运行日志无错误。cleanup调用成功返回，未额外验证删除后枚举；不要扩大清理保证。

这只是已合入隔离夹具+未合入R1候选的错误路径补证，不是正式Host冻结、R4进程重启/配额/迁移/shell验证，不读写用户生产存档，不说明公网已部署。正式#150/149仍归Leader，测试夹具归Cloud；#234发布布局原Owner仍待修，#159已有证据不重复。
