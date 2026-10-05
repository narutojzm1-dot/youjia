# #388 / PR394 正式公开版后验

Owner: CODEX-LEAD-ASSISTANT。执行窗口跨北京时间2026-10-05 23:00轮至10-06凌晨；这是缺陷后验，不替代Leader的正式日版本记录或邮件。

## 来源和门禁

PR394最终head `ff33c16655c530ef0755a7a36f588ad70b46289f` 经独立子代理 `CODEX-LEAD-ASSISTANT-REVIEW-PR-394` APPROVE后合入，merge/source `348029a62a5952a7d7f5af5190147cf756934e14`。此前Windows59次调用、最终Linux完整strict64次启动及候选Web证据见[本地接续档案](../2026-10-05-audio-touch-routing/local-continuation/README.md)，不混作下述公网测试。

[正式发布Actions37335762412](https://github.com/narutojzm1-dot/youjia/actions/runs/37335762412) 对merge348029执行发布辅助检查、完整游戏验证、Web导出和发布，success。[Pages37336959942](https://github.com/narutojzm1-dot/youjia/actions/runs/37336959942) 对gh-pages `1340aabbb469cf2eea53f0ae6f55f65be9c167ae` 部署success。原始状态记录在public/。

公网 https://narutojzm1-dot.github.io/youjia/ manifest为 `game-348029a`，Godot `4.7.2.stable.official.ed1daf0bf`。入口/manifest/js/wasm/pck及10存档模块共15文件实际下载：长度及Git blob SHA1均匹配Pages树，模块SHA256同时匹配manifest；校验前后manifest未变化。PCK为27080984字节，SHA256 `af762d697adfa1109916beb425ebf424fe9be5e40ee3707165bafa595d23ad92`。完整文件表、Pages树和原始manifest见public/；不把仅HTTP200当版本绑定。

## 实际公网体验

Windows Chrome两次全新浏览器尝试CSS844×390和390×844，DPR3/has_touch，使用--disable-http2限定HTTP/1。横屏成功从公网普通标题入院再暂停，实际捕获PCK网络响应并核SHA256，HTML data-build及测试前后manifest一致；横屏版本、浏览器及实际加载包见browser/source-proof.json（只有1条）。PCK为该横屏页面实际响应字节；前述15资源独立下载核验不冒该浏览器逐份响应证明。竖屏等待300秒未到首帧，未执行输入矩阵，整体进程exit1，不能称整批通过。失败原图与资源时序在browser/390-844-load-failure.*。

横屏31个状态观测、9张未加工输入原图、console/page errors为0。总静音/音乐/环境分别覆盖鼠标、触屏tap、约500ms持按后释放、拖出取消和Enter；断言实际播放路数及活动AudioParam增益，持按释放前不提前切换、tap/释放只切一次、拖出取消不切换。驱动仅只读DOM输入和WebAudio观测（包装调用保持Reflect返回），不注入业务成功状态。事件UTC及真实输入记录见browser/events.json，驱动全文附档。竖屏无成功事件，不将候选62条或失败截图计入公网通过。

首次尝试在120秒内未等到首帧，尚未执行按钮测试，日志first-attempt-timeout.log原样保留，不计通过；重试把首帧等待上限增至300秒并添加失败截图/资源诊断，加载成功但读取实际PCK响应时调试缓存已被回收，日志second-attempt-response-cache.log保留。第三次增加CDP缓存但仍从Playwright另一会话读取，出现同样取证错误，third-attempt-response-cache.log保留。第四次改为同CDP会话读取，在300秒时仍停下载84%，无脚本错误，原图/资源时序在fourth-attempt/，日志另附。最终改用HTTP/1重试，横屏完成、竖屏仍下载超时；CDP绑定及按钮断言不变。部分成功及失败记录都在browser/及browser.log；这不证明HTTP/2或整体加载稳定，没有据此推定超时的产品根因。

## 收口边界

#388状态：修复已独审合入并发布，公开15资源校验与横屏输入通过，竖屏公开矩阵缺失，保持开放。下一轮先核实际公开源并补390×844公网输入及PCK绑定；只在完整后验通过后关闭该单。#195仍开放：原并发快速输入、物理设备、真人听验、BFCache/长时及全心流未由本测试覆盖。#382确认框/底层滑杆及半暂停独立待修；#413标题许可链接对比度排队。用户近期反馈#399/#400由制作人跟进，不重复接管。归档原件SHA256清单见archive-hashes.json；自身不列入自身哈希。
