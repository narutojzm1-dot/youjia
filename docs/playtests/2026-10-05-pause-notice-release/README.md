# #348 暂停通知正式发布复验

Owner：CODEX-LEAD-ASSISTANT。本记录描述2026-10-05 13:13–13:14 UTC实际公开 `game-046871f`，之后其他版本发布不改变本次版本证据。通知修复已完成；#195输入/听验剩余仍开放。原实现和受控/本地档案见[候选记录](../2026-10-05-pause-notice/README.md)。

## 提交、原生与自动发布

PR [377](https://github.com/narutojzm1-dot/youjia/pull/377) 最终完整 `52a2be7b720e26d306d4d9c90ea8dd8471dfb87a`，独立 CODEX-LEAD-ASSISTANT-REVIEW-PR-377 APPROVE [5995013227](https://github.com/narutojzm1-dot/youjia/pull/377#issuecomment-5995013227)，合入源 `046871fa803f3eebd8b9900092bb07ff70671d52`。修复只改四方法通知部分及两显示helper；未改变输入、音频、存档或探索实现。独立终审实际168/0，精确旧Main替换基线168/112失败，另32项入口/低动效探针通过。

作者最新a067组合4.7.2完整daily57次引擎启动通过，原始日志在候选档案。本次真正合入046另含Cloud372拾物展示（合入父e0bb109d76c4f0b1713e173d2b223e8770858acc）；Main通知与测试/daily未变化。不能把较早本地a067 PCK或局部Main哈希当成完整046构建。

正式 [Actions37313949152](https://github.com/narutojzm1-dot/youjia/actions/runs/37313949152) 与 [Pages37314697585](https://github.com/narutojzm1-dot/youjia/actions/runs/37314697585) success。实际job111775885274完整日志无损gzip存ci.log.gz：58次4.7.2启动，57次验证加1次导出，PAUSE_NOTICE168/0、相册45914/0等门禁通过。没有用默认4.6.3冒充。job/run/提交元数据见release.json。

## 公网资源身份

实际清单sourceCommit为046完整SHA，entry game-046871f，发布13:09:43Z；HTML data-build与executable一致。真实网络完整下载JS/WASM/PCK、10个版本化保存模块，均HTTP200；模块实际SHA256及全部相对导入一致。连HTML/manifest共15文件的长度与Git blob逐一匹配真实Pages提交 `15798ce0f984f7aae9e8d42ff1070b8f46539b58` / tree `03d61298e7c0313cae9dcfd826e26a5417d3b068`，不是只检查HEAD/Content-Length。

正式PCK **25269536字节**，SHA256 **f556a65726ef66bd5a15d37af01baed92d2af707bef4c647050efdb74d40f808**，Git blob4084e7e67e9619c9bbcb65f9de359d6fae51e05c。public.json与tree-proof.json记录每个实际文件；验证脚本保留resources.py.txt。完整PCK不重复提交仓库。

## 自然公网操作

Chromium软件WebGL，CSS844×390、390×844，DPR3，两组分别全新浏览器，普通点标题与Escape。未注入游戏状态、存档、时间或音频图。browser.py.txt与完整browser.log/web/events.json保留，18条均严格game-046871f、errors[]，18张原始PNG全部保留未加工。

每组入院→早暂停→等约8秒墙钟→恢复引导→引导已可见后再暂停→等约5秒墙钟→恢复同一完整引导→继续可读→正常消失。已实际查看横竖屏暂停、两次恢复与过期原图：暂停面板不受通知覆盖，恢复提示完整。截图的软件渲染耗时计入wall_seconds，墙钟等待不等于Godot游戏时钟，亦未自然精确重现历史3de/500ms持续遮挡；确定的同帧/迟到入口问题由native证明。

| 观察点 | 横屏 | 竖屏 |
| --- | --- | --- |
| 可见提示再次暂停、5秒后仍无遮挡 | [原图](web/844-390-dpr3-pause-visible-hint-later.png) | [原图](web/390-844-dpr3-pause-visible-hint-later.png) |
| 恢复保留完整引导 | [原图](web/844-390-dpr3-resume-preserved-hint.png) | [原图](web/390-844-dpr3-resume-preserved-hint.png) |
| 正常过期 | [原图](web/844-390-dpr3-expired.png) | [原图](web/390-844-dpr3-expired.png) |

## 准确剩余与交接

英文仅native双语矩阵，未做生产英文Web、真人听验、物理手机、后台/BFCache、完整世界心流或全部存储异常。相册/确认框已有提示仍依原process更新，不声称这两个界面同步隐藏。候选控件观测横屏master失败且旧a067同处失败，#195继续可信DOM→Godot gui_input/pressed→TuningStore→后端增益归因；横屏unmuted expected=true只是值未变，不能当成功恢复。此次普通公网18阶段没有复测音频控件效果，不冒五控件全通过。Producer看图待，不代用户/制作人认可。Leader共享框架、Cloud探索及Producer资源Owner保持；#348通知切片可关闭，195父范围保持开放。

