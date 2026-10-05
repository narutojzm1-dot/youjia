# #130 发布取源：完整历史 + partial clone + 根 docs 排除（只读审计）

结论：**隔离机制与精确发布脚本的结果支持这个最小候选进入独立实施/正式门禁；没有发现必须改变历史保留语义的反例。** 保留 `fetch-depth: 0`，增加非 cone `/*`、`!/docs/` 可让完整 main/分支/tag/Pages 历史保持可用，同时不取回仅根 docs 引用的证据 blob。它没有旧 depth1 方案的 shared-shallow 回归。本报告仅为只读诊断，未修改生产、开PR、启动引擎或浏览器，12次发布全部针对临时 file:// fixture，并非GitHub发布或性能保证。

锁定源码 `9623ba22c8edc564e5c89dc6b0171324e9230764`；重新读取 checkout v4 实码 SHA `11d5960a326750d5838078e36cf38b85af677262`。全套文件blob/hash记录在 `/tmp/publisher130-partial-audit/source-index.json`。阶段快照显示37384961406 checkout后来成功，UTC22:50:19→22:56:09，共350秒，之后进入daily；这不构成失败，不据此推断慢的根因。

## 源码契约与新依赖核查

- `publish-pages.yml:22–25` 当前 depth0；permissions仍contents:write，串行发布和原ref不变。checkout `git-source-provider.ts:166–185` 在sparse存在时自动filter=blob:none，depth0仍使用全部heads/tags refspec；`ref-helper.ts:69–76` 与 `git-command-manager.ts:294–301` 保留完整历史/必要unshallow，不引入depth1。最小生产增量只需四行sparse输入，**不用单设filter，也不减少refspec**。
- 非cone实现 `git-command-manager.ts:206–220` 设置core.sparseCheckout并写入两个根模式；不增加worktreeConfig。fixture已实际证实新linked Pages工作树继承该模式，但只隐藏根docs，根game-*、index.*、manifest、全部save-*目录正常物化。
- 原publisher `:184` 后续原样fetch gh-pages。初始partial fetch记录origin.promisor=true、origin.partialclonefilter=blob:none；fixture在初取源后另推进Pages，证明这次不显式写filter的fetch仍保留filter，新Pages docs blob保持missing。`:189` 原worktree add使用准确新Pages tip；`:217–220` 原git add-A/commit/push保留未物化的旧Pages docs树条目，不当成删除。
- helper `:14–19` 先验证当前包和参数；`:22–27` 只对真实shallow保守不裁剪；`:28–40` 用完整first-parent、名字和无rename diff确定顺序，未知包仍保全部。读取路径/提交树不需要下载历史PCK的内容；当前worktree中的旧包仍必须按需物化，不能承诺消除全部Pages资源取源。
- fresh main树共915个非docs blob（前一基线913 + disabled suite及UID2个）。重新读取并校验734个文本blob SHA，181个二进制路径全部保留，无symlink；943处原始res:// token中没有res://docs/。非说明文档中的docs命中逐一核为workflow模式、export排除、注释或外部URL，不是运行输入。
- 对a0bb以来6项非docs变化重新检查：PR取源workflow、Main禁用态样式、新disabled专项及UID、daily入口、完成映射。新增专项只载入scenes/main，未加docs输入；当前daily是**73套+1 import**，不是旧72套。之前动态路径核查仍适用，源码SHA相同的动态加载未改变；宽匹配744行保留候选索引，不宣称744条都是动态依赖或全部动态状态已证明。
- 全部art/assets、near_path_anchors、根metadata、test/tools/web/site均保留；四个曾漏根metadata与嵌套test/docs也在Git正例中核字节。export_presets仍明确exclude docs。未来加入docs fixture/生成输入必须重审，不能删断言或静默跳过缺文件。

## 真实隔离 Git 与发布脚本结果

脚本 `/tmp/publisher130-partial-audit/fixture.py` 构造临时bare origin、main三提交、旁支/tag、Pages三次旧包发布及取源后的第四次Pages提交。复制上列精确原publisher/helper和10个真实storage模块；实际四个构建入口用小型合成dist。所有版本查询仅执行明确stub，**真实Godot进程=0**。除临时file://源没有其它远端写入。

