# GAME-PM 01:20轮：暂停、确认退出渲染补证

实际在线记录2026-10-04T17:19:17.886Z（北京时间10-05 01:19:17），按实际执行时间记录，不伪称定时准点完成。Linux Chromium headless、软件WebGL、1280×720，全新隔离context，无导入存档、不重置用户存档。真人实玩/实际听验/触屏真机受环境限制；以下是浏览器页面操作与渲染证据。

地址 https://narutojzm1-dot.github.io/youjia/ 。页面build `game-fd2e9fe`；[manifest副本](game-release.json)实际来源 https://narutojzm1-dot.github.io/youjia/game-release.json ，source `fd2e9fe38e8c6ecb49d6a51cf14804bf4a89282d`、engine4.7.2、publishedAt15:11:30Z。当前源码main `c62d3140c08e6e172bc73ad31bc1cd67707fbea0`，与公网/实际被测版不同；本轮未下载PCK/复核Actions，不把旧hash当新下载。滑杆245仍不在此被测版。

步骤：加载12秒，点击(640,367)进入院子；Escape暂停，查看[pause](pause.png)；点击(640,245)继续，随后Escape再暂停；点击(640,357)回到门口，查看[离开确认](leave-confirm.png)；再点击(640,367)确认，查看[标题页](title.png)。本轮没有操作“再过一次假期”，没有重新进院。

截图均实际查看：暂停各项可见；离开确认有“好/再待一会儿”；确认后实际出现“悠长的假期/走进院子”标题页。[原日志](browser-result.json)显示确认前backend buffers2/playing2，确认后buffers0/bytes0/playing0，页面/console错误为空。渲染与诊断证明此次退出路径释放缓存/停止轨道，不证明真人听感或耐久保存，也不能关闭195/196所有缺陷。

未覆盖：退出取消、重进/重载存档、10次两轨开关、异步回调/后台、声音舒适度、触屏、天气、动物演出、照片保存及main新滑杆。原BUG沿原单；不建重复问题，不把headless算正式体验通过。
