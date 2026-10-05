# 新绵羊照片主体构图修复

CODEX-LEAD-ASSISTANT；2026-10-05北京时间15点执行；原QA-EXP-20261003-002/#40的独立新照片子项。用户指定Assistant缺陷优先，与Leader分担；Leader相机/存档/主场景范围不动。

明确缺陷：sheep_pet_gentle的规则owner是物种sheep，快照subject是sheep_a/sheep_b。默认取景按精确ID查找，找不到羊就落到院子中心(630,470)；因此题词可以写绵羊而取景漏羊。现在对没有同名角色的物种Owner，以其真实角色ID计算主体包围框。既有特例取景和同名牛/马/羊驼保持；缺失Owner仍走原兜底。不改成功条件、相机或存档，不自动替换旧照片；本复现证明新拍摄路径，不声称原旧档首次生成原因完全确定。

原生：Godot4.7.2隔离XDG下，同一生产Main/YardWorld角色快照专项修前9检查3失败、修后9检查0失败；两羊sprite的真实变换包围框入镜、原快照不变、牛和缺失主体兼容。日志before.log/after.log。完整严格daily退出0，包括专项挂载、通用/摄影/物理/低动效/横竖屏/加载壳；native-daily.log为目标4.7.2完整记录。此前误用GODOT_BIN启动环境默认4.6.3的非目标轮已停止，不用其结果计目标验证。

Web：test/photo_species_web/main.gd以真实生产Main、PhotoMoment和原图生成受控快照，在真实4.7.2 Web导出/Chromium1280×720显示旧默认焦点与修后焦点；controlled-before-after.png左边旧兜底未见羊，右边新取景可见两羊。web.json：focus(279.09,400.81)、span233.10，页面/console错误0。这是受控真实类渲染，不是自然轻抚游玩、真机或公网版本。首次夹具在capture前hide生产Main导致空记录，已修为capture后hide；空记录不计通过。

生产export_presets.cfg与project.godot保持原文件；本地受控导出临时切入口及移除test排除后复原，仅用于证据。正式导出继续排除test/和docs/。历史照片不变；父#40其他范围保持开放。正式发布需独立最终SHA审查、合入后Actions/Pages和实际manifest/PCK证据；此文档当前未声称发布。