| 配置 | main/Pages shallow | 根docs blob | 已知旧包裁剪 | 精确publisher两构建 |
| --- | --- | --- | --- | --- |
| 完整baseline，无filter/sparse | false / false | 已取回 | 保当前+最近1，删a/ff | 通过 |
| **depth0 + blob:none + 根docs sparse** | **false / false** | **main全部三版本/旁支唯一docs在两次发布后仍missing** | **同baseline，无警告** | **通过** |
| depth0 + sparse，无filter | false / false | 文件隐藏但blob已取回 | 同baseline | 通过 |
| depth0 + filter，无sparse | false / false | HEAD docs必按需物化 | 同baseline | 通过 |
| depth1 + filter/sparse | true / true | 旧不可达blob不在missing枚举 | shallow保守留全部 | 通过但包数增长，证伪此替代 |
| depth0候选，服务器不支持filter | false / false | server忽略filter，blob取回 | 同baseline | 通过但无传输优化保证 |

每种配置实际执行5个保留检查：正常顺序、未知历史包保持全部、不存在当前包拒绝、keep0禁用、负keep拒绝，共30项；六种精确原publisher分别执行两次成功构建，共12次，验证sourceCommit/entry、HTML+JS/WASM/PCK、别名、manifest、10模块字节/SHA/相对import、旧版本module目录、应保/应删包数，均通过。之后每种配置另建新源commit但移除dist PCK，**6次真实publisher返回1且本地origin gh-pages head不变**，证明缺当前包时未推送。

完整候选main历史3提交、Pages first-parent4提交可用、shallow=false；全量refs/tag同源。Pages docs即使隐藏，在两次真实git add-A/commit/push后blob仍与seed原件相同。全部非docs fixture路径含隐藏.github、root metadata、art/assets、嵌套test/docs逐blob一致。

初次fixture跑到depth1负例时错误要求不可达的历史docs blob仍出现在rev-list --all --missing输出，因此工具断言失败；这属于fixture可达性模型错误，不是生产脚本失败。已记录初次四个成功模式、失败原因并将“完整历史所有blob仍missing”断言限制到full-history模式，随后六模式全量重跑，再增加6次缺PCK真实拒绝后完整通过。原始说明、过程日志和直接返回码均保留，不隐去初失败。

## 最小生产候选与完整门禁计划

仅在原checkout的with中保留depth0，增加：

```yaml
fetch-depth: 0
sparse-checkout: |
  /*
  !/docs/
sparse-checkout-cone-mode: false
```

保持action版本/ref/凭据/权限、并发策略、原测试/导出/发布步骤、helper/worktree/push字节不变。候选不把路径过滤用于修改玩法，不删除证据。

1. 在#130独立认领/分支，重新核最新main与在途Owner；只改上述四行、需求/决策与可重现小型fixture证据。上述完成行/返回码绑定审计源，未当作新生产head已验证。
2. 在最终head运行独立Git fixture，确认full历史、不出现shallow警告、源码仍仅根docs缺席、原helper/发布函数不变。初次fixture模型错误与修正保持原件；正式源码当前915路径范围需精确对应。
3. 最终PR CI实际跑当前73套+import、50门禁、2Node、retention11、publisher fixture与Web export；独立最终SHA审查批准后才可合入。PR CI仍不执行生产publisher，不能替代步骤4。
4. **等待460公开普通操作后验closed后再集成，避免中途换公开源。** 实际main发布核对action精确SHA、fetch --filter=blob:none且无depth1、main完整历史和后续Pages fetch/worktree，无新的浅取/保留警告；检查原全量回归/导出/发布所有阶段和最终部署。
5. 实际读取公开HTML/manifest，下载完整PCK与10个版本模块核哈希/来源，核Pages树保留当前与最近包、未知历史仍保守不删。核对当前构建4入口/旧模块目录和根metadata/art未漏；若任何门禁失败保留前一可用版，不把点调度当完成。
6. 只报告实际阶段时长与取源机制。full refs树/历史仍有成本，当前保留PCK/素材仍需下载，filter不被服务器支持时可能退回全blob；不能把未压缩blob减少、单次350秒或fixture毫秒对照当提速归因。

## 证据目录

`/tmp/publisher130-partial-audit.json` 为总索引；同名目录含 source-index、fresh-source-scan（734个文本精确SHA）、fresh-dynamic-candidates、non-docs-change-audit、fixture脚本/结果/命令返回码、12次成功和6次拒绝日志、initial-fixture-correction、run37384961406阶段快照。没有下载日志签名URL、凭据或私人邮箱。报告状态为只读、未实施；生产增量和实际CI/发布必须另记。
