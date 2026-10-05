# #150 探索跨 op 重交后的共享保存提示

**最终候选实际通过：** runtime `af0a13ea074dd64e2f10f706a8d4630d60fbc9d3`，Godot4.7.2完整daily exit0（保存提示50项、探索143项及全部尾部），`final-daily.log`。独立真实Web普通探索＋一次IDB intent写入故障：old write10 rejected→已排队trip11 confirmed→正常idle12；一次确认后同页提示清除。实际关页重开保持圆石2/松果1、水位1，无重复，浏览器errors为空。原图/完整DB/回执/driver见 `final-web/`，PCK及运行时文件摘要见 `final-build.json`。实施者已亲看最终清提示与重开原图。尚待独立最终SHA审查和公开发布验收。

以下按阶段保留初版通过范围与实际Web退回，不能把初版门禁当最终结果。

Agent-ID: CODEX-LEAD（内部实施 host_budget_impl）。原单认领5994503627，来源Cloud PR368；不接管Cloud探索流程，不改授予逻辑或Host协议。

运行时代码86d1af6b2f6d61623586ab535990b99b93ba2938，base a067ce9。SaveStore在探索intent被接受后发只读身份：trip_id、serial、record_revision；trip另有冻结find_ids。不是新的持久存档字段。Main记录当时可覆盖的旧故障与revision，只有同趟、不旧于失败revision且实际写入覆盖该领域的新op confirmed才消旧故障；record永远不能消trip授予失败，trip物品列表必须相同。更晚失败不在旧coverage中；其他领域、未入队照片继续阻止面板消失。最后仍需ack完成且真实idle。accepted身份与coverage在confirmed/rejected后清理，待决op期间保留。

39项专项通过：原21项、实际SaveStore接受/Native确认链（初始故障为受控回调）、真实Coordinator受控backend的unknown→resolve rejected→新op unknown→confirmed→ack idle顺序；后者是契约验证，不冒充物理磁盘故障。不同趟、不同物品、旧revision、record/trip隔离、晚到失败与未提交照片负例通过。首次新增测试因GDScript局部类型推断缺注解而未加载，补Dictionary类型后运行通过，无生产运行失败被隐去。

生产Web导出通过，PCK SHA256 `6d8b1faa0f6b2dc7b61252573c99a96e2ea0cac1c01330f721f2fa3df0c5309e`。完整 Godot 4.7.2 daily 实际 exit 0，运行时代码86d1af6，含原39项提示专项；该专项完成后仅新增ack失败两断言，增量41项实际exit 0，日志分别为daily.log/ack-focused.log，不将完整daily的39项误写成41。真实浏览器存储故障验证仍进行中，尚不称已合入/已发布/完整验收。

身份覆盖约定：record_revision 来自 Cloud 合法单趟会话的单调修订；不是任意外部文档版本推断。trip 写入同时包含会话record，所以同趟、不旧的trip可覆盖record失败；普通record没有授予事务，绝不反向覆盖trip失败。

Native测试先前trip-1真实已确认，随后trip-2推进水位；再提交trip-1按现有水位线不再授予。该组用于覆盖身份/提示，不证明真实首次reject后补授予。受控backend组验证回执顺序；首次拒绝后实际补授予且仅一次仍以独立Web IDB故障体验为准。

明确未覆盖：Cloud `_finish`/`restore` 的 `_persist_idle()` 写 `session:null` 后没有登记 `_ops`，对应 reject 被 `_on_rejected` 的无匹配 op 分支忽略，当前没有同一 idle intent 自动重交流程。本切片不把任意 null 记录视为同趟覆盖，也不会虚假清除此故障；若要玩家当前页重试该 cleanup，需要 Cloud 明确登记其重试或共享层保留准确原始 intent 的额外接口，另行划定范围。不是“全部探索故障提示闭环”。


## 真实 Web 拦截与修订

86d1af6 虽然 Native 通过，真实 Web **失败**：先接受return record与trip，之后record写入失败，trip在旧失败发生前已经排队，原accept时coverage为空。old write10 resolve rejected、新write11 confirmed、idle12 confirmed后面板仍在。见 `initial-86d-web-failure/`，不是已修复证据。

修订runtime `af0a13ea074dd64e2f10f706a8d4630d60fbc9d3` 在内存接受身份加单调序号；terminal rejected回调将本次精确故障revision绑定给已接受但顺序更后的同趟覆盖op。unknown不追加coverage，早接受不能覆盖后接受，绑定后新的失败仍使revision失配。原晚于故障才接受的路径保持；Host、Cloud流程、授予不改。新增真实Coordinator先排两笔再失败链及反例，专项50项通过（queued-focused.log）。新生产export通过，PCK9f5e3505a848475919990d2bb635e42ce4fb52e8804c37f82895e20577d14aab；该修订的完整daily与独立Web重测最终通过，见本文开头与final-*；旧daily.log只证明86d，不冒充新运行时门禁。
