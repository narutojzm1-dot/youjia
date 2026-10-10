# #645 卧姿动物呼吸与眼帘：公开交付回执

Owner CODEX-LEAD，2026-10-10。两片分别实现与验证，不把候选、原画或原生受控场景当作公开上线证据。

第一片 PR688：head `bf0504ad17b1e17e0c55cedc863d8b1f79cfa816`，公开 source `8c6eb6b24d4661317192d22dd10031be02ebac4e`。CI38025675334、Publish38026759515、Pages38027535097均成功。实际PCK 65,919,788字节，SHA256 `7ffbf14f3e145bc9344f39b8ce979d0986a2419fdb690c6d52cacc89aa638505`。首页/PCK git blob、10存储模块、4引擎文件、2加载模块逐一下载核验，见first-public-verification.json与manifest。

第二片 PR689：最终 head `ddcb5567d18ea82a0dc95603a6c07ef3a826e341`，tree `59135a8836fe900e87e20b771bbc8b2ef489b886`，与本地合流提交 `8ddc891e242d3911da946a96504611e38e9dfabf` 同树。保留Cursor PR687的HUD与台账；CI38029527907通过，合入 source `ca16e0a24f2ad077c5d90f925e39e36959fc896c`。Publish38030520052、Pages38031437834成功。实际PCK 67,654,920字节，SHA256 `6acdc7476f1b483ae71467e3b848e0559c49a74d23519113bff7d6a9b8872170`；首页/PCK git blob与10存储+4引擎+2加载文件全部下载核验通过，见final-public-verification.json与manifest。

## 体验与兼容

正常公开页面重载、点击进入，既有第17天存档恢复；Beibei与成长鸡保留。背篓麦粒2、玉米2、圆石3、松果2与历史照片可打开，随后自然跨第18天。第一片390×844竖屏正常操作，未见warn/error。截图first-old-basket、first-old-album、first-public-390x844对应这次普通浏览器体验，无状态注入。

candidate-web-rain是第二片本地Web普通点击进入、晴→阴→雨后的回棚画面，不冒称公开包。当地浏览器连续自然跨到第5天，未见运行错误。六卧姿胸腹、两羊独立眼帘、起身/减少动态切换和照片冻结的GPU/连续录像/真实磁盘证据见 ../2026-10-10-resting-eyelids/；录像明确区分受控初始状态与后续自然运行。

最终公开ca16e0a正常重载后第19天夜间恢复，晴夜马/羊驼在各自区域卧下、牛羊在棚，随后自然进入第20天白天活动。390×844点击移动/相机跟随、背篓数量及旧照片正常；warn/error为空。final-public-night、final-public-390x844、final-public-basket、final-public-album为普通公开体验，未注入状态。

未覆盖实体手机或声音听验。耳动与额外睡姿仅为可选增强，未冒称已实现。#635斜向原画仍不合格，未用本单关闭整体Goal。
