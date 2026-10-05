# 发布取源候选的工程证据

本目录是内部配置验证，未执行游戏引擎/浏览器，不是正式发布或玩家体验记录。

- `readonly-audit.md`：实施前只读结论与门禁计划的原快照；其中临时路径用于说明当时工作环境，不当仓库文件链接。此快照“未实施”指当时审计阶段；当前候选范围/状态见上级 `publisher-source-sparse.md`。
- `source-index.json`：审计时读取的main9623与checkout action精确Git blob/SHA256。
- `fresh-source-scan.json` / `source-text-blobs.tsv`：main9623的915非docs路径边界，其中734个文本逐blob读取/校验；181二进制仍保留；全部非说明文本docs命中逐项核查。
- `fresh-dynamic-candidates.json`：宽匹配744行的核查索引，不表示744条均为动态加载或所有运行状态已验证。动态原路径与新增460代码的变更审核另见 `non-docs-change-audit.json`。
- `initial-fixture-correction.json`：审计首轮对depth1旧不可达blob作了错误枚举假设而断言失败，随后改为仅对完整历史断言所有docs blob均missing。原错误没有当成生产失败，也没有隐去。
- `fixture.py` / `fixture-results.json`：读取当前仓库的真实publisher/helper和10模块，在短生命周期file://仓库分别执行六种配置、30保留检查、12成功发布及6缺当前PCK拒绝。真实引擎=0，版本查询由明确stub返回；不是将stub冒充Godot。
- `fixture-command-results.json`：直接记录每个临时Git/Python/Bash过程的命令、退出和时间。配置不存在/期望拒绝等非零结果是明确测试分支；不是每一个命令都应exit0。
- 各 `*-publisher-0.log` / `*-publisher-1.log` 为实际成功发布脚本原始合并stdout/stderr；`*-publisher-missing-pck.log` 保留六个实际拒绝与对应错误，结果JSON核到origin未移动。
- `run-37384961406-stages.json`：既有460发布checkout最终success350秒的阶段快照；不是本候选发布/性能结果。

从仓库根独立复现：

```sh
python3 docs/engineering/publisher-source-sparse-evidence/fixture.py
```

默认写新临时报告目录，不覆盖归档；若要指定输出目录可在命令末尾传路径。运行只修改临时file://仓库和指定报告目录，结束删除fixture仓库。当前结果绑定运行源 `93d708d5fb20f8007b47b40bfc58f1845295aa4e`，最终docs收尾不改生产文件。新head的真实PR CI、独立终审与正式Pages结果在PR/原单后续绑定。
