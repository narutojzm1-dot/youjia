# 近郊输入修复的实际公开核验与长冷启动记录

CODEX-LEAD-ASSISTANT，2026-10-11。本次只归档实际证据和更正事实；未修改加载器、纹理、音频、存档或游戏运行代码。#565总目标仍未完成，完整范围见[逐项核对](completion-audit.md)。

## 被测公开集合

| source | Publish / Pages | 实际Pages commit | PCK bytes / SHA256 |
|---|---|---|---|
| `3caeb1fe6082da0cf0db00e3bea20dc47eb50edf`（含PR737输入和Leader731保存扩展） | 38108960020 / 38110504456，均success | `0e0d30c8391e9aa118b947d00e91f97ac1fd0191` | 69,625,924 / `dd14a0ee9777f2b1466c20e54602c0007b52e8e6aa902e4d60ba13ffb01c8a9c` |
| `c28246f14dd8bca837624699ca9447124e39d0d1`（另含Cloud PR741按钮折行） | 38112894768 / 38113778036，均success | `2d1ba9915152aa437e72613ceeec44c82dadb2b5` | 69,626,676 / `f6159b930d7a6230c0f42f6b4687d8b3b23ed4b752a2845734a4fd723a170281` |

两集合各17个真实公开运行文件通过完整SHA256与对应Pages Git blob检查，见[3ca](release-3ca/verified.json)和[c282](release-current/verified.json)。稳定WASM原件39,514,754B，SHA256 `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`，复用本地先前已下载原件后重新哈希；本次资源核验不冒称重新完整下载WASM。浏览器冷启动则真实请求了WASM/PCK。大二进制原件留在本地，哈希/目录索引上传。

c282发布完整检查含HUD72、动物发现92、直接拾物189、动态44、雾34、窗29、容量48，均零失败；完整发布日志在[metadata](metadata/nearby-c282-publish-success.log)。本次没有另跑本机原生套件，不把发布CI或旧头测试冒作新本机执行。

## 普通HTTPS体验

无扩展Chrome154 / AMD8060S ANGLE D3D11 / DPR1，原始Godot包；没有注入玩家种子、时间、天气或库存。只读Host载荷观察、普通输入及正常天气按钮，所有实际接收PCK/MJS字节与核验快照一致。启动/刷新前后都检查HTML build，防止发布竞态混用版本。

| 实际视口 | 完成状态数 | 自然物品与刷新后数量 | 原始来源 |
|---|---:|---|---|
| 390×844 | 11 | 圆石1件 | [events](browser-initial/390/events.json) |
| 844×390 | 21 | 第6趟落羽1件 | [events](browser-initial/844/events.json) |
| 1280×720 | 15 | 第3趟落羽1件 | [events](browser-desktop-observed/1280/events.json) |

合计47状态是**两次实际运行的结果汇总**，并非初次三视口驱动全程成功。均覆盖直接点物、点地继续、返院、HUD再进出和真实刷新后进入小院，0page/console错误；桌面天气HUD后133.2ms的下一次世界点击生效，Touch天气一次切换。原始输入、只读载荷、包校验、截图和无声视频保留。[汇总](summary-combined.json)。rAF普通/减少动态样本和实际GPU记录随各视口保存；模拟手机尺寸不等于实体手机测试，视频帧率不当作游戏帧率。

## 冷启动确实仍慢

同一桌面观察运行始终保留原页面，600秒只是**测试观察预算**，没有修改生产超时、隐藏加载页或绕过firstFrame。页面继续收资源后终于正常启动，完成普通近郊链及刷新。完整[CDP轨迹](browser-desktop-observed/1280/loading-network.json)、[复算结果](metadata/input-public-network-analysis-oct11.json)及[复算脚本](scripts/analyze-input-public-network-oct11.py)均保留。

- 冷启动壳内firstFrame **565.131秒**，完整缓存warm **5.191秒**；实际刷新观察耗时5.577秒。计时不是navigationStart到可操作小院；不能称首次加载问题已解决。
- WASM：HTTP200 / gzip，39,514,754B decoded、10,248,949B encoded，原生请求至完成139.942秒。
- PCK：HTTP200 / gzip，69,626,676B decoded、69,089,253B encoded，请求至完成551.664秒，响应体阶段541.972秒，平均约0.122MiB/s。两项编码后body合计约75.663MiB；加载页104.1MiB为解压后口径。
- 本次连续有资源进度，0Network.loadingFailed、0Range请求、0页面/控制台错误；闲置恢复没有触发。长耗时主要落在大响应交付阶段，尚未区分上游、CDN、代理或网络的具体因果。
- 浏览器驱动用了`--disable-http2`，实际协议HTTP/1.1，并经本机代理；明确记录条件，不代表用户浏览器线路，也不是严格A/B。历史e9的171.596/4.506秒、f872的45.247/2.303秒仍各自有效，不用不同时间/网络单次数据证明优化倍数。

用户截图的`Unchecked runtime.lastError`属于扩展Runtime API错误形态（[Chrome官方说明](https://developer.chrome.com/docs/extensions/reference/api/runtime#property-lastError)）；没有证据指向具体扩展。无扩展也出现长冷启动，所以它不是必要条件。将新样本送到已有性能#740；不重开已经完成续传可靠性修复的#606，也不重复实施工程督导所列实验或抢占资源/引擎Owner。

实际已核PCK的[只读挂包盘点](pck-budget/result.json)包含630个虚拟条目，未实例化生产项目/autoload，不等于目录MD5校验。最大几项为村落、近郊、小院底图和对象纹理；字体已是约1.877MB子集，不能推断字体未裁剪。未删除旧照片动态依赖、缩图、改导出清单或宣称已减包。

## 失败、缺件与音频更正

- 初始预期3ca的普通测试遇到站点升级c282，快照旧目录无对应模块而失败；不算游戏启动报错。保存了原视频，未捕获的stdout/stderr文件不重建，见[curation](curation.json)。
- 初次c282三视口驱动在桌面实际拾物/返院后，默认30秒reload等待`load`超时；初次整体运行失败，没有补写summary。之后独立桌面冷启动180秒观测超时，截图仍77%/80.3MiB且0错误；原日志和图都保留。最终同页延长观察至实际首帧完成，不能把延长测试预算称为性能修复。
- 观察驱动stdout的中文经原生代码页/PowerShell管道出现乱码；原日志未改。JSON由Python直接写UTF8，保留实际文本。最终完成标记与summary有原件，终端退出码未保留，不补写exit0。
- 先前#565评论6105175212所称“进入探索false”不准确：Main的`set_yard_active(false)`在`_show_title`，探索进入不清此flag。因此近郊沿用院内AudioDirector状态，不能断言完全无声。主线缺的是正式分场音乐/夜雨音景；Leader623 `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169`已有API和Main适配，但仍Draft待真实听验，542同样未合入。不复制公共接线，无声录像/PCM不冒真实听感。

[evidence-index](evidence-index.json)列出160个原始文件、164,870,323B及原路径/完整SHA256，二进制未经重编码；[local-full-archive-manifest](local-full-archive-manifest.json)另记本地保留PCK/WASM。策划总范围、现行Main输入和Leader/Cloud/Grok职责保持。本次归档仅证明c282的上述实际范围，不证明后来45f9976b的断行数据发布或23:00日版本完成。
