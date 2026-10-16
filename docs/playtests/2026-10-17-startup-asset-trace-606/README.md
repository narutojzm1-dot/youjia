> 本页最后“最终实际公开核验”为收尾结论；前面保留各时点候选及失败的真实身份。

# 分资源启动诊断与溪流编码对照

Agent-ID CODEX-LEAD。本次源PR834完整fe58482180534a86ab3f36f504a4a247455d4f9d，基于main55bdc47a；仅web/loading.html与既有loading_shell_test.cjs。此页初次归档时完整CI38957029528/job117162361393仍在运行、Draft未合入/未发布，不能当公开证据。

## 诊断边界

沿用下载器已给出的url/offset/source回调，网页保留最多32条按config已知PCK/WASM名称索引的assetEvents，相对时刻、命中或重试、cache/network来源、偏移与尝试次数。全局assetCacheHit/downloadRetry仍是首个事件时刻；未知资源、外部URL、额外查询、任意错误对象不留入新记录。完成/失败后不收迟到回调。下载恢复的次数、20秒界限、整包校验、SaveDB和玩家UI均未改；这不是原公网停滞根因修复，不关闭606，也不接管ASSISTANT原范围。

既有启动模块/失败/旧入口/firstFrame等夹具及新增混合资源、32条上限、URL过滤、完成和失败后迟到保护通过。新增测试第一次将Promise拒绝误当同步，补微任务等待后通过；该夹具失败保留观察记录，不当生产缺陷。

browser-trace.cjs用实际本头HTML及未改be0下载器，在真实Chrome以原生CacheStorage与8字节受控资源运行，默认20秒watchdog：WASM命中/PCK网络读4字节后停住→network重试offset4；另PCK缓存读4字节后停住→cache回退offset4，两者记录明确分开。暖缓存无网络重试，存档阻断取消不补重试；四场景pageerror均0、indexedDB getter访问0。此为受控启动链，Engine/保存桥为明确stub，不冒充游戏实玩/公开包或真档保留。完整游戏与正式发布仍需单独核验。

## GROK-BUILD PR804 b739复核

完整b739519cc52a41873a9eb19d2abb53abeff7bcbc的21新增/变更隔离文件已逐份固定SHA读取并比Git blob SHA；最初Git按需取单blob超时，改HTTP取原件后核验，失败未当通过。旧a7视频不变。最终review5552801720与749回执6223304706已解除前轮具体编码对照等待，保持Draft/未接入/未最终验收。

独立MP4 stss表与x264内嵌头：旧同步关键帧0/250/500/750/1000、keyint250，新单GOP仅第0帧、keyint1200。两片均实际完整解码1280×720/30fps/1200帧/40秒。新视频916236B，SHA256 054d983a4bee0660d189ba58ae667c595f4f4b5a3f51dfcf4d343aa1c4f81271；全片RGB相邻差median0.00484664，max0.01154369在3→4，旧大峰四点消失，独立数据/脚本与原PNG、两种编码裁切联系图见本目录。裁切分辨率不同，不假装像素等价；作者已提交原REALTIME_MOVIE输出和编码命令。

结合旧峰与关键帧对应、PNG小样和单GOP对照，支持旧整画面大峰来自编码刷新，不是shader圈界。完整1200张原PNG仍不在本环境，916141静止像素/loop_max0/首圈3电平等全片统计保留作者来源，未独立复算。固定时间步录屏不是持续30fps性能；生产Host/实体GPU手机/完整10×5/正式美术仍未通过，749开放。源码与源视频留在原804，独立联系图大原件同时随迁移补包，不重复寄未改美术的同阶段预览。


## 最终实际公开核验（此前CI在途为初次归档历史）

PR834完整fe58482180534a86ab3f36f504a4a247455d4f9d经review5553167768及完整CI38957029528/job117162361393通过，合入实际运行源码`c8d994fecf83195e2949820324c24520dec19302`，树66661fbf82440ffb440537ed8ca5bb99a7b2bbc1。完整解码日志457592B/SHA256 63891131dbd17ad080c901e3dba4ecf5efb7ac22c988b884605b9e6aa13ceee4，实际Loading shell PASS入口完成、无SCRIPT ERROR/工作流ERROR，Web导出及pinned WASM修复通过。没有重新运行未变的专项来凑检查。

唯一自动push Publish38960567328/job117174282541、对应Pages见原始元数据均success，未手动重复dispatch。实际`game-c8d994f`，固定gh-pages `9d7b02a2beb1528a1f06d3db7e1b7298b1522165` 与公共站点38份完整文件一致；实际双端完整PCK **90525076B / SHA256 f81562a030441efead75846279ee5879c1ff80c8c126f828a8b97b5f9436dc50**，核验UTC `2026-10-16T20:43:02.378299+00:00`。实际PCK内source与公告/公网UI相符。随后本资料合入头仅文档，不当新运行包。

本头模板与旧正式be0完整包的本地混合测试另列hybrid-trace-game原件，firstFrame8.529秒、实际关Chrome进程重开6.005秒，自然生成第4代inventory/album/keepsakes保留，pageerror及console数组均空；它不改标下述本头完整公开包。

普通真实正式站点自有既存QA profile，未清档、未写fixture、未替换HTTP/CDP包。成功轮次`ordinary-attempt-1`：旧完整envelope/payload第5代保持；firstFrame **15.284秒**，实际关Chrome进程重开 **6.702秒**，手动重试`False`。逐5秒进度、所有网络失败/控制台/页面错误、新assetEvents与每轮截图见原始JSON，其他失败轮次同目录保留，不覆盖。基线来自前轮be0实际关进程重开记录，非假档。

本次普通入口首次分资源事件：
```json
[
  {
    "at": 1275,
    "asset": "engine-e232d3881ea999631bbb4a08ccc86fa54dd2bc8a5b42fb6cb281cb86dd85bc48.wasm",
    "kind": "cache-hit",
    "source": "cache"
  }
]
```
重开分资源事件：
```json
[
  {
    "at": 42,
    "asset": "engine-e232d3881ea999631bbb4a08ccc86fa54dd2bc8a5b42fb6cb281cb86dd85bc48.wasm",
    "kind": "cache-hit",
    "source": "cache"
  },
  {
    "at": 45,
    "asset": "game-c8d994f.pck",
    "kind": "cache-hit",
    "source": "cache"
  }
]
```

本次普通站点没有重试、请求失败、控制台或页面错误；首轮仅记录WASM缓存命中，重开记录WASM/PCK均命中。网络/缓存回退分支由上述四场景受控真实Chrome链验证，不冒充本次公网确实触发了回退。时长不是同条件性能A/B，不据一次更快进场称性能提升或根因解决。

这些只对本轮实际观察负责，不外推原45%/42%公网失败的唯一根因，也不把没有记录的网络阶段推断成缓存故障。#606继续开放、ASSISTANT原Owner和生产范围不变。实际普通日志已有资源名，发生重试时会保留回退来源，后续可按路径定位；无新存档或玩法规则。10月16日日推和同阶段资源预览未重寄，本次不是10月17日23:00日节点。

收尾PR804最新完整25f35c4feea59903afd7902ac3e5611da08f7c63相对b739仅README增加单GOP视频推荐说明，代码/视频树未变，已补核文字项并接受；新完整diff与哈希见grok25-static原件。b739实际解码/原PNG小样证据不改标为25新运行，仍Draft/未接入/未最终验收。
