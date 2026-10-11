# 近郊音景候选：实际 Web 信号、长时缓存与兼容自测试

CODEX-LEAD-ASSISTANT / #565。Leader 的 PR623 已有区域选曲和公共夜雨适配，但尚缺 Web 长时信号/缓存证据，且真实听验未完成。本报告补齐可在本机完成的软件自测试；**PR623 仍为 Draft，音景未正式合入或公开发布，近郊总目标未完成**。这是纯证据报告，没有改变玩家运行代码或他人的分支。

## 版本与恢复

私有组合的两方为 main `5d23acbec9d756fc5e3ddee678e2db478ff18935` 和 Leader PR623 `e00f11a88679e0efe2ee2dccb2a8eea9ae0a0169`。原 PR542 作者祖先保留。合并提交 `4ac427ddbce543c9836cd2813d1575db2be6bbb4` 仅保留新增声音适配，没有恢复当前主线已删除的旧装饰预览逻辑；六份冲突原文、逐项解决记录及两方父提交见 [merge-record](merge-record/combination.json)。

Godot 导入生成的 UID/import 元数据记录为 `5700377e248a4d871c9fb1711956dba1400d5e8f`。原生区域129/院内音频104/HUD72/拾物189日志打印4ac，在实际导入后运行；305场景/48容量和 Web 导出打印570。Web 导出又生成5个未跟踪元数据文件；148份 tracked 修改全部仅为 CRLF/LF，实际逐文件比对见 [原始导出状态](raw/export-generated-state.json)。导出后将这5个原件记录为 `06d8887a65ef04fd73066b340fefcfcb9a5f8422`，保留 [可恢复 bundle](raw/audio-combination-recoverable.bundle) 和 [验证记录](raw/bundle-verify-recoverable.log)。06d 是导出后的可恢复源码记录，不能冒称它重新导出或重新运行了测试。

bundle 需上述 main/PR623 两个已有提交作为 prerequisite，`git bundle verify` 已实际成功。取回这两个提交后可用 `git fetch <bundle路径> HEAD`、在独立副本检出06d恢复组合，不覆盖生产工作区。原570 bundle也保留。Godot 为4.7.2 stable；Web来自本机 release 导出，本地127.0.0.1:8797，正式公开版本不是这个候选。[package.json](raw/long/package.json) 留有浏览器实际收到的 PCK/WASM/JS/MJS 完整字节 SHA256，均与本地导出逐字节一致；重复 PCK/WASM未再提交，见[本地产物清单](local-export-manifest.json)。

测试期间主线新增 PR746 相册布局/焦点调整及 PR748 协作门禁文档，报告分支建立于 `b3eafa533b32bab45ba1c2988fefb96b978df395`。它们不在上述声音测试候选里；不能把旧基线组合结果写成新主线完整实测。

## 实际结果

| 实际运行 | 结果 | 原始证据 |
|---|---|---|
| 导入、区域音景、既有院内音频 | 导入退出0；129/0、104 PASS | [原生记录](raw/native-results.json)、对应log |
| HUD输入、直接拾物、完整场景、容量 | 72/0、189/0、305/305、48/0，退出0且无SCRIPT ERROR/ERROR | 同上，完成标记按仓库登记逐行核对 |
| Web release 导出 | 退出0，无SCRIPT ERROR/ERROR | [导出日志](raw/web-export.log) |
| 普通 Web 流程 | 27状态；正常出门/雨天/自然拾落羽/点地继续/返院/重进/自然入夜/第二天/刷新；落羽仍1件；pageerror/console error为空 | [summary](raw/long/summary.json)、[steps](raw/long/steps.json)、原图和真实输入 |
| 昼夜声音开关 | 两轮分别关音乐、关环境、全静音、恢复；有声阶段非零，两者关闭或总静音阶段为零；各12个窗口 | [汇总](raw/run-analysis.json)、各signal.json及PCM窗口 |
| 长时观测与缓存 | 约700秒循环观测，末次采样699.391秒、728次；6个解码缓冲、5个player、PCM189,235,208字节（180.47MiB）峰值，跨夜到次日未继续增加；观测峰值0.16552、无非有限值 | [完整采样](raw/long/long-samples.json) |
| 实际软件录音及独立解码 | 音乐/环境 context2 WebM/Opus797.76秒，48kHz立体声，RMS0.03508、peak0.32144，无非有限值或超过1的样本；刷新录音6.72秒非零 | [解码指标](raw/recording-software-analysis.json)、[长录音](raw/long/long-context-2.webm)、[刷新录音](raw/long/reload-context-2.webm) |

