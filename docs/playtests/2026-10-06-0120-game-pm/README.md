# GAME-PM 01:20轮：暂停与离开确认（有限公开观察）

页面锁版2026-10-05T17:32:13.490Z，末次截图/记录17:34:38.756Z（北京时间10月6日01:32–01:34）；页面加载在锁版前启动。源码main与页面source均ecea67dba1afc9b99b6097970e4965fbcd99c53a；HTML build game-ecea67d、独立curl [game-release.json](https://narutojzm1-dot.github.io/youjia/game-release.json) publishedAt17:22:08Z，原值见[result.json](result.json)。本轮没有下载PCK核hash；Leader17:23:49公开核包是他方独立发布证据，不能冒本轮PM核包。

Linux Chromium151.0.7922.173 headless/SwiftShader，1280×720 DPR1桌面鼠标/键盘，全新自己context，无用户存档导入/重置、无业务状态注入/存储探针。浏览器正常关闭；不是真人实玩、物理设备或实际出声。PM亲看六张原PNG。

1. 驱动等HTML build并再等12秒，初点640,368：00-yard实际仍加载壳，不按文件名冒入院成功。Escape后01-pause仍非已验暂停。再等10秒，02-ready确为标题。
2. 点击640,368→等1秒→Escape→等0.7秒：03-pause确见院内暂停面板，音量显示100%。没有操作声音控件、不验证听感。
3. 点击640,278（回到门口）→等1秒：04-return-title实际是“现在离开吗”确认框，不是标题。
4. 点击640,373→等1.2秒：05-title仍是确认框，好按钮有焦点。当前只能确认这次截图没见离开完成；不据单次点击定根因/新BUG，也不称退出通过。未测试取消、触摸或确认后继续，不能替代Assistant #382专项；没有重置“再过一次假期”。

本轮未覆盖照片转屏/关页/返院链（Leader在同构建持续验收，避免重复）、天气连续性/阴天新图、持久化、真机、声音。没有新增可确认BUG编号。[原输入驱动](browser.cjs.txt)与result保留未完成结果；未覆盖不计通过。01误名保留原证据，不重命名成成功路径。
