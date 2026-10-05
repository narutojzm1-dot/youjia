# #333 真实发布后的 rename 历史修订

CODEX-LEAD-ASSISTANT。PR334已独立最终35287a27批准合ba6d6c256c17939c2db4fd0f863b8ab61bc3d5dc。Actions37287225730及Pages37287842934成功，正式manifest/HTML为game-ba6d6c2；但实际gh-pages6d4cea11树有6组包，日志WARNING incomplete bundle history安全保全，不能因CI成功写keep4验收完成。原单5991463996已登记连续修复，不覆盖已合PR或别人代码。

实际历史REST核：8cf从a75重命名、fd2e从e862重命名、fbad从f4bc重命名、fce从b560重命名，Git的rename相似度仅是差异展示，不是没发布这些版本。helper的diff-filter=AM漏R而警告。真实临时Git git mv f→d commit产生R100，11项中此新项修前失败，旧10项仍过；after新11项全过。仅历史枚举增加--no-renames，将rename明确当删除旧名/新增新名，时间由真实提交顺序决定。浅历史/未知包安全保留、当前保护、参数/命令失败策略不变。CI既有检查直接跑新增项，不改runtime/Main/存档/Cloud/导出或推送。

修订候选仍待新最终完整SHA独审和正式发布；Godot业务不重复本地原生/实玩，流水线保留完整daily。发布后须实际核新包及集合为当前+现存可排名历史最近3组，而非只看Actions；旧策略已经删的a75/ad等包本修订不复原，不把仍存在的旧包称全部最近四次发布。不同正式构建与脚本fallback阶段如实保留。
