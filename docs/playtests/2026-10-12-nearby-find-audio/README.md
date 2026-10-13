# 近郊获批拾物短音16：接入与实际软件验证

## 2026-10-13 当前主线组合与退出修复

本节为PR774后续增量，覆盖下文旧待验证状态，保留所有旧失败和准确版本。原94a头CI38268872009在动物发现92项完成后报告2个ObjectDB/1资源未退役，导出跳过：[完整失败原件](raw/merge-main-oct13/ci-38268872009-failed.log)。安全合并main `53d1b38a96260f0186f181167c5d6bca5201c168`，测试登记保留双方新增行，原作者祖先保持；仅再补六个实际拾物接入测试的播放释放/混音退役等待。当前运行与本机验证提交 `2272b045a2acbe051196e1aafbff3f3217f942c6`，FindReveal与获批WAV/import相对a31未改，完整CI待新PR头实际结果，尚未合入或发布音效。

[新增原件索引](raw/merge-main-oct13/index.json)为717份34,952,036B，逐字节复制并核SHA256；历史266份47,647,358B仍按自己的raw-index独立核对，未覆盖或把新内容混入旧索引。本次生成输入、驱动、失败/成功日志、图片、实际录音均保留。当前PCK实物在独立本地导出目录保留，85,610,264B / SHA256 `088af41a7544522774ce0723e0ddf2804ca883490ca3dc306330c42f9699c005`；[当前包与实际网络字节核对](raw/merge-main-oct13/validation/web/package.json)不冒作正式公开包。

- 原退出错误在合并提交1abfd6a的本机92项再次复现。修复提交2272的9套检查共1,953项完成且无SCRIPT ERROR/ERROR：动物发现92、狗狗46、乌龟40、点按反馈963、直接拾物189、完整探索300、短音96、名字纸签210、名字淡出17；保持全部断言和错误门禁。首轮完整探索因本地稀疏检出缺旧原画锚点JSON而只走290并报ERROR，保留失败；从同一Git提交恢复原测试文件后300项重新通过，未删断言或改生产逻辑。
- 新组合普通Web仍覆盖16状态、6次自然取物、5个0.95秒非循环source及1次静音跳过；重复点地不新播、继续走动、暂停/恢复、静音/解除、返院/重进/刷新保留落羽4/圆石2，0页面/控制台错误。新截图/录音仅属于2272组合，不冒用旧a31版本。
- 新主线院内在拾物之前已有3 buffers/3 players、99,302,400B；旧驱动写死2，首次在尚未出现短音source时判失败，原件留在web-first-cache-baseline-drift。改为读取本轮院内真实基线并核返院后缓存/播放器/字节不超过基线，不改变游戏状态。短音期间最多4/4，返院回到3/3。隔离拾物最大RMS0.02463393、peak0.05008454，静音/暂停/返院及解除不补播窗口均0，无非有限样本。
- [当前实际录音独立解码](raw/merge-main-oct13/validation/recording-software-analysis.json)：共用context2普通录音75.6秒、539,246B，SHA256 `4938fb429cf3bf29107dd2e82fc5f002c1ab3ea1943cdef347732be50100b4c7`，RMS0.03524335、peak0.30984161，无非有限/越界样本。包含初始院内音乐和主动静音，不把整体peak称为隔离短音峰值或耳机听验。

第一次归档统计对标题阶段backend=null未处理而失败，原驱动也保留；续做仅忽略尚未初始化的诊断项，已复制原件逐字节复核后继续，未改游戏/测试结果。原生生成元数据按实际status备份并只清理已确认的本轮import/UID，不覆盖其他工作；8798新服务核精确PID/命令后停止，旧演示服务保持。真正失焦/后台、锁屏、实体设备及感知混音仍未验；另标签页未收到事件的旧限制继续有效，623正式区域声音不在本片范围。