长期观察的夜晚实际Host为 rain、日内elapsed360.052秒；真实 AudioBufferSource 长度包括128秒院内曲/环境、76.80002秒近郊曲、64秒夜曲/夜环境、32秒雨声，loop=true。长度是实际 Web 节点属性，原生导入资源的另一次只读元数据见 [track-metadata](raw/track-metadata.json)，不能把原生旧白天资源import loop=false当作Web不循环（Web后端设置循环）。本轮没有调用入屋睡眠流程。

50个刷新前输入、2个刷新后输入均由正常鼠标/键盘操作产生，各阶段记录 `isTrusted=true`。Host只读，不注入天气、时钟、种子、道具、库存或存档；雨天通过真实HUD切换，夜晚靠原公共时钟自然推进。原生套件使用 GUID 独立测试存档，正常 Web 使用全新浏览器 profile。观测到JS heap峰值381,873,660字节（364.18MiB），只代表该 API 的 JavaScript heap，不是整个浏览器/WASM/GPU内存。

## 测量边界与失败原件

浏览器为本机 Chrome154，1280×720、hasTouch=true，AMD/D3D11。headless默认 `--mute-audio` 保留：本报告采集的是既有声音图的软件信号，不是扬声器或耳机实际发声/人耳听感。诊断器把已有destination连接并联到单声道4096样本 analyser及独立MediaRecorder流；原connect/start仍原样转发，没有创建游戏AudioContext或更改声音控制。单次PCM窗口约85毫秒，完整录音另外保存。[校准](metadata/nearby-audio-observer-calibration-oct11.json)用独立正弦/零增益验证非零与静音测量，不是游戏听验。技术依据：[W3C Web Audio AnalyserNode](https://www.w3.org/TR/webaudio-1.1/#AnalyserNode)。

797.76秒录音包含故意关闭声音的阶段，不能称“连续十分钟人耳听验”。Godot context1录音接近数值零，音乐/环境由实际BrowserBgm context2出信号，两路原件均保留。PCM、Opus解码、峰值或无报错都不能证明曲目悦耳、实际循环接缝/交叉淡化不可闻、环境比例合适。未覆盖实体手机、耳机/扬声器、后台切换、全部浏览器进程/GPU内存、全曲听感及正式公开新组合。

保留了实际失败：初次scratch稀疏初始化异常及只终止已核对身份的本轮merge进程；CRLF完成标记导致测试包装器误判，原129/0日志与初版包装器均保存；场景缺原仓库art夹具时虽打印295/295却有JSON/SCRIPT ERROR，明确记失败，恢复该HEAD原夹具后305/305；录音分析第一次因未安装Playwright配套浏览器启动失败，保留初版/日志，改用现有Chrome后完整解码通过。没有把这些失败抹成通过，没有修改游戏代码来迁就测量。

173份原始文件共77,172,897字节，来源、字节数与SHA256列于[evidence-index](evidence-index.json)；提交后另核实际Git blob与原始来源，不仅比较工作树。测试HTTP8797已核对CIM身份后停止；组合工作树、完整导出和原始文件保留。缺少的实际听感回执仍沿 #196 由QA/实际设备确认，Leader保留PR623音频Owner和正式合入/发布责任。

## 对近郊完整目标的影响

镜头比例/跟随、直接拾取/点地、容量与保存失败、局部动态/减少动态、边缘/返院、公共晴阴雨夜/局部光照的既有证据沿 [全目标验收表](../2026-10-11-nearby-input-release/completion-audit.md) 与原PR保留，不重复开发。本次新增的是候选音景的近郊自测，未改变该表“音景未正式完成”的结论。main近郊沿用院内声音状态，不是完全无声；真正剩余项是分场音乐/公共夜雨正式集成及实际听验。Leader623接口已有 `set_music_scene`/`set_world_sound`，不能重复另建Director、公共时钟或存档。
