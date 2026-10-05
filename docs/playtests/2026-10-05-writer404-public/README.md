# PR404 公开双页保存占用指引与真实重试验收

PASS 本次正常双页路径。生产源完整 `c1a2b0f4ec5966b4955c54e7be3934933482aff2`，首次页、第二页、第二页真实reload三次HTML data-build与实时manifest均严格同源，见builds.json。没有使用旧e412构建，公开PCK/十模块由Leader另行实际核验，本QA不冒称重复核包。

一个全新Chromium context，桌面1280×720、headless/SwiftShader。第一页正常进入、点羊产生自然照片、打开手帐；第二页普通加载同公开URL，真实WebLock竞争显示“另一页正在游玩 / 请回到原来的页面，或关闭后在这里重试。”与重试按钮（second-blocked.png）。第二页没有first-frame，不绕锁进入游戏；原页仍显示照片（first-preserved.png）。无锁、存储或业务状态注入。

真正关闭第一页，在第二页实际点击DOM重试按钮执行生产reload，正常标题进入并打开手帐，原羊照片、假期第1天及两句题词保留（second-recovered-album.png）。已实际查看上述原图；first-album.png保留初始画面。

完整readonly DB三阶段（第二页前/第二页阻断中/关闭原页重试后）精确相同：youjia-save-host-v1的records只有current、generation2，无intent，未覆盖或重复照片。见records.json；actions.json记录输入时间，run.py/read_db.js为原始驱动与只读查询，console.json完整日志。driver exit0，pageerror=[]、console error=[]。

只做一组普通公开双页，未称触摸/真机/断电或全部失败原因浏览器矩阵；候选静态/专项证据与本公开体验分开。未修改生产或仓库源码。

## 发布归档

原始普通浏览器证据由 review304 采集，review301 仅归档；README本段为归档补充，其余原件按 original-copy-verification.json 逐字保留。PR404最终 `ab358411604a667541042c638f17ba87c93a4ece` 已获[独立终审](https://github.com/narutojzm1-dot/youjia/pull/404#issuecomment-5996902915)，合入并发布源 `c1a2b0f4ec5966b4955c54e7be3934933482aff2`。

[Actions37327781206](https://github.com/narutojzm1-dot/youjia/actions/runs/37327781206) 与 [Pages37328500074](https://github.com/narutojzm1-dot/youjia/actions/runs/37328500074) 均成功，原始API响应见 release-actions.json / release-pages.json，CI原日志无损gzip保存见 actions-full.log.gz（解压逐字原件，保留原始行末空白）。Leader实际下载公开PCK为27,078,648字节，SHA256 `e73feb420947465c436f9c6fb1d22b066ed3bcafe46beb5401f0a33bc7b688bd`；公开/raw及十模块源码逐字一致，见 public-release.json。

仅双页占用启动指引这一范围闭环；#150共享存档整体及Cloud领域cleanup恢复未据此完成，未覆盖全部失败原因/触摸/物理断电。
