# PR CI docs 排除证据

此目录仅记录内部工程验证，没有玩家体验截图或公开发布声明。

- `historical-checkout-audit.json`：2026-10-05 21:52:44 UTC 的只读 Actions/仓库体积快照。454当时仍在验证；其后已成功并合入。本文件保留实际观察时态，不作为新候选CI结果。
- `dependency-feasibility.json`：67c87全源码与454运行增量的静态依赖核查；正式验证基线另见 `source-shape.json`。
- `sparse_fetch_fixture.py` / `sparse-fetch-fixture.json`：独立 file:// bare repo 的三组传输/工作树对照，不连接真实仓库，不运行Godot。
- `shallow_retention_fixture.py` / `shallow-retention-fixture.json`：7例证伪发布workflow朴素depth=1方案；读取仓库现有helper，不修改发布脚本。
- `source-shape.json`、`validation.json`、`process-results.jsonl`、`suite-completions.json`：实跑源码、每阶段/每Godot与Node进程退出码、72套准确完成汇总及导出哈希。
- `daily.log`、`retention.log`、`publisher_fixture.log`、`web_export.log`、`export-engine.log`：本机真实原始输出。退出结果以上述直接记录为准，不用日志尾行代替进程退出。
- `auto-generated-cleanup.json`：只还原/移除本次import自动产生的metadata/UID变动；未碰他人分支。

复现三组Git机制：`python3 docs/engineering/pr-ci-source-sparse-evidence/sparse_fetch_fixture.py`。
复现历史保留反例：`python3 docs/engineering/pr-ci-source-sparse-evidence/shallow_retention_fixture.py`。

这些脚本仅使用短生命周期临时仓库；输出会更新同目录对应JSON。本次内部配置不改变游戏行为，未重复浏览器体验；正式Actions最终head及独立审查在PR/原单记录。

补充记录：`source-size.json` 是准确base blob体积；`source-preparation.json` 区分本地借用部分对象准备失败与真实回归；`cache-cleanup.json` 记录引擎窗口释放后只清理自身ignored导入缓存。`export-comparison.json` 比较九个导出文件；`pck-member-comparison.json` 是全部398成员实际MD5/内容SHA检查，UID映射相同但顺序不同、三场景各4字节差异未擅自解释。可用 `python3 compare_pck_members.py BASELINE.pck CANDIDATE.pck` 复验，原二进制不重复入仓。
