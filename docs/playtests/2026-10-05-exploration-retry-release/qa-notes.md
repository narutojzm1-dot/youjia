# PR379 公开探索保存提示恢复验收

2026-10-05 UTC，独立浏览器 QA。PASS 本文特定故障边界。

首入和真正关闭后新开两页分别读取公开 game-release.json 并校验 HTML data-build；均为完整 source `d707113f8dde1636d24dfcff821518cd0555b277` / `game-d707113`，见 page-builds.json。未混用后续构建。公开 PCK 核验由 Leader 另行完成。

全新一次性 Chromium profile，1280×720 headless/SwiftShader。正常标题进入、点击石板路、四停点自然 E 查看/T 取物或置换，最终带落羽、圆石、松果各一。未改种子、位置、物品或游戏内存，未调用业务测试接口。

受控故障仅在回院前令下一次 IndexedDB intent key 的 put 抛 UnknownError 一次，触发时间 1791206343001。这是存储边界故障，不是自然网络故障。只读包装原 Host submit/resolve 记录完整原始参数与原回执、原样转发；全 DB 通过 readonly transaction 读取。记录的 transaction_state 来自真实 Host 原回执，不冒称另行捕获了原生事务事件。

- 故障后 current generation10：keepsakes={}，水位0，trip-1 active/revision9/三件 carried；intent不存在。16 原图显示实际“再确认一次”提示。
- 真实点击该按钮一次。原 write10 resolve = rejected、terminated、readback_verified=true；后继 write11 = confirmed、complete、readback_verified=true，generation11，三件各1、水位1、session pending_commit。
- 17 原图（点击后4秒）仍有灰色禁用面板，必须保留，不声称立即消失。随后正常 idle cleanup write12 confirmed/complete → generation12、session:null、intent不存在；20 原图面板已消失，无需重开才清除。
- 实际 page.close → 同 browser context 新页 → 正常标题进入；21 原图已回院无故障提示。重开 DB 与 settled current 完全相同，generation12、三件各1、水位1；20秒轮询不变，无重复授予。
- driver exit0；console.json page errors=[]。个人已查看05/16/17/20/21原图。

证据：run.py 可复用驱动，steps.txt 原始步骤，page-builds.json 两页来源，*-db.json 全 DB，*-receipts.json 原 Host 回执，01–23 PNG 实际截图。不是听验、物理断电、真机或完整故障矩阵；未重复候选，未修改生产代码。
