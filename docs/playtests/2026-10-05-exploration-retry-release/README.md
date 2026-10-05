# PR379 探索 trip 保存重试提示：公开发布验收

PR379 已合入、已发布，并完成下述限定公开体验；不是日版本节点报告，不宣称 #150/#305 全部完成。独立浏览器 QA 原记录见 [qa-notes.md](qa-notes.md)，保留原文；其中01–23图指原始目录，仓库仅归档16/17/20/21四张必要原图，其余原件位于 `/workspace/exploration-retry-public/`。

## 发布来源

- 生产源：`d707113f8dde1636d24dfcff821518cd0555b277` / `game-d707113`；[首入和真关页后两页HTML/manifest](page-builds.json)严格同源。
- [Actions 37314627037](https://github.com/narutojzm1-dot/youjia/actions/runs/37314627037) success，head上述源；[Pages 37315444581](https://github.com/narutojzm1-dot/youjia/actions/runs/37315444581) success，gh-pages `74ca0c1b461e6654c1c7dcf56cd5b06c7236dde6`。
- [公开包核验原件](package-verification.json)：PCK 25,271,456 字节，SHA-256 `098a4b70598a6bc261e26cf7ae9e38c5fb10ab5be07c8bdb7284c40f1fafe83a`，公开与raw一致；十个存储模块公开/raw/源码哈希一致。该构建核验来自Leader，浏览器QA未冒称自己重新下载了包。

## 本次验证范围

正常UI出门、停看、自然取得落羽/圆石/松果各一；未改种子、物品、位置或调用业务测试接口。独立新context、桌面1280×720 Chromium/SwiftShader。回院前仅一次真实IndexedDB intent put受控抛错，属于trip提交故障，**不是另案已授予后session:null cleanup写失败**。

[16失败提示](16-t1-home-5.png) 对应 current generation10、keepsakes空、水位0、三件仍carried；一次真实点击“再确认一次”：原write10 resolve可信rejected/terminated，后继write11 confirmed/complete、generation11、三件各1/水位1。[17点击后4秒](17-t1-after-retry.png) 仍有禁用提示，不能说立即消失。随后正常cleanup write12 confirmed/complete，generation12、session:null、intent不存在；[20同页稳定画面](20-t1-settle-2.png) 面板已消失。

真page.close后同context新页，[21恢复画面](21-reopened.png) 无失败提示；[settled-db.json](settled-db.json) 与 [after-reopen-db.json](after-reopen-db.json) 完整DB一致，三件各1、水位1，20秒轮询无重复授予。原始 [steps.txt](steps.txt)、[run.py](run.py)、各阶段`*-receipts.json`保留Host调用与原样回执；事务状态来自Host真实回执，不冒称额外捕获了原生transaction事件。[console.json](console.json) page errors为空。

所有归档原件字节/hash见 [archive-provenance.json](archive-provenance.json)；无缓存或导出大包。不含听验、真机、物理断电及完整故障矩阵。

## 未解决范围与交接

上述379收口的是trip重试新op的提示恢复；[独立cleanup失败证据](../2026-10-05-exploration-idle-cleanup-public/README.md)仍成立，不能用本次正常cleanup成功取代该故障用例。cleanup API/身份与队首比较方案仍在研、未冻结，Cloud idle生命周期范围尚无接收回执，不宣称已开工或已修复。Leader共享状态/Main与Cloud探索方法边界保持；#150领域组合继续开放。
