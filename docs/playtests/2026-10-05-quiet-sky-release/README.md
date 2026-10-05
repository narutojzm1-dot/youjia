# 普通回应、马休息与静观天空修复的公开验收

Agent-ID: CODEX-LEAD。2026-10-05 北京时间14:56后复核；本记录不是23:00日版本节点。

## 交付与审查

- PR302 普通抚摸不默认爱心、短暂面向玩家，final d3094f136720ac010ac33c8a789957fac2661011；独立审核5989274048，merge3ed47d7a3d5c608720f54ca3d5d282143d8d2e5d。
- PR304 停用尺寸不一致的马休息tail贴图，final97fc91eb5d7a5375e6d292fa0d47c2638aa5e148；独审5989199336，merge6a3ffd5a7fcde9e7c8b8f68a1eb62c02742c3eeb。固定transform实际贴图路径的29.13%高度跳变见[原证据](../2026-10-05-horse-posture-size/README.md)，不代表全部马组合验收。
- PR308 静立看天空请求zoom1.14→1.0，finalcdb74fb87bf3405707864867d6f7c9374f78b47c；独审5989489064，mergeea7f1a0c2390e2e1bd9e70883d217b48070035f6。quietsky15项、完整daily及生产导出通过。两模式Main实际相机对照见[原证据](../2026-10-05-quiet-sky-scale/README.md)。平移机制保留，跟随分支改变，不声称相机完全静止或平移轨迹不变。

## Actions、公开文件与构建来源

308构建[37273905150](https://github.com/narutojzm1-dot/youjia/actions/runs/37273905150)成功。06:51:20Z公开与gh-pages原始manifest均指向ea7f1a0完整SHA；实际下载两份PCK逐字节一致，21,926,140字节，SHA256 af91e882dcdbadc5bdef5bac34f6c1b6d01ec456e8b4d8901ed8a6675eea236e。原始记录public-release.json。

浏览器首轮断言预期game-ea7f1a0却读到后续game-c93a9b4，故该次停止且不计通过；后续协作文档PR312又触发发布。重新核验固定实际game-b5bf35d/source b5bf35d69005858cdf706edb8ec72b7184f8ac55，包含302/304/308；后续310/312只改协作文档。

[构建37274550947](https://github.com/narutojzm1-dot/youjia/actions/runs/37274550947)和[Pages37274862964](https://github.com/narutojzm1-dot/youjia/actions/runs/37274862964)均成功。06:56:40Z公开/gh-pages manifest一致，publishedAt06:54:56Z。两份PCK实际下载21,926,140字节、逐字节一致，SHA256 **96ebe019ccb386097d1ed9277c699df8c603a697b7b3ec69940713223d5907a8**。见public-release-latest.json。manifest无哈希字段，这里是实际计算结果；不同构建PCK不可混称相同hash。

## 实际浏览器范围

公开 https://narutojzm1-dot.github.io/youjia/ ，Chromium桌面headless模拟844×390，新隔离context，无玩家旧档。实际HTML data-build game-b5bf35d；首页→入院→暂停→分别调整两条音量滑杆→恢复，console/pageerror为0。public-pause.png和public-resumed.png已实际查看，分别显示18%/71%与返回院子。仅UI/启动检验，不代表实际听到声音或真机长时稳定性。

另一路公开自然输入：入院后点击马附近、等待6秒，再在马轮廓位置输入8次点击，每次250ms。保留选中帧和全部8帧；已查看selected/0/7。实际已看帧显示“你轻轻摸了摸马”且未见默认心，目标栏也出现水塘岸石，说明附近目标会动态切换；后续画面仍有观察平移，不据此声称所有镜头保持完全静止。截图中的反馈与目标需以实际图像判断，不将8次输入等同8次成功业务交互，持续提示也不证明每次都触发成功。此路径无状态注入、错误0；精确zoom数值和两模式对照来自上方Main受控Web证据，不从公开截图猜测内部数值。

## 未完成范围

#30完整姿态资源、鸭鹅回应与互动短音、#180完整自然遭遇/照片重放、#51新阴天底板、环境音真实听验和探索正式接线仍分别跟踪。#150候选预算已入251研发分支，不是生产Host冻结；本次发布不包含外出探索或云存档。公开画面仍能看到旧阴天构图差异，不把本批镜头/贴图修复写成天气已完成。
