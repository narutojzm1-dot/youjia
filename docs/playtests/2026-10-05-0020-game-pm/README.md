# GAME-PM 00:20轮：移动/手账渲染与边界执行补证

实际在线记录2026-10-04T16:26:14.858Z（北京时间2026-10-05 00:26:14），轮次延迟启动，不伪称00:20准点完成。地址 https://narutojzm1-dot.github.io/youjia/ ，Linux Chromium headless、软件WebGL、1280×720，全新隔离context，无导入存档、不重置用户存档。本环境不能真人实玩/实际听验/真机，相关验收受阻；以下仅真实页面操作渲染补证，不作心流通过。

## 版本与步骤

页面build `game-fd2e9fe`；[公开manifest副本](game-release.json)来自 https://narutojzm1-dot.github.io/youjia/game-release.json ，source `fd2e9fe38e8c6ecb49d6a51cf14804bf4a89282d`，engine4.7.2，publishedAt15:11:30Z。本轮源码main `0828c8fff4b34221fce222e08a6dcc8273acf254`；当前main已包含245滑杆，但实际公网仍旧版、不含滑杆。PM未复核PCK哈希/发布Actions，不引用旧哈希当本次下载。

步骤：在线加载12秒，点击进入小院；按右方向键1.2秒、松开后等1秒，查看[移动操作后](move.png)；点击(110,675)打开手账，查看[空手账](album.png)。PM已看两图：场景/旅人/动物可见，手账为空态双页、“还没留下一张照片”，前后页不可用、合上可见。没有拍照或保存/重载，不当照片主体题词与持久化通过；没有测自然动物演出、天气连续性、触屏、暂停退出或声音舒适度。

[浏览器结果](browser-result.json)无pageerror/console error，backend诊断running/playing2；此轮未操作声音、诊断不证明出声。未产生可关闭原BUG的新复现，不建重复问题。

## #159精确候选执行补证

对 `a2dea17001c1cb98ed5f14cd15f2ca8c2b5954ee` 创建独立detached worktree，未修改原分支/代码。实际可用Godot为 **4.6.3**，与部署/前次验证4.7.2不同；未为此降低目标版门禁。

执行 `godot --headless --path <独立worktree> --editor --import --quit`，见[import原日志](boundary-import.log)；然后使用仓库 `tools/lib/verified_godot.sh` 的 `run_verified_godot`，同精确候选 `--headless --script test/still_boundary_feedback_suite.gd`，严格wrapper exit0，`STILL BOUNDARY FEEDBACK PASS 44`，见[原执行日志](boundary-strict.log)。退出时ObjectDB instances leaked警告保留。此前TuningStore编译失败在此引擎与候选下未复现；结果不等于目标4.7.2、完整daily、Web像素、最终独立审或发布验收通过。证据回原159评论5982084854，不代作者宣称可合入。

后续同a2独立GAME-PM-REVIEW-PR-159代码APPROVE已回PR，旧风险/三项修订已核实，目标4.7.2严格验证与必要Web仍缺，不表示合入/发布门禁全通过。
