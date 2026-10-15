# #535 场景音乐候选

Owner CODEX-LEAD，2026-10-07；基线540合入a1bef56e4515ae49a9d46451700cb12977325a59。不是公开发布验收。

## 实现与必要检查

原Main不提交音乐场景，AudioDirector固定yard.music。现在实际探索进入选near_path.music，回院/新假期选yard.music；保持同一双播放器/后端/音量/暂停逻辑。原创近郊76.8秒候选及来源/乐谱/测量/试听见[资源说明](../../../art/concepts/near_path_music_20261007/README.md)。声音资产SHA2563286356d45ffd5668f079ddffc7a3f687e4d38a5e9d1ef1c9387feff7b02a38a。

- 音频104项：重复事实不重启、不同资源、后台切换/恢复、静音/零音量、快速切换后只剩一声源、缺轨安全静音、标题停止/迟到回调不复活。
- 真实Main探索305项：恢复旧外出、实际出门/正常返回/中断回标题/重新入院均匹配对应cue；原存档与采集回归保持。
- 环境输出上限30、声音按钮648、基础417项通过。
- 音频suite加入每日严格门禁；completion正数/缺失/错误/前后缀反例通过，UI completion组66项。
- 首次探索检查因本地稀疏检出缺少仓库原锚点JSON产生SCRIPT ERROR，runner按失败退出。恢复HEAD原文件后重新运行通过，没有修改断言或吞掉错误。
- Web导出exit0、无ERROR，index.pck SHA256 `8e04bc5225b52a56d31a167642f4311ee76570a321612af1277897def65adc44`。

本地证据日志：Temp/youjia-basket-check-6c4e2a16-50dc-4e66-9679-a0e73391b9c7（前三项通过、探索缺文件失败）；Temp/youjia-basket-check-76fe86e0-a5d5-4525-9adb-8eb5d063f6eb（探索305/基础417）；Temp/youjia-scene-music-gate.log；Temp/youjia-scene-music-export.log。

## 普通Web操作及限制

`http://127.0.0.1:8765/scene-music/index.html`，IAB普通游戏页面，旧35天档。真实点击进院、沿小路出门、近郊暂停、音乐关闭/打开、继续、回院；页面正常，warn/error为空。`returned-yard.jpeg`是该趟返回画面。未改隐藏存档/游戏状态，不用截图证明可听差异。

**仍待真实耳机/扬声器听验、连续10分钟循环/淡化舒适度、浏览器PCM/整体内存峰值及实体移动设备。** 原生与Web页面操作仅证明状态/可玩路径，不代表实际声波、无缝或音乐审美通过。此PR保持Draft，不将候选曲目发到main；#535第8项与#196听验保持开放。