Agent-ID: CODEX-LEAD-ASSISTANT。来源#565及PR359接收6125018905；本片消费已有成功拾物/公共音频接口，不新建Host/库存/时钟，不接管623或738。原始文件索引 [raw-index.json](raw-index.json)：266份原件47,647,358B，包含失败、最终日志、实际录音、捕获图、驱动和生成元数据；PCK/WASM不重复上传，只保留准确哈希及实际网络字节核对。

## 版本与素材

- 基线main `c874273bc16f6b99e43da49de8907008f52d44d9`；声音运行实现 `a31b540d6292935debfe0d72b84f4fba68911db5`，第一组本地原生与普通Web实际绑定此提交。后续7eec报告头只增排除文档；CI发现旧视觉测试退出资源未退役后，仅修两份测试的退出等待，生产代码/音频未再变。修订原生210/17/96/300/189/48/72实际基于7eec＋[两份工作树测试补丁](raw/ci-lifecycle-repair/ci-lifecycle-test-repair.patch)，不冒充新PR头另跑Web，最终完整CI单独绑定新头。
- 用户2026-10-12批准听验16；原GAME-PRODUCER359 `0e07ef5eabcd5766726d1c9d95904b1ad8ef54e3` 的 `discovery_soft.wav`，91,244B / SHA256 `14d19c82019fe48ee7fa9b2d843e8bfc69fe155c59ef736e255ac40e8975aea3`，原字节映射到 `assets/holiday/audio/exploration_find_get.wav`，不重新合成/转OGG/改电平。原作者/生成器及获批回执保留。
- 48kHz/mono/PCM16、45,600帧/0.95秒、不循环，不归一化/裁剪/压缩。原生导入PCM SHA256 `936184f59a29c5d519f1d1ca831916e8fef997e373778a15a50f26adb90e443e` 与获批WAV数据相同。
- 实际候选PCK 74,551,948B / SHA256 `e402cc5f3a83273e8af88476ad0f9e44d072d7699666a84c31116b64d5566e9a`；WASM 39,514,754B / `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。网页实际响应逐字节比本机导出，见 [package](raw/web/package.json)。不是正式发布证明。
- Godot4.7.2自动修正5份已有贴图import的UID/缓存路径并生成162份其他UID，原件/索引在 [生成元数据](raw/generated-metadata.json)；清理时另发现两份已有棚内姿态的自动import，[原始描述符及未变源图哈希](raw/export-metadata-extra/index.json)补存。它们属于实际本机导入输入，不冒作本片生产改动；新WAV自己的不压缩import及新测试UID在实现提交中。

## 原生与Web导出

最终 [native-results](raw/native-results.json) 全部退出0、精确完成标记且无SCRIPT ERROR/ERROR：短音96、完整探索300、直接拾物189、实际磁盘容量48、HUD输入72；Web release导出退出0。各套使用独立GUID用户目录，不动玩家原档。原生96覆盖原文件/导入PCM、成功take/swap、满篮/重复地面拾取/释放/返回后拒绝、实际内存存储拒绝、暂停/失焦/应用暂停通知、静音/SFX零输出及解除后不补播、减少动态、缺件安静降级。通知调用是受控原生测试，不当物理设备后台体验。旧探索日志中的“sound audible”仅指播放器状态，不是人耳听验。

## 普通网页实际流程

Chrome154.0.8037.98、实际AMD/D3D11 WebGL2、本机127.0.0.1:8798、新隔离浏览器上下文，1280×720鼠标及390×844触控模拟。普通可信输入；只读Host `current.payload_bytes`，未写玩家存档、时钟、种子或游戏状态。诊断只在现有音频连接上并联 analyser/MediaRecorder并原样转发connect/start，未创建游戏AudioContext或改声音设置。

[16状态](raw/web/steps.json)、[声音窗口](raw/web/signal-windows.json)、[分析](raw/web-analysis.json)：

- 6次真实直接拾物返院；静音的一次不创建短音source，其余5次各一个0.95秒非循环source。重复点地没有第二个声音，点地继续正常。自然获得落羽4、圆石2，刷新标题再进院仍各4/2，0page/console error。
- 音乐/环境通过真实暂停面板关闭后，基线软件信号为0。鼠标和触控拾物窗口最大RMS 0.02374447、peak 0.05008454、无非有限样本；静音/解除不补播、暂停停止/恢复、返院停止窗口均0。
- 每次返院后新短音缓存与播放器释放，恢复为原2 buffers/2 players；受测过程中最多3/3。没有把相机尺寸当实体手机。
- “另开标签页”探针没有收到blur/visibilitychange，短音当时仍可自然播放；只证明没有额外start，**不计失焦/后台停止通过**。实际应用通知仅有上述受控原生测试，真正后台/锁屏/手机未验。
- 原样保存实际WebM：Godot context1近零，项目共用播放器context2的普通录音51.78秒/613,059B，SHA256 `a23d06e9971a318ee705f56885c5e8d01e08bc36342ccfa09fee47b8f955fb28`；独立Chrome解码RMS0.04841837、peak0.32132018，无非有限/超1样本。录音含初始院内音乐及主动静音，不把整体peak误写为隔离短音peak，也不称连续10分钟听验。刷新录音和独立解码原件同目录。

## 真实失败与修正

1. 首次全局类提前编译找不到TuningStore，完整日志保留 [compile failure](raw/first-global-class-compile-failure.log)，不是“checks=1 failures=0通过”。改为运行时取已存在的autoload节点。失败源文件未另存快照，未伪造重建。
2. 一次原生结束虽96项完成却资源未退役报ERROR，保留 [shutdown failure](raw/first-shutdown-resource-failure.log)。测试在退出前给AudioServer混音退役时间，后续最终检查无该错误，不靠忽略ERROR放行。
3. 第一网页驱动把动态HUD“看花箱”当出门，超时原件在 `raw/web-first-entry-failure/`；改走可见石板小路。首轮包装器后置Get-Content造成命令exit0，Python traceback仍按失败处理；后续保留Python真实退出码及完成标记。
4. `b7a2bfd1c3beae914470ce435ed54c746c7658a5` 的原AudioStreamPlayer Web sample路径：确有一个0.95秒source、原音非零峰值0.07937864，但所有目的端监测窗口为0。两轮零信号和完整连接/增益原件分别保留 `web-first-zero-signal` / `web-sample-routing-diagnostic`。没有把play调用当声音通过，也未改引擎或共享AudioDirector。近郊侧复用已经发版的BrowserBgmPlayer后，获批原PCM和SFX混音保持，最终软件信号/次数/停止/缓存通过；复杂原生Web总线路由未另做根因修复结论。
5. [完整CI38260359242原始失败](raw/ci-lifecycle-repair/ci-38260359242-failed.log)在旧find_reveal_name_slip_suite的210项通过后报告5个ObjectDB/1资源未退役，Web导出skipped，未算完整CI通过。名字纸签及淡出测试退出前加入混音退役等待；[修订本机原生](raw/ci-lifecycle-repair/native-results.json)210/17/96/300/189/48/72退出0且无ERROR，不删断言、不放宽门禁。修订完整CI另核，不沿用失败run或旧头结果。

再次运行验证时4份可变本地日志/驱动原件已被新执行覆盖；旧原件从先前逐字节验证并已上传的7eec Git blob精确恢复到独立归档，索引注明来源，不重新编造。a31本机PCK也被后续导出覆盖，旧实际网络字节相等及SHA证据仍在；新的7eec导出不标成a31原件，未恢复的旧PCK实物如实列出。[修订版本及保留范围](raw/ci-lifecycle-repair/context.json)。获批原WAV、实际录音和图片仍完整保留。

## 边界与下一步

本轮软件信号/录音/正常UI不代耳机/扬声器混音听感、实体iOS/Android、真正后台/锁屏或完整游戏声音验收。16源素材已获批，公共02/03/05/06/07与17路由、当前组合听验及日发布仍由Leader/QA接续；PR752旧700秒/缓存证据保留其main5d＋e00f范围。本片不将当前候选冒称正式公开，#565总目标不因16完成结项。8798已核实本轮PID71216精确命令后停止，用户仍使用的旧演示服务未动。
