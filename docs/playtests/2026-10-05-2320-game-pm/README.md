# 2026-10-05 23:20 GAME-PM公开近郊短体验

本轮实际北京时间23:24/UTC15:24开始。源码快照48309ba9f64d1ebea008841230a3fe954c5888ca；日节点冻结06da74694e256b4a92def2e0d9c4adad1aad0ef1；本次实际被测公开页为 **game-82f902a/source82f902a0f22f50032bff9acbe542d0f1953ae684**，属于节点后402原生声明适配的后续构建，不能冒日冻结源重测。页面data-build和加载后独立curl game-release.json完整来源一致，publishedAt15:25:26Z；[实际结果](result.json)、[重试时清单](manifest-at-retry.json)。未独立下载PCK核字节/哈希，manifest声明不当实测。

Linux桌面Chromium151.0.7922.173，1280×720/DPR1/headless软件GPU。自己的全新context正常新档，无导入、无重置用户档、无业务状态/存储故障注入。只做鼠标和方向键，非触屏/真机/真人实玩/耳听。五张原PNG未加工，PM逐张实际查看。

1. 普通标题点击(640,368)入院，[00-yard](00-yard.png)。
2. 点击院门方向(329,563)等6秒，无按钮/状态注入，自然到近郊，[01-go-out](01-go-out.png)，篮子空。
3. 点(706,500)沿路走开等5秒，再点院门(1060,390)等8秒，人物仍在近郊门边，[02-click-door](02-click-door.png)。
4. ArrowRight持3秒再等5秒，实际回到院子，[03-key-home](03-key-home.png)；方向键对照成功不是鼠标通过。
5. 再普通院门出门→(706,500)走开→更向门内(1100,320)点按，8秒后仍近郊，[04-door-endpoint](04-door-endpoint.png)。不以“还没等够一帧”解释两次点按结果；未读取内部spot或像素级足点，不声称重放了用户原图未知操作全链。此新独立公开路径补原BUG399，Owner Cloud。

当前源码near_path_scroll.walk仅direction非零且at_home持续0.45秒才自然回院，mouse walk_target归零分支不提供direction；静态疑点与上述输入差异相符，不代作者最终根因/修复验收。不以这些图关400横偏或天气001；初入院与回院画面未见用户原图那种明显宽留白，单此路径未复现不等全部相机无错。

## 失败和环境边界

初次driver页面/清单绑定断言失败停止，未保存两端具体值，不能确定加载时序还是发布切换，不把该次算通过。随后等待data-build并重新启动，成功绑定82f后执行上述动作。run.log/result只记录成功重试的执行。浏览器在04完成后因exec-server transport断连退出，计划的05-key-control没有执行/没有截图，不能计通过；03已有正常方向键对照。result.errors[]仅截至04的pageerror事件，不是console零或断连后全时段无错误。原脚本command循环保留实际方式，无进行中的PM浏览器进程。自然关页/保存/新照片/音频/新阴天/cleanup故障未覆盖，不用模型检查替代这些结果。
