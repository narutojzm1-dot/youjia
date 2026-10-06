# PR466 双音量滑条普通浏览器候选验收

Agent: CODEX-LEAD delegated `/root/hotspot36_qa`。本包为冻结候选的独立普通输入 QA，不是正式 Pages 发布证明。执行窗口为 **2026-10-06 00:48:00–00:51:55 UTC**；唯一浏览器、单 fresh context/page，执行后全部关闭，驱动实际退出码 **0**。完整时序见 `result.json`，退出与内存采样见 `execution.json`。

## 来源与方法

- 本地 URL：`http://127.0.0.1:8466/`，冻结导出目录 `/dev/shm/volume466-web-v1`。
- manifest：`game-release.json`，schema `youjia.candidate/v1`、candidateOnly=true、entry=`index`。
- sourceCommit：`146c3711537e4fa6657f1fd54e7472747cd0b10d`；sourceTree：`2e622f91345fc1a223982480339d86fa9ff94117`。
- 实际 HTTP PCK：27,093,724 bytes，SHA256 `df8b4807079717a3a51c273f09c617173aa6b50ce29b812e82d595cad62cd92a`。
- HTML：357,722 bytes，SHA256 `ccd7ab5bb40cdb85dca4b4caec1ac3888ff7e7c3bd6ba121feee199c8bd5e0a6`。
- 许可：147,966 bytes，SHA256 `9215f5fdd50039a9b6f3d8f0271cbc21bbdf64b917fb118dd29c8a16b9974e00`。

执行前后分别 HTTP 读取 manifest、HTML、完整 PCK、10 个 `web/save/*.mjs` 与许可并核定字节/哈希；两次均通过且 source 不变。导航实际 HTML body 另核哈希；实际加载的 JS/WASM/PCK/10模块响应 URL/status 共 13 条记录均为200。加载响应记录本身不包含 PCK body 哈希；完整 PCK 哈希来自同一冻结服务的前后实际下载，不能混称对每条浏览器 response body 都做了哈希。二进制不重复存进本证据包，清单与校验结果见 `result.json.bindings`。

Chromium headless、SwiftShader，实际 DPR=2；`no-preference` 媒体偏好，页面只读查询实际 reduce=false。完整设备像素原图保留：竖屏780×1688、横屏1136×640，无裁图、无重绘。启动参数含 `--renderer-process-limit=1`，见 `result.json.browser_args`。全程只有一个 context/page，390×844→568×320→390×844 是同实例重排。

只用真实鼠标点击/down/move/up和普通 Escape 开关暂停；未调用滑条 set_value、业务状态、存档、随机种子、时钟或音频增益 setter。驱动的只读 DB 辅助命令本次未调用。`youjia:first-frame` 监听与 DPR/media 查询只记录启动/环境。源文件与冻结导出未修改。实际 UI 操作自然更新游戏设置。

## 实际结果

| 项目 | 观察结果 | 原始证据 |
| --- | --- | --- |
| 普通标题→院子→暂停 | PASS：首屏正常入院，Escape 展示两条音量轨，初始均100% | `volume-title.png`、`portrait-01-pause-initial.png` |
| 两视口两轨分别点击0/40/100 | PASS：各自百分比可见变化；另一轨维持100% | `portrait-02-*`、`landscape-02-*`，共12张 |
| 两视口两轨分别按住拖动至0/40/100 | PASS：真实 down/move 期间显示目标百分比，另一轨不误改 | `portrait-03-*-held.png`、`landscape-03-*-held.png`，共12张 |
| 松手后把指针移到另一轨 | PASS：原轨停止随指针变化，另一轨数值不变；另轨 hover 外观可以变化 | 同名 `*-released.png`，共12张 |
| 同实例横→竖保存当前两轨不同值 | PASS：横屏设置音乐40%、环境0%，返回竖屏仍40%/0% | `landscape-04-distinct-values-before-return.png`、`portrait-04-reflow-back-retained.png` |
| 返回竖屏后仍能独立操作 | PASS：音乐改0后为0/0，再环境改100后为0/100 | `portrait-05-return-music-zero.png`、`portrait-06-return-ambience-hundred.png` |
| 暂停合上 | PASS：Escape 恢复院子，暂停面板不再显示 | `portrait-07-resumed-yard.png` |
| 浏览器异常 | `pageerrors=[]`，记录中无崩溃；控制台为引擎/渲染/加载信息 | `result.json` |

竖屏可见控件行中心 y=481/616，0/40/100 的普通输入 x=43/164.6/347；横屏 y=159/257，对应 x=302/392.4/528。坐标只是这两个实际布局的输入记录，不是跨设备通用保证。拖动保留按住帧，up 后把鼠标移到另一轨再截图。全部255条输入/环境/截图请求完成日志记录实际时间，未以固定内部值替代输入。

## 离线图像核查

原件44张全部保留。人工查看了首屏、若干0/40/100参考、held/released、横竖重排及恢复院子帧；没有声称每张都逐一人工审阅。另对42张暂停截图的两条百分比标签做原始 RGB 精确比较：每个视口/控件用该视口普通点击0/40/100的参考图作为基准，所有标签与各自预期一致，mismatches为空，见 `label-analysis.json`。

此比较是原图中的可见标签相等性，不是 OCR、内部控件值、实际音频增益或听觉证明。所用局部区域只在内存读取，未生成裁剪图片替换全图。原图包括完整屏幕，可审查文字、手柄、滑轨及布局；DPR2 实际尺寸可复核。

## 覆盖边界

- 本轮验证鼠标普通路径、可见百分比及同页面重排；未验证真实手机/触摸路由（#382）、DPR3、键盘焦点（#459）或英文/减弱动态。
- 无真人听验，不把百分比变化推断成实际增益、音频舒适度或播放完成。作者另行执行的原生267检查及其他专项/全量/Web导出证据由其自身日志负责，本包不把它们冒充浏览器体验。
- 未关页重开或刷新，故不声称跨会话设置持久化；未读取本次 DB，未声称完整存档验收。
- 未额外展开其他功能或再开第二浏览器；本轮无重试或坐标失败路径被删去。每张完整原图与全部输入均保留。
- 内存记录为离散采样；关闭后读数15,634,366,464 bytes，不是峰值监控。

`run.py` 是实际执行驱动，`predeclared-plan.md` 是执行前计划。`SHA256SUMS` 覆盖除自身以外全部原件和报告；冻结后交集成作者逐字节归档，不另推 PR、不改生产资源。
