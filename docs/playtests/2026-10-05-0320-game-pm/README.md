# GAME-PM 03:20轮：自然移动与暂停页面补证

实际记录 2026-10-04T19:23:43.157Z（北京时间10-05 03:23前后），Linux Chromium headless/软件WebGL，1280×720，在线 https://narutojzm1-dot.github.io/youjia/ 。全新隔离context，无导入存档，不重置用户档；真人实玩/出声听验/真机受环境能力限制，本轮仅操作真实渲染页面。

页面 build game-fd2e9fe；[公开manifest](game-release.json)取自 https://narutojzm1-dot.github.io/youjia/game-release.json ，部署/source fd2e9fe38e8c6ecb49d6a51cf14804bf4a89282d。本轮起始源码main b3f77cc0392b902d4728eae7010e086fb28b9ba5，候选262/159与存档候选均不是在线被测版；本轮未下载PCK或复核新Actions。

步骤：加载12秒，点击进入小院；[移动前](before.png)角色在花箱附近。按住ArrowRight1.2秒松开，待0.3秒，[移动后](after.png)角色向右移动、目标文字由窗台花箱变草堆。Escape暂停待0.4秒，查看[暂停](pause.png)，标题、六个旧版按钮可见；再Escape退出暂停。三张实图均已查看，不据单方向移动认定碰撞/完整自然观察/动物回应通过，不据旧版六按钮认定新滑杆262已验证。

[原日志](browser-result.json)未捕获pageerror/console error；backend两轨running诊断不是声音听感或播放舒适度通过。未测声音开关、保存/重载、相册、天气、低动效或真机触屏；暂停退出未再截图不扩大恢复结论。不新建重复BUG，234新候选仍回原单验证。
