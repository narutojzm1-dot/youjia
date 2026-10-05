# 新绵羊照片漏拍修复：正常实玩及公开发布

CODEX-LEAD-ASSISTANT，2026-10-05 北京时间15:40–15:45。仅QA-EXP-20261003-002新照片子项，父#40仍Leader；旧档旧照片和其他摄影方向未关闭。

PR [320](https://github.com/narutojzm1-dot/youjia/pull/320) 最终完整SHA `8c364c0ab5a4d2b5550e7710485d0b428064c0ef` 经独立上下文 Agent-ID `CODEX-LEAD-ASSISTANT-REVIEW-PR-320` APPROVE，转录见评论5990163884。合入main `5a0a446577eba5916da51ad7f0e926f118045c01`。修复仅对没有同名ID的物种Owner按真实actor ID取景，不改相机/存档或历史图。

原生与受控Web证据保留[原修复记录](../2026-10-05-photo-species-frame/README.md)：专项同一9检查修前3失败/修后全过，目标Godot4.7.2完整严格daily通过；独立子代理另外重跑9构图、1332渲染、46保存兼容、110交互摄影全部通过。受控旧/新图是重现证据，下面是正常游戏入口的自然输入，分别记载。

正常本地生产Web导出（非测试场景）和实际公开game-5a0a446分别用Chromium全新context、1280×720，无复用用户档、无状态/位置/事件注入。实际点击标题进入院子(640,368)，点击绵羊(364,412)，观察“你轻轻摸了摸羊”，等待自然抓拍，点击手帐(114,675)。新生成照片题词“绵羊愿意靠近我了”，两只羊完整入镜。local-natural-album.png与public-natural-album.png分别是本地/公开实际截图；local-natural.json及public-natural.json记录输入和pageerror=[]。这是自然输入专项冒烟，未覆盖所有心流、真机或耳听。

[源验证和发布37278776707](https://github.com/narutojzm1-dot/youjia/actions/runs/37278776707)、[Pages部署37279176855](https://github.com/narutojzm1-dot/youjia/actions/runs/37279176855)均success。公网manifest实际sourceCommit=5a0a446577eba5916da51ad7f0e926f118045c01，engine=4.7.2.stable.official.ed1daf0bf，entry=game-5a0a446，publishedAt=2026-10-05T07:41:38Z；HTML data-build及executable一致。核验时间2026-10-05T07:42:50Z（北京15:42:50），完整下载JS 279815、WASM 39514754、PCK 21927084字节，后两者与HTML fileSizes一致，三文件Git blob哈希与gh-pages `37cec9ba116915153b1a4d17f0f6e112188b3743`树完全相等。详细SHA256/HTTP200/manifest见public.json；PCK SHA256=9df9591a1d2ad2104d156c930d8e0b0a941de62c63648bed75bcf23b175c4492。未将本地导出当成上述公开部署。

分工接收见#242评论5990178078：Assistant接收#180/#231/#195/#234/#167剩余缺陷队列，先核已发布修复和未覆盖点；不是五单同时实施。原#285及#300/#317候选已交制作人（#155评论5990066745、#194评论5990067000），现有SHA/审查保留，接续回执待，不并行改资源。五张原单已回写queued接收状态，均未冒代码进行中。下一候选只复核#231已发布odd提示及剩余旧鱼miss文案歧义，先查最新认领、登记具体方法再实施；GROK-CONTRIBUTOR PR276既有测试/真实Web三序列范围保持，不重复全矩阵；Leader#149/#150生产存档及Cloud探索范围保持。

