# #565 大鹅休息眨眼

Owner CODEX-LEAD；基线 df20696e2e8f7ebc14cd79edc21022e0104d60f2。只在真实静止 rest、正式 goose_rest 原画、非互动/摆拍/减少动态时播放独立4.5–11秒间隔、0.30秒闭眼与睁眼。只有可见眼区混合，身体/脚位/alpha保持。骑乘图入口同步清除眼区，避免跨姿态短暂错位。无新存档字段。

资源由内置 image_gen 编辑生成，透明RGBA原样复制为 goose_rest_blink.png；完整提示词、源图、实际路径及SHA256在 [provenance.json](provenance.json)。没有覆盖原图，也没有用Python改图。运行时 shader 只采样一个眼区，其余生成像素不参与画面。

348项本机检查通过：100眨眼、35姿态、105骑乘、25鹅食物回应、56羊回应、27大型动物避雨/夜归。大型动物套件首次因缺隔离数据环境退出，补专用临时APPDATA重跑27项通过；第一次眨眼测试误引用不存在的duck字典键，修正测试后通过，未掩盖运行时错误。日志随附。

实际GPU捕获（明确受控离线质量证据）[睁眼](gpu/goose-eye-0.png)、[半闭](gpu/goose-eye-50.png)、[闭眼](gpu/goose-eye-100.png)：2049像素变化，眼区外0、alpha变化0。不能将这些图冒作普通游戏操作截图。

普通Web 127.0.0.1:8781：进入→点地走近大鹅，实际看到大鹅由卧姿回站立；刷新最终构建再入院，记录实际日常场景及控制台。未注入调试状态，普通截图不确定捕到瞬间闭眼；骑乘与回应完整覆盖来自专项测试。无手机实机或真实声音听验结论。

完整CI和公开Pages/manifest/PCK核验随后以原PR最终SHA回执补充，未验候选不宣称发布。其余动物/主角步态及总Goal继续开放。

## 已发布回执

PR647 head `de84ffb824c9e731a43c744c3f7c0e2ca3bdd1cd`，tree `b341b97157b9f0eabc3b76e76629e3b7d30d388b`。CI37893919331、Publish37895747624、Pages37897780443全部成功；公开source `8d5b2aa88bd65fcb4db6fb9f2e4291eba6d3af04`。15:18实际下载PCK60,456,668字节，SHA256 `200d0a05a4b5b79ac847128eeb611527aa5bfa4e5f2d89df9e82dd663d667c29`。HTML/PCK git blob与gh-pages一致，10存档、4引擎、2加载模块实际SHA256一致。[清单](public/game-release.json)、[核验](public/verification.json)。普通公开页面重新载入旧第16天阴天、小米1、Beibei仍在，控制台warn/error空，随后暂停；[实际原图](public/old-day16-restored.png)。不冒称普通截图捕到瞬间闭眼。

发布前14:45邮件复查曾超时，15:20再次完整读取同一三消息决策线程，并搜索14:15以来含已读邮件，成功且无新增回复；更新本地去重水位，保留此前失败事实，没有额外发信。
