# #291 正常生产入口自然点击与发布核验

Agent-ID CODEX-LEAD。运行时代码与最终审核1713c8073c3f0eb49dfe76a70a1ee27f6d5f15cc一致，合入76499128714eb17b92f7be15d550bcdfc43d305a。

## 本地正常导出，自然画布点击

Godot4.7.2，Chromium1280×720独立profile，临时目录在工作盘。未替换启动场景，未注入游戏状态、种子、计时器或瞬移。脚本只监听页面首帧事件，并用受控证据中的HUD文字像素模板识别按钮、安排点击；不是读取游戏内部状态。

从标题入院点水面(750,540)，角色自行走到岸边：7.6s等待，17.8s收竿；第一尾鱼收获后同一水面再抛，21.4s等待、27.3s收竿。两次按主按钮(1165,677)，第一尾中鱼与最后一尾小鱼的通知/投鱼按钮均在原图可见，第二竿没有被默认投鱼盖住。result.json的caught_via_button记录识别收竿后的按钮操作次数，实际成功另以first-catch.png/final.png读图核对。console/pageerror为空。

这不是跨真机/多轮随机稳定性验收，也没有新增携带多鱼库存。失败保留旧鱼/不重置旧鱼计时由生产类回归和#276原作者自然对照覆盖，本次流程验证两次成功。受控三视口证据和历史失败仍见../2026-10-05-fishing-active-hud/。

## 实际发布

- Actions [37266508299](https://github.com/narutojzm1-dot/youjia/actions/runs/37266508299)与Pages [37266810712](https://github.com/narutojzm1-dot/youjia/actions/runs/37266810712)均success。
- 公开与gh-pages raw的game-release.json一致：game-7649912，sourceCommit 76499128714eb17b92f7be15d550bcdfc43d305a，publishedAt 2026-10-05T05:13:17Z。
- 实际分别下载公开/raw PCK，21,925,756字节，逐字节相等，SHA256 `92af87daec4a29dc192964d5210431fc3e09d48099689e70f016c83638f3f77f`。见public-check.json。
- 实际公开844×390入院、暂停、两滑杆、恢复，data-build为game-7649912，console/pageerror为空，恢复原图已查看；未作听感或线上自然钓鱼的声明。本地自然点击与公开包来源校验是两项独立证据。
- 首次检查发生在Pages部署中，公开仍是game-f39e4ab而raw已更新，严格校验拒绝；等待Pages成功后才重查通过，未把workflow写分支成功当发布完成。

本次只发布钓鱼主操作修复，不关闭父#231其余体验、阴天#168、动物爱心#30、马尺寸#180或音频听验。此为普通13点批次，不能替代23点日版本节点。
