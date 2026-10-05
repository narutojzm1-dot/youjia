# #388 公网竖屏补验（2026-10-06）

Owner: CODEX-LEAD-ASSISTANT。接续[PR419公开后验](../2026-10-05-audio-touch-release/README.md)，不改游戏代码或重新发布。

公开manifest仍为source `348029a62a5952a7d7f5af5190147cf756934e14` / `game-348029a`，与PR394已独立终审合入的修复一致；该版发布Actions37335762412、Pages37336959942和15文件实际哈希已在PR419核验。本轮全新Windows Chrome154.0.8037.97，CSS390×844、DPR3、has_touch，HTTP/1，普通公网标题入院/暂停，未注入业务状态。实际该页PCK网络响应27080984字节，SHA256 `af762d697adfa1109916beb425ebf424fe9be5e40ee3707165bafa595d23ad92`，同一CDP读取真实响应，HTML build与测试前后manifest一致，见browser/source-proof.json。

本次进程exit0；31状态观测、9张未加工输入截图、errors0。总静音/音乐/环境各跑鼠标、触屏tap、约500ms持按释放、拖出取消、Enter恢复；实际活动音源数量/增益符合断言，按住尚未释放不切换，拖出取消不切换，单手势不重复切换。仅只读DOM/WebAudio观测，未冒真人听验或音色结论。父代理查看竖屏master-held-off和music-drag-cancel原图。

驱动基于PR419最终驱动，仅选单竖屏、首帧等待上限由300秒增为600秒；按钮坐标、断言、CDP包绑定不变。旧失败不覆盖：上轮默认传输超时/调试cache失败/HTTP1竖屏75%停滞保留在PR419。本次成功不证明加载稳定、HTTP2或物理手机全部通过。逐事件UTC见events.json。

和PR419同正式源的横屏31事件/9图合起来，#388所需两视口公开输入已齐；不是声称上轮exit1整批重新变成exit0。候选Linux strict64及Web62事件仍独立保留于PR394。此文档最终SHA经独立子代理审核合入后，可关闭#388三音频按钮重复切换切片。父#195原并发快速输入、真机、真人听验、BFCache/长时等保持开放；#382确认层输入独立后续，#413许可链接对比度排队；用户交制作人的#399/#400不接管。

archive-hashes.json列除自身外全部原件的长度/SHA256；.gitattributes保留原始字节。
