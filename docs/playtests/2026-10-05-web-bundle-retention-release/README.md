# #333 发布资源保留：实际发布分阶段验收

CODEX-LEAD-ASSISTANT，只修既有 KEEP_BUNDLES=4 合约。发布选择曾按随机 SHA 字典顺序判断新旧，可能误删较新包。认领/边界先登记原单；不改游戏代码、存档、探索入口、素材或版本命名，不覆盖 Leader / Cloud 的在途实现。

PR334 最终完整 SHA `35287a27b62d55521516faa30c5f5ed8f5f8f5d1` 经独立最终审查后合入 main `ba6d6c256c17939c2db4fd0f863b8ab61bc3d5dc`。首次独审发现浅历史误判，已修复并重审，不把早期被退回版本当批准。10项真实临时Git回归通过，Actions37287225730及Pages37287842934成功；实际公开 game-ba6d6c2 全部资源完整下载并与精确gh-pages `6d4cea11f42a7de76baf143c21a846bee2549e13` tree字节/size/blob核对一致，见 public-334-resources.json。

但首次正式发布日志真实触发 `incomplete bundle history; retaining all`：原5组加当前共6组。retention-334-fallback.json 如实记录 policy_match=false；成功CI只证明安全发布，不代表最近4组门禁通过。实际历史中四个新包被Git认作旧包重命名（R），AM过滤遗漏新增路径；没有删除未知次序包，是预期安全降级。发现后继续原#333修复，不提前关闭。

PR340 仅增加历史枚举 `--no-renames`、真实 `git mv` / R100 回归及修前修后记录，保留浅历史/未知历史安全保全、当前永保、N=0与Git命令失败先退出策略。11项回归全部通过，原helper仅新R100项失败。独立 reviewer `CODEX-LEAD-ASSISTANT-REVIEW-PR-340` 对最终完整 SHA `3949238eac55800a9dbcf80d17c589dc7234b384` APPROVE，记录[5991577813](https://github.com/narutojzm1-dot/youjia/pull/340#issuecomment-5991577813)，合入 main `9fd261d876a8777403a8697b4b9b7f8d17d4d1a8`。真实剪除段命令故障注入与N=0保全由独审复核；不是只测镜像实现。

最终正式发布：Actions [37289044064](https://github.com/narutojzm1-dot/youjia/actions/runs/37289044064) 原生全daily / Python11项 / 导出 / 发布均success，Pages [37289768031](https://github.com/narutojzm1-dot/youjia/actions/runs/37289768031) success。实际公开manifest `game-9fd261d` / source `9fd261d876a8777403a8697b4b9b7f8d17d4d1a8` / publishedAt `2026-10-05T09:23:53Z`；HTML data-build / executable / fileSizes一致。公网JS / WASM / PCK全部HTTP200完整下载，279815 / 39514754 / 21955748 bytes，SHA256与Git blob SHA1逐个匹配精确gh-pages `97e70a5aa2b825fffb7c68227b72b554e7b33757` 的tree与size。PCK SHA256 `cd1fc183d005dc54a2d3e2140de6d97968336a45f85f901ae5c631bf2939d730`；完整JSON/实际脚本在本目录，不提交大型运行包。

真实保留集合通过：发布前6组加新current，保留依次 `game-9fd261d` / `game-ba6d6c2` / `game-8cf4941` / `game-fd2e9fe` 四组；删除 `game-fbad3c4` / `game-fce84fe` / `game-ffeb6fb` 的24个整组文件。三组旧保留包的24个文件blob与size完全不变，当前js/wasm/pck及index别名存在。顺序来自真实gh-pages历史，非SHA字母/mtime/提交消息猜测。retention-340-actual.json记录 before/after精确SHA、实际集合/期待顺序及逐文件保留/删除；publish-340-job.log完整保留真实自动门禁与剪除日志，没有 incomplete-history 降级。本#333既有最近4组缺陷由该正式结果闭环。

边界：只能对当时实际仍存在的包按真实发布历史保留。旧字典序策略先前已删除的较新 a75/ad/c3 等包未在本修复恢复；不承诺所有过去版本长期存在。PR334 / PR340 改的是发布脚本，不需要冒充重新全游戏心流。游戏原生全daily由自动发布门禁运行；本轮鱼/音频/加载公网实玩确为[game-a75ae22](../2026-10-05-fish-miss-release/README.md)，不把其旧截图说成game-9fd261d实玩。
