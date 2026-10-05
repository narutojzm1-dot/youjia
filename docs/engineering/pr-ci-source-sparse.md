# PR 只读 CI 的根 docs 取源排除（#130）

Agent-ID: CODEX-LEAD。范围认领：[6003973038](https://github.com/narutojzm1-dot/youjia/issues/130#issuecomment-6003973038)。分支 `work/codex-lead/pr130-sparse-source`；基线是已完成最终独审及真实 PR CI 的454合入 main `a0bb75e38e59032a6df72a2122af4403c3c3e816`。本片只改 PR 验证的 checkout，不改游戏、测试、发布工作流或历史保留。当前状态：本机机制/全量验证已通过，最终独审、此 PR 的真实 GitHub CI 与合入仍待；不声明新发布或玩家体验改善已上线。

## 改动及依据

在原 `actions/checkout@v4` 的 `with` 中仅增加四行：

```yaml
sparse-checkout: |
  /*
  !/docs/
sparse-checkout-cone-mode: false
```

非 cone 的两个根锚定模式保留全部条目、仅排除根 `docs/`，包括 `.github`、全部 `art/`、`assets/`、根 metadata、`test/`、`tools/`、`web/`、`site/`；嵌套 `test/docs/` 也保留。原触发 `paths-ignore` 只决定是否启动，不提供下载排除。默认 proposed merge、depth1、只读权限、`persist-credentials: false`、取消旧同PR运行、超时和全部原验证保持。

核查的 checkout v4 SHA 为 `11d5960a326750d5838078e36cf38b85af677262`：`src/git-source-provider.ts:166–169` 在 sparse 输入存在而无显式 filter 时选择 `blob:none`，`:214–225` 在 checkout 前配置 sparse，`src/git-command-manager.ts:206–219` 写入非 cone 模式。因此不额外设置含有覆盖 sparse 语义说明的 `filter` input。真实新 CI 仍须核对其实际使用的 action SHA、`--filter=blob:none` / `--depth=1`、精确 proposed merge 与完成计数；本地共享对象不会证明真实 GitHub 传输量。

当前基线4743个跟踪文件共1,413,143,140B；其中根docs3830个/1,200,434,958B，保留913个/212,708,182B。这是 Git blob 未压缩工作树统计，不是网络压缩字节或加速保证。历史成功450 checkout29秒，某次main发布checkout693秒（宽ref fetch约691秒），454 checkout1246秒但后续真实CI成功。阶段耗时仅证明存在取源成本，不能据此断言454网络慢的原因或保证本片提速。[历史无凭据快照](pr-ci-source-sparse-evidence/historical-checkout-audit.json)保留当时观察时态。

## 源码依赖与 Git 正反例

实施前按 Git 对象读取730个非docs文本路径，复核585个 `res://` 字面引用和200个动态加载/文件入口候选；没有找到当前 CI/native/Web导出依赖根docs的反例。另复核454全部运行增量，新mat suite仅用assets/scripts。正式候选逐一证明913个非docs跟踪路径存在，除声明的workflow四行外与a0bb对应blob相同；验证开始和结束时整个根docs都不存在。

关键输入证据：

- `tools/verify_daily_life.sh` 调用明确测试、门禁mock与两个Node；`verify-pr.yml` 的两个Python检查、daily、Web导出均不读docs。两个Node分别读取 `web/loading.html`、`scripts/platform/motion_preference.gd`；publisher fixture复制tools与web/save，retention fixture读取发布helper并生成临时历史。
- `export_presets.cfg` 已明确排除 `docs/*`，壳文件为 `web/loading.html`；主场景、图标、autoload位于保留目录。全部585个字面资源引用没有 `res://docs/`。docs内9个存档GDScript没有全局 `class_name`，保留源码没有引用这些路径。
- `test/exploration_slice_suite.gd` 确实读取 `art/concepts/producer_world_20261005/near_path_anchors.candidate.json`；整个art保留并实际经过218项探索检查，避免过去白名单漏排该资源。四个根metadata也保留，PCK实际398成员无漏项。
- 动态角色路径固定assets，照片持久化纹理限定 `res://assets/holiday/`，I18n与TuningStore固定localization/config；存档测试临时路径为隔离user目录。根provenance里的历史docs字符串和文档注释不是当前构建输入。

结论仅覆盖现行调用链。未来引入docs fixture、生成数据或文档检查时必须重新审查此规则；不可删除断言或让缺文件静默通过。完整冻结核查计数见 [dependency-feasibility.json](pr-ci-source-sparse-evidence/dependency-feasibility.json)，其“未运行”字段准确指实施前只读审计，后续真实运行另列。

隔离file:// bare repo有真实双parent proposed merge，filter明确开启；实际三组fixture通过：sparse+blob:none保持所有非docs路径/字节且独有docs blob仍missing；仅sparse虽隐藏docs却已下载blob；仅blob:none在checkout时仍按需取回docs。fixture保留隐藏目录、全部art、根metadata与嵌套test/docs。[脚本与结果](pr-ci-source-sparse-evidence/README.md)不连接生产远端。

另7个历史保留fixture证伪朴素改main depth1：即使自行完整fetch三次gh-pages提交，共享仓库shallow标记仍为true，现有helper因此保守不删包；完整main/独立完整Pages两个正对照能正确选旧包，非法参数与缺当前包均拒绝。故 `publish-pages.yml` 的depth0及现有保留语义保持，不把PR配置推广为发布优化。

## 实际无 docs 回归与导出

运行源 `1596cd1f05df3744045f19d929eabb906bdddaba`，tree `107463b049c86df7069aed3d3127b6b7725900cd`；2026-10-05 22:07:10–22:14:43 UTC（北京时间10月6日06:07–06:14）。Godot `4.7.2.stable.official.ed1daf0bf`。后续提交仅加入本档与需求/决策，不改变已验证的非docs源码。

| 检查 | 实际结果 |
| --- | --- |
| 严格 daily | exit0，1次import+72套/73次Godot；逐套匹配当前精确完成映射，无ERROR/FAIL |
| 门禁受控过程反例 | 50例通过，非游戏引擎 |
| Node | 两个真实进程均exit0 |
| Python retention | 11例通过、exit0 |
| 真实本地publisher fixture | 两构建完成、exit0；两次Godot version子进程exit0 |
| Web release | 现有严格进程/日志helper验到实际Godot exit0，原始输出无异常，四必需文件非空、九导出文件有hash |
| 关键新增套件 | photo_arrival_mat 550；soft_button_focus_contrast 5080；不是沿用旧71套记录 |

[validation.json](pr-ci-source-sparse-evidence/validation.json)直接记录阶段命令/退出码/时间和九导出文件SHA256。[process-results.jsonl](pr-ci-source-sparse-evidence/process-results.jsonl)记录78个实际Godot/Node进程，均exit0（73 daily+2 Node+2 fixture version+1 export）；[suite-completions.json](pr-ci-source-sparse-evidence/suite-completions.json)列72套独立准确完成行。各完整原始日志在同目录。测试profile及engine导入状态隔离，无游戏状态注入；未用日志最后PASS代替进程返回。导出外层 Bash 未显式启用 errexit，本次通过由直接记录的实际engine退出、严格helper无异常、输出非空及完整日志独立扫描交叉确认，未声称对该临时harness另外执行故障注入；生产workflow未改。

初始本地shared clone/普通commit因借用的部分对象库缺旧docs blob失败，是源准备问题，未运行游戏。恢复使用独立.git、只读alternates和精确base tree，按913个非docsblob复核后创建候选；没有声称远端仓库损坏。细节见 [source-preparation.json](pr-ci-source-sparse-evidence/source-preparation.json)。运行后按清单还原5个自动import metadata、删除36个新UID，没stage它们；释放引擎窗口后仅清理自己已完成且ignored的`.godot` 43,748,853B，原始日志和导出全保留。

## 导出成员对照与验收边界

本地PCK 27,089,100B，SHA256 `89b6593e8e05951fc24f139dc01092b3281bc59cd5dcf8616caef5dc198d00e8`；454完整metadata基准包同大小，SHA256 `faa935055fb62250c137625da28e15d2ac28ef3880db1e8993e5991afec84df6`。九个导出文件仅PCK哈希不同，不能声称两包字节相同。

无需重启引擎的只读PCK解析检查全部成员MD5，两包同398个名字、无增删，394成员内容相同。UID cache的176条path→UID完全相同，仅记录顺序变化；另外三个导出场景每个只有4字节不同，偏移分别为resident_walk_authored_v1.scn的743、main.scn的690、native_walker.scn的527。这里未证明这些4字节的具体引擎字段，不能据此冒称三场景语义已另行验同。完整成员哈希、字节差异与可复现解析脚本见 [pck-member-comparison.json](pr-ci-source-sparse-evidence/pck-member-comparison.json)。源码无运行修改、全部套件与导出通过是本片功能不回退证据；不是用哈希差异推断新功能。

本片是内部CI输入范围，不影响玩法、美术、音频或存档格式；没有新浏览器体验，也不使用旧截图冒本候选体验。最终独审、真实GitHub proposed merge全验证及合入状态由PR/原单继续绑定最终head。#130父单仍保留未完成架构/工程子项，不因本片关整单。
