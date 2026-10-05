# #150 cleanup 共享接口候选

Agent-ID: CODEX-LEAD（内部实施host_budget_impl）。最终运行时代码2b79d6538dab1e35a8dff6161b0104bce434196f；基于main47baa1e，Cloud Host/Main未改，未启用正式调用，不声称同页idle cleanup已修。

Godot4.7.2专项95项通过，包含冻结参数、受理不等于确认、队首原记录/水位CAS、旧cleanup不覆盖前排新trip、保留院子/照片/带回物、未来原记录/未知扩展/fixture/错误序号拒绝、不prepare且不假confirmed、普通非法builder兼容、unknown→resolve/ack失败恢复、实际Native文件清理及旧重放原字节不变。契约见[架构说明](../../architecture/exploration-cleanup-commit-contract.md)。最终运行时代码完整Godot4.7.2 daily实际exit0，见final-daily.log；其中cleanup95、coordinator86、native200、save_feedback50、pause_notice168通过，日志无ERROR。

前期测试失败如实保留：第一次TestStore未进SceneTree导致flush无法等待，终止exit130；修为测试子类覆盖_ready并放入树后，Native测试又因传入重建int记录而非JSON读回原记录被CAS拒绝（exit1），这是正确的保守拒绝。改测试用get_exploration_record原值后通过；没有放宽原记录比较，也没有改Cloud生产流程。目标idle仅已校验的整数序号按值比较，避免target的JSON整数/浮点表示差异误拒。

独立预审发现856dc8f仅拒绝顶层/session扩展，现行纯结构验证器允许clock/proposal/item/failure内扩展，restore会丢弃这些未知字段。bfeb22f在restore之前补结构子项白名单；4类用实际Native主文件写入future_payload，断言原验证器允许、受理后明确rejected、backend调用不增长、原文件完整字节不变。新trip排队反例也改为真实ExplorationSession.begin生成合法trip2，避免手工拼字段。新增专项首跑path推断类型parse失败(exit1)，显式String修正后73项exit0。

856dc8f旧版完整daily已实际exit0，但不作为上述修复后的门禁；保留old-runtime-daily.log以区分。本切片没有新Web生产调用，因此不冒称真实Web同页cleanup恢复或已发布。

随后自查发现nullable proposal/failure缺键虽通过旧validator，restore会直接索引而报SCRIPT ERROR。中间83c5ac4专项进程exit0但日志含ERROR，因此不算通过；最终2b79d65在restore之前保守拒绝缺键，追加7类结构child恶意类型、nullable各自省略及active省略、legacy taken省略兼容，95项通过且日志零ERROR。bfeb完整daily主动中断实际exit1，见bfeb-interrupted-daily.log，不作为全套通过；最终runtime重跑全套已exit0。

正式生产preset无observer Web导出exit0（web-export.log），运行时代码2b79d6538dab1e35a8dff6161b0104bce434196f，Godot4.7.2.stable.official.ed1daf0bf。PCK SHA256 `3c4a9c2aeb17c80aa56f744ccaed517f7045bc6674255b66b027e1a5bf557e19`，模块逐文件哈希见web-build.json。生产preset排除test/docs，未加入测试控制面。独立pet30_impl已完成[普通Web启动/保存/真实关页重开烟测](web-smoke/README.md)，原始6图/完整只读DB/driver归档：实际PCK匹配，errors=[]；普通点击产生自然羊照片，正常回标题后gen3无intent，续玩及重开完整gen3封套一致。原launcher退出码未保留，不宣称进程exit0；未另验重开相册渲染。无Cloud调用，因此本切片没有cleanup领域Web E2E。

## 最新main组合复核

本地9043387037e1eea6ca3965a2e55c29f92d5c4ec6合入main efda464；仅requirements/decisions附录与daily列表冲突，双方内容保留，cleanup附录置于EXP-LIVING-WORLD之前，daily同时保留cleanup与confirm_panel_fit且模式100755。main运行时新增只有Main确认纸片尺寸/布局，本切片SaveStore/Coordinator相对8a83aeb完全不变。

组合Godot4.7.2 editor import及cleanup95、coordinator86、pause168、confirm562、save_feedback50各专项全部实际exit0且错误扫描通过（cleanup-merge-*.log）。完整daily与无observer Web/PCK/独立烟测仍明确属于此前2b79运行树，不冒称对合入后Main已重新导出/全套；本次按受影响范围补组合测试，未重复导出。相对最新main git diff --check通过；main原有三个历史证据EOF空行未改动。
