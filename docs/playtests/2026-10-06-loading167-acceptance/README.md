# #167 同一正式构建的三尺寸加载与真实重试验收

执行身份：CODEX-LEAD 委派 QA 支援 `gate130_completion`；原实现 Owner **CODEX-LEAD-ASSISTANT** 与专业角色 GAME-QA 保留，不冒 GAME-QA 本人或新的 Assistant 实现回执。按 [6005985387 协助认领](https://github.com/narutojzm1-dot/youjia/issues/167#issuecomment-6005985387) 只补原加载专项，未修改运行代码、资源、分支实现或游戏状态。

**本次六个样本满足 #167 原加载范围的浏览器尺寸验收，待最终文档 SHA 独立审核；本 PR 不提前关闭 issue。** 小院加载壳、标题/字节进度/错误/重试在桌面、390竖屏、844窄横均可读；真实错误后普通 DOM 重试恢复首帧，再以鼠标从标题入院。normal/reduce 各三尺寸完整执行。原作者 184/185、ART 旧认可、341与GAME-QA370的既有成果不重认领，不把完整游戏、真实听验或未知手机性能追加成加载视觉缺陷的永久门槛。

## 被测版本和执行条件

- 全部实际公网：`https://narutojzm1-dot.github.io/youjia/`，`game-49596fa`，source **`49596fa93bff3c29edfe441898017158c6e469a3`**，storage entry `save-49596fa`。六例共 **12 次前后独立 HTTP 完整 PCK 下载**均为 **27,090,652 bytes** / SHA256 **`c851ac2b66ef6bba5211b7ba8488173c6b6a336ee7508d6150a5f5ccd488f930`**。
- 此文档基线 main **`b9f68c3c5c4e70e16cefde9b4400bb1d553ff915`** 已包含后续 camera465；**文档 main 不冒被测构建**。本档实测 source 始终 49596，不把这次加载验收转记 camera465或未来发布已通过。
- Linux Chromium **151.0.7922.173**，headless SwiftShader，`renderer-process-limit=1`。一个 browser，六个 fresh context/page 串行，每个确认关闭后才开下一个；DPR1、1280×720 / 390×844 / 844×390。
- `no-preference` / `reduce` 由创建 context 时的浏览器 OS 媒体偏好设置，并实际读取 `matchMedia` 核对；没有内部 TuningStore 注入。生产的 `MotionPreference` 沿既有系统偏好接口消费；本轮只读媒体值和可见结果，不宣称测过全部游戏低动效。
- Fresh context、`service_workers='block'`、CDP `Network.setCacheDisabled=true`、真实请求路由；已记录的资源响应 cache flags 全 false。CDN/代理可能仍有缓存，故这是浏览器缓存清空样本，不是源站绝对冷缓存或自然性能基准。
- 唯一 corrected browser 实际 2026-10-06 **00:07:17–00:14:06 UTC**，外层 session81590 **exit0**，六 context 均关闭；原始结果在 [result.json](six-case-matrix/result.json)，[执行退出与内存采样](six-case-matrix/execution.json)。内存值是离散样本，不能称连续峰值。没有启动 Godot 或额外浏览器。

## 每例的真实操作链与结果

每例先实取公开来源；首次 engine-JS 网络请求暂 hold，拍初始加载原图，再只 **abort 一次真实请求**。页面自己的错误逻辑显示失败与重试；实际点击 `#loading-retry` 发生 reload。恢复导航首次真实 WASM 请求至少 hold4秒，保两张加载帧后放行；等真实 `youjia:first-frame` 和 `loading.hidden`，拍标题，再按标题实际位置普通鼠标入院并保两帧。所有 hold 与截图开始/完成的 UTC/单调时钟均在原件，未注入假 DOM 错误、首帧、随机数、日序、存档或玩法状态。

| Case / 浏览器媒体偏好 | 前绑定 UTC → context 关闭 UTC | WASM 实际受控延迟 | 结果 |
| --- | --- | --- | --- |
| 1280×720 no-preference | 00:07:43 → 00:08:26 | 4.004550 秒 | 加载、失败、DOM重试、首帧、标题、普通入院通过 |
| 390×844 no-preference | 00:08:40 → 00:09:30 | 4.008537 秒 | 同上 |
| 844×390 no-preference | 00:09:43 → 00:10:33 | 4.009901 秒 | 同上 |
| 1280×720 reduce | 00:10:46 → 00:11:41 | 4.020567 秒 | 同上；媒体值实际true |
| 390×844 reduce | 00:11:55 → 00:12:59 | 4.011711 秒 | 同上；媒体值实际true |
| 844×390 reduce | 00:13:16 → 00:14:06 | 4.016850 秒 | 同上；媒体值实际true |

每例七张 **原始 PNG**，共 **42张**，没有裁切、重绘或拼图替换：`01-loading-initial`、`02-network-failure`、`03/04-retry-loading-a/b`、`05-retry-title`、`06-yard-entered`、`07-yard-stable`。[机器汇总](six-case-matrix/summary.json)列每例原始来源、实际延迟、错误、关闭及CSS采样。实际驱动 [run.py](six-case-matrix/run.py)保留，采用交互指令让实施者先看标题后按普通位置入院；点击记录在事件数组，未调用游戏私有方法。

执行者亲看各例失败、恢复加载、标题和院内稳定原图，并查看 reduce 的两加载帧。桌面小院画与暖纸下方信息层清楚；竖屏院景上方、文字/重试居中留白完整；窄横小院在左、信息在右，错误详情与按钮都在画面内。只读 DOM 几何对24张加载/失败采样未见越出视口或文本横溢；动效的 author CSS 与伪元素采样 `transform/animationName=none`、duration=0s。独立助手 `leader_scope_audit` 另实际查看21张原图并复核六例A/B图像差异仅落在数字/进度区域，背景ROI相同，见 [独立只读原件复核](independent-raw-verification.json)。这些是采样与源码/CSS检查，**不冒所有动画帧、浏览器内建进度动画或真机视觉保证**。

DOM采样在截图完成后执行，实时下载进度会继续变化，例如 desktop-normal04 原图约0.6MiB/0%，其后DOM约1.7MiB/2%；landscape-normal04原图4.3MiB/6%，其后DOM4.8MiB/7%。这是真实取证时间差；不得把DOM数字冒同帧像素值或将配置等待当引擎精确时钟。页面的 **63.5MiB** 明示解压后资源总量，与PCK文件字节数、压缩下载及CDP传输计数分列。

## 来源、错误及取证边界

每例前后均实际 HTTP 读取 manifest、HTML、完整 PCK、十个存档模块和许可页。HTML哈希在整个矩阵一致，实际导航与重试返回的HTML也与绑定相同；`data-build` 实际为 game-49596fa。许可页字节147,966 / SHA256 `9215f5fdd50039a9b6f3d8f0271cbc21bbdf64b917fb118dd29c8a16b9974e00`；只单独HTTP验证，没有声称点击许可UI。

恢复导航中十模块的实际浏览器 response body 逐 SHA256 匹配 manifest；**PCK 的完整字节哈希来自独立前后 HTTP 下载，不是 DevTools response.body**。浏览器实际 PCK 的 URL、HTTP200、cache flags、CDP `encodedDataLength` 另记录，六例PCK encodedDataLength约26.676MB，不与已解码PCK27,090,652B或页面63.5MiB混称。JS/WASM实际loaded200另记。编码传输计数是浏览器协议观测，不是物理线路总传输量。

每例恰有一个预先声明的 engine-JS `net::ERR_FAILED`，及两个对应 console error：浏览器“Failed to load resource: net::ERR_FAILED”和产品“Startup failed Error: Engine script could not be loaded”。逐条URL、导航阶段和白名单留在 result；**pageerror为空，额外console error/failed request不被忽略**。首导航/失败/实际DOM重试过渡期的旧模块body明确标 `Excluded`，避免reload后陈旧资源ID；这与恢复导航十模块已实核分开。模拟故障不是自然生产报错。

## 首次取证失败原件保留

[First attempt](first-attempt/result.json) 实际一个桌面context走到加载→JS故障→DOM重试→首帧/标题→普通院内原图，但收尾时两类 DevTools 取证错误使 outer session57647 **exit1**：旧导航 `host.mjs` 响应ID在reload后不可取，以及大PCK正文被inspector cache逐出。browser于 **00:05:58 UTC** 关闭，没有执行第二case，也未完成该case的后绑定；**不将首次运行改写PASS**。其七原图、完整driver/error、[退出记录](first-attempt/execution.json)全部保留。

随后仅一次有界修正采集器：旧导航模块正文明确不作为可用哈希；恢复模块仍实读，PCK通过前后独立HTTP全哈希与浏览器实际loaded记录绑定。不得声称被删掉的取证项已成功。修正和两个脚本哈希在 [collector-correction.json](collector-correction.json)；六例是新的fresh contexts，不把初次七图拼入成功矩阵。没有改产品代码，也没有继续无限重试。

## 原验收映射与剩余边界

| #167 原范围 | 本轮实际证据 |
| --- | --- |
| 小院风格与桌面/横屏/390竖屏可读 | 三尺寸×两偏好原PNG，保留已批准母版；加载、状态、字节进度、构建号、错误与重试完整可见 |
| 失败/重试、标题和院子可操作 | 每例一次真实JS请求abort、DOM重试reload、真实首帧后壳隐去、普通鼠标入院 |
| 低动效不新增缩放/闪烁 | 浏览器reduce真实媒体路径，窄屏含完整操作链；两帧、只读CSS及独立ROI检查，无新缩放/闪烁迹象；未作全帧证明 |
| 真实构建/浏览器/资源字节 | 固定49596，Chromium版本、12次前后公开PCK全哈希、实际请求、十模块/许可、正确区分解压量与CDP编码量 |
| 实现与必要回归/发布历史 | 184/185已交，341与370既有证据保留；本轮无代码，不重复Godot/导出或调度发布；本证据PR仍须最终SHA独立审核 |

185历史受控PCK故障/真实重试已通过，本轮没有重做它；341曾有一次PCK abort未得到失败按钮，不否定185。本轮选可终结的JS故障，因此不冒PCK故障路径重验。370本人已有桌面003视觉通过，不再写“GAME-QA完全未看过”，其53秒加载停滞/重试工具超时也不改写成自然故障已证。

未覆盖手机真机、其他浏览器/系统/DPR、自然慢网性能、音频听验、全部存档/后台恢复、全游戏低动效或所有关卡；这些限制准确保留，不外推样本覆盖，也不任意新增成 #167 原视觉缺陷门槛。本次只是加载专项，其他 #400 构图/#51天气/#382输入保持各自Owner。原范围可提交最终独审后由Leader核定收口；此时不提前关闭issue或宣称本证据文档已合入/已发布。

[执行前计划](plan.md)、[来源与角色](source.json)、[预检公开manifest](public-manifest-preflight.json)、两阶段各自SHA256SUMS与本目录总SHA256SUMS共同保留。原HTTP HTML的末尾空行也保持字节，不能为去除diff空白警告改写原证据。
