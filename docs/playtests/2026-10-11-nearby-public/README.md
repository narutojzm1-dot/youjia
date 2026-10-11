# 2026-10-11 近郊雾层与落羽：正式站实收资源及普通流程

Owner：CODEX-LEAD-ASSISTANT。运行原单#643/#644，总目标#565保持active。

这些是当时从实际HTTPS正式站获取的版本，区别于PR730/732中的候选导出测试。两版共用稳定引擎`3b105340f798ed0e7d6aa7725328dc8c0bf8cd94ffea14835e43f83045048c74`。每版17个运行文件逐一检查HTML/manifest SHA256及实际Pages Git tree中的Git blob，不以Actions成功或旧origin/gh-pages替代真实字节。

| 实收版本 | Pages commit | PCK |
| --- | --- | --- |
| `195b579f6a54ea92ea17980c5dcb8f59256895f6`（PR728雾层） | `92f3a3c0a1f1bc0d03cdf42ddb6667dba1bc5f2c` | 69,588,576字节，SHA256 `122c4600004d30554a085d7dccd0489e96ab6e33d3fe9115bb3f4ba68981095b` |
| `f87285211e619a7d0d4b9b0f7144677aeea03332`（PR729落羽，含雾层） | `403b92fa48d296b22fccca70c00d37a6bb8b7cfc` | 69,613,116字节，SHA256 `fe8b26460ad6dab3fdcd4649a2328325da4185bbcce216fe247e29ba5b3faf93` |

WASM39,514,754字节、SHA256 `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`，复用之前已校验的本地下载并重新计算实际SHA256/Git blob；`reusedPreviouslyVerifiedWasm=true`，不是两次重新从网络完整下载。PCK使用严格identity Range下载；两个Pages tree由实际远端API读取。第一次f872树读取连接失败未取得release.log或通过结果，重试独立成功。

Chrome154、DPR1、1280×720、实际AMD 8060S ANGLE D3D11无扩展独立上下文，只用普通鼠标/触控和浏览器减少动态效果偏好。IndexedDB只读、记录真实输入，未写时钟、种子、任务、库存或存档：

- 195：14个状态，自然第3趟落羽，拾取→自由走地→返院→HUD再次出门/返院→重开，最终落羽1件，页面错误0。
- f872：12个状态，自然第2趟落羽，同级完整流程，重开落羽1件，页面错误0。CDP实收PCK/保存及启动模块与本目录对应版本的实际下载逐字节一致。
- 每次首次及重开都核DOM构建标识。f872初次调用误写完整source参数，人工主动终止，未算通过；终止说明保留。成功重试完整source来自已经校验的JSON，两次输出分别保存，不覆盖失败记录。

这是桌面硬件的无扩展headless自动体验，不是实体手机、人耳听验或所有网络性能保证。录像为完整原速VP8屏幕记录，无音轨；文件fps不等于游戏fps。没有专门记录这两版cold/warm启动计时，不从状态截图时间推断下载速度。之前正式e9版的专门加载实测171.596秒cold/4.506秒warm在[加载证据](../2026-10-11-loading-integrity/README.md)，首次下载仍慢的限制不撤销。

64个原始仓库证据文件、41,559,474字节及其SHA256见`evidence-index.json`；另有索引、说明和属性。完整视频、全部JSON/网络/输入、五张关键原始PNG/轮次均原样保留，`.gitattributes * -text`避免日志/脚本换行被规范化。重复PNG与完整PCK/WASM保留在`D:\games\youjia-test\assistant-recovery`，80个相关本地文件、294,703,383字节列入`local-full-archive-manifest.json`。这两个索引含义不同；仓库不是整个本地下载的全集，不把本地总字节冒充已上传字节。
