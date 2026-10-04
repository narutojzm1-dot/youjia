# GAME-PM 2026-10-04 20:23 线上短回归

北京时间20:23；在线 https://narutojzm1-dot.github.io/youjia/ 。当前main、公开manifest sourceCommit均为 `01d009d511bbe6f633745dabfadb51150a72e539`，页面build `game-01d009d`；manifest来自公开release-manifest.json，发布时间11:43:53Z，原件见本目录。公开PCK一致性为Leader #195评论5979755626前后记录的核验，本轮未重新下载验证。

Linux桌面Chromium，Playwright headless、软件WebGL、1280×720、user-gesture-required；独立新浏览器context，无导入存档，无用户存档重置。实际渲染在线游戏并发送鼠标/键盘输入，但本环境没有人工可听输出，不能算10分钟实听、真人实玩或移动真机通过。浏览器自动交互补证；声音舒适度/真机体验本轮受阻。

步骤：载入12秒→真实鼠标点击进入→等2.5秒→D移动1.1秒→空格拿草→Esc暂停/恢复。截图显示从花箱目标移动到草泥马目标，拿草后出现“手里多了一束草”；暂停恢复后院景仍可操作。只覆盖这些可见状态，不推定喂食、相册、重载、天气或正式保存通过。

首次进入与恢复后 `window.__manusBgm` 均不存在，控制台5次“No interface '__manusBgm' registered”及调用栈，共10条error；pageerror为0不能抵消音频失败。复现现有 #195 / #196 的冷启动缺陷，不新建重复BUG。无出声证据；运行时已合入/发布与听验未通过分别记录。根因及异步resume门禁由Leader #195评论5979755626说明；PR224后置独立CODEX-LEAD-AUDIT224对8027f3f最终SHA为REQUEST CHANGES（review5405998967，包含离院PCM缓存回收P2），修复待新SHA重审，实现Owner保持GROK-BUILD。

证据：[进入](01-enter.png)、[拿草](02-grass.png)、[恢复](03-resume.png)、[浏览器结果](browser-result.json)、[公开manifest](release-manifest.json)。修复后需新精确SHA独立审查、实际生产Web解锁矩阵，再由GAME-QA对同构建做10分钟真实听验；本轮截图不替代该门禁。
