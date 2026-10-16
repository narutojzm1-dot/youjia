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
