# 已提交探索记录 cleanup 无效参数保全

Agent-ID: CODEX-LEAD（内部实施 host_budget_impl），原#305认领6000660890。基线 `cdec7a6a5b8f13307048e60f6e1f57d49f5b5881` 保留Cloud427提交祖先；运行修订 `47bb594006b4236d88e145969c2f5d1ca4118405`。仅修改ExplorationHost._cleanup_rejected无效参数分支，不接管Cloud正常领域算法、不改共享存储wire/磁盘schema/Main输入。

## 触发与修正

领域HOST_CLOSE对结构仍可读取、含未来扩展的已提交formal记录发cleanup；共享391 API正确拒绝INVALID_ARGUMENT，旧Host却改用普通record写idle，从而覆盖current。现在INVALID与PRECONDITION_CHANGED都终止本次重交：没有fallback提交、不伪造成功，保留原失败与权威记录。正常支持记录的普通写失败仍按原最多2次重交，unknown仍等待原op结论。

这是本地受控兼容性记录的真实Native文件复现，不是已证实的公开用户档案事故。Native原始来源sidecar可能保留原文，缺陷针对current被覆盖，不能把有sidecar当作通过391契约。修订不承诺自动修复未知格式，失败提示保守保留；未来需能理解该格式的恢复方案，未新加重置/删除玩法。

## 回归

新专项 test/exploration_cleanup_preservation_suite.gd 通过实际Host.restore→SaveStore→Coordinator→Native文件链，覆盖started_clock/proposal/item/failure及顶层unknown。每个案例要求原始拒绝仍在、无confirmed、无prepare/submit/ack、权威文件完整字节和record不变、队列停止且带回物不重复；正常记录仍一次确认和三次真实backend调用。51项，基线cdec 15失败（每个unknown案例3项），修订后51/51、exit0。

初次新harness的base变量类型推断引发parse失败，setup-failure原日志单列，不算产品复现或通过；显式类型后才取得上述修前/修后结果。import实际exit0。脚本在隔离用户目录运行，未写玩家档。全部只在/dev/shm独立项目修改，8200/8201旧候选不动。

完整daily和Web导出待追加；未声称真实浏览器未知记录故障复验、公开发布、全格式兼容或原#150/#305整体关闭。独立终审由另一reviewer完成，实施者未自审。

测试边界补充：新51项没有实例化Main，因此“失败提示保留”是原拒绝信号与无重交覆盖映射的源码结论，不冒该专项实际UI体验；既有save_feedback及Cloud slice门禁另列。future formal扩展不得走普通record fallback；既有fixture隔离与unknown路径未改，不把本片描述为修复所有legacy格式。

原缺陷诊断见[PR430归档](../2026-10-06-cleanup427-contract-review/README.md)，接收修正见[#305评论6000660890](https://github.com/narutojzm1-dot/youjia/issues/305#issuecomment-6000660890)。根取消了未修cdec的发布run37356141984，实际completed/cancelled回执随档；**取消发布不等于回滚main**。本修正仍须完成独审与发布，不能以调度取消冒已上线修复。

## 完整运行门禁与候选导出

47bb精确运行代码完成Godot4.7.2 strict完整daily，70次启动实际exit0：Cloud slice216/core357、Coordinator86、cleanup95、新保全51、保存反馈50均过；title_card251与title_short_landscape1541也分别全部通过。每个suite按原脚本独立XDG_DATA/CONFIG/CACHE及YOUJIA_TEST_ISOLATED_DATA，不共享旧档；没有将其它环境的失败判断成已解决。

同树生产Web导出exit0，独立/dev/shm/cleanup-preserve-export/8202。PCK27088028字节 SHA256 `0833fcc888dcf15a74d1ca600fe9ce8c0fb44c01d9cd45723f8faad95e187543`。原export-files.json在stamp前采集；复用根generic helper只加本地game-47bb594与fullsource manifest，后stamp哈希/脚本/回执另列。没有修改PCK/JS/WASM引擎字节，不是公开发布。301普通与304精确cleanup故障Web验收进行中，两个profile互不共用。

候选随后顺序合main515f（432公开档案）及cd3a（433相册公开档案），两者均仅docs；运行路径scripts/autoload/tools/test/web/project.godot相对47bb完整diff为空，不重跑无变化full、不重新覆盖正在QA的8202。两份正式历史证据保留，不将取消cdec发布误写成回滚。

## 真实Web受控单次cleanup写故障（review304）

[完整受控原件](web-controlled-fault/README.md)绑定47bb/fullmanifest与双实际PCK0833fcc。普通自然落羽1在write5授予；仅真实prepared intent满足“已授予parent→清session且水位/物品不变”时抛一次DOMException，cleanup6 UNKNOWN→resolve rejected；实际一次再确认后唯一替代7confirmed/ack cleared，同頁失败面板消失。真page.close新page明确禁fault，current完整envelope与重试后完全相等，gen7/sessionnull/落羽1，第二页fault0；errors=[]/exit0。实施者也亲看06恢复原图。早03尚未触cleanup的取样保留不作成功或故障失败。没有改业务状态、种子、时间、位置或回执，只有明确IDB故障注入。此链证明有限重试接线，不证明INVALID未知字段保全（后者Native51分列）。

## 普通Web首次未完成（review301）

[失败原件](web-ordinary-incomplete/README.md)：自然羊照入册、进入近郊前两停点后，第三停点Keyboard.press出现Target crashed，driver exit1。未返院/真重开，不计通过；errors=[]不能覆盖driver崩溃，现无充分证据归因产品或资源。待另fresh最小单停点普通链独立补验，不用受控故障链冒普通QA完成。

## 普通Web唯一缩短链有限通过（review301）

[独立fresh短链原件](web-ordinary-short/README.md)：自然羊照→shade自然松果1→普通触门返院→真page.close新page相册同照，exit0/errors无报错，双页四manifest完整47bb与每页PCK0833fcc/27088028绑定。照片album/photo_moments在四次只读current中完全相同。返院后取样gen8已松果1/水位1但session pending_commit且有intent；重开gen9清session、松果仍1/水位仍1但仍有intent，**不称完整封套相同、intent清空或完全idle**。只证明该时点照片/物品保留且未重复授予，后台队列完全排空并非此普通链覆盖。实施者也亲看重开相册图。

首次长链Targetcrash exit1的README/log/hash已补齐并保留，不能因后续短链通过而抹掉。普通短链、受控IDB单故障与Native未知扩展保全是三份不同证据；Web原件全部逐字节核对见web-original-copy-verification.json。最终待独立完整SHA审查与正式发布，未自审、不关闭父需求。

原始Target crashed日志末行自带一个空格，为保持原字节未清洗；仅此归档run.log以目录内.gitattributes关闭行尾空格检查，其他文件仍按正常diff门禁。
