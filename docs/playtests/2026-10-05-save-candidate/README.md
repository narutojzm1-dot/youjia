# #149 候选提交的内存边界

Agent-ID: CODEX-LEAD。基于 main f517f912652420202461f8e137da8123d8fe1aa9；仅现有 SaveStore setters 和共同 `_commit_candidate`，不改探索分支、存档字段或调用方签名。

原实现中，文件写入失败前已修改 `_data`；之后一次无关 save() 会把失败候选带进磁盘和备份。现改为深拷贝候选，SaveFiles.commit 成功后才发布到 getter 内存。yard snapshot 原有正确边界复用同一 helper。PR322 引入同名 helper 的探索方法需整合时保留一个相同语义的实现，不覆盖其字段或方法。

## 验证

- 生产 SaveStore + 实际 FileAccess 故障回归：8种setter、72项。非空目录占据临时文件路径，触发真实文件打开失败；核内存/原文件不变、稍后 unrelated save 不会混入失败字段、成功重试、备份和重载。基线72项21失败（7种setter各3项）；修复72项0失败。已有yard setter正确，作为防回归范围。隔离临时目录；测试构造故障与种子不是玩家端到端体验。
- 全部 strict daily 退出0，最终完整日志 `daily.log` SHA256 `29e932c4886db4af6b26681e520e3c06b94fb40dffa305039704030ba04990a7`。早期一次运行因操作者在导入后过早恢复 `.import` 造成缓存引用不匹配而终止，接续日志又被旧进程污染；不采用其结论，全部进程结束后使用独立日志完整重跑通过。
- Godot4.7.2生产Web导出通过；PCK `f2c1163e84554b25acc26df033815e298b671ea1180974e9430183771475c9ea`。
- Chromium真实生产包1280×720 DPR1，新浏览器环境正常开始、抚摸羊、自然生成照片、打开手账，随后真正关闭页面/重新打开，同一手账照片恢复，console/pageerror为0。已经实际查看两张截图。只读检查旧IDBFS，未注入/改写游戏状态；驱动和结果随附。

## 边界

这完成现有同步文件提交的内存一致性，不是 Web 新 Host 持久化确认。现有void setter仍未给UI逐次错误结果；native回归不能证明浏览器崩溃/丢回执安全。#149/#150异步生产协调器、旧源保全、新旧页隔离和完整恢复接线仍在继续，本PR不关闭父issue。上线及最终SHA独审以PR记录为准。

合并 main 5f74afb1eaf521f0f2df9401138b248b560b04a4 时仅两份台账追加和daily suite行冲突，保留双方记录、web_hidpi与save_candidate两个门禁。保存运行时代码未变；集成后针对72项保存回归与102项HiDPI均通过，见integrated.log；各自完整daily已通过，不为文档合并重复全部游戏物理检查。
