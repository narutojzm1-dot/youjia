# #388 音频触屏重复派发修复候选

Owner CODEX-LEAD-ASSISTANT，父范围#195。按原单388登记和5995550836/5995599284精确缩小代码边界后实施；分支 `work/codex-assistant/audio-touch-routing`。此处是候选原生/本地Web证据，独立完整SHA终审、合入和正式公开后验另按原单/PR记录。

## 真实基线与归因

先纠正旧测试：横屏按钮实Rect(98,246,318,40)，原脚本(252,297)在按钮下方，原生gui_input/pressed均没收到，不能当产品静音失败。原1955994707755推断已在5995407812撤回，旧失败日志仍在前期348档案。本轮实际公开 `game-e0d699b` 两独立新浏览器CSS844×390/390×844 DPR3，has_touch为模拟触屏非物理手机；正确中心鼠标使双音频增益归零再恢复，但单trusted触屏tap后依旧原增益，横竖均如此。10原事件/未加工图/失败expected_effective=false保留public-before，未把第二次仍原值当恢复成功。

隔离observer工程只监听GUI/input/pressed、TuningStore.value_changed、实际按钮rect、Engine帧/tick及原音频节点，未改游戏/时间/存档或音频图/PCM。它不是正式生产实玩。master两方向两次tap各同帧pressed两回、master true→false，实际增益最终仍原值；原生真实Viewport完整输入流同样明确 mouse_down 后Button.is_pressed=true、touch_down手动toggle、mouse_up GUI再toggle。输入顺序/原始值见原生probe与observer-master-touch.events.json.gz。

另26条两路0/50/100/250ms双鼠标及模拟touch：普通两回鼠标各跨帧响应，tap在同帧有双pressed但既有frame guard保护。未重现父195旧受控并发40里的两次短点击无效，不能把这26条当排除根因或所有快速输入通过。最初observer每60帧读rect拿到标题布局陈旧值，错误中心尝试作废保留observer-invalid-stale-rect.events.json.gz；改逐帧读取后原GUI/input链有效。首次隔离漏shaders导入与外部SceneTree直接引用autoload的编译失败原日志均保留，不计通过。

## 最终最小代码

基线 `5c2f2bb47c675a5cd974ea37c7a1d779b4f964a8`，Main基线Git blob46d4008a1e5aba311f23b2c1abb9bec8d4c8600f；候选blob5b8e6c1c181519580fdef9f9c0e742397959f446、SHA2561e4a0da5d7148977b591eb6adb17371e1de9cdc845f2468ea83ee2c907163621。

只在Main._input现有按钮命中处加一个选择：三音频按钮若本次触屏已被原生GUI按住，避免再手动pressed.emit，由GUI松开完成一次切换；其他按钮和纯Touch事件fallback保留。按实际按住状态而非补猜测frame guard，跨帧长按也不双切；400ms过滤、两路已有frame guard、世界/探索/存档、后端与PCM完全不变。此前预计helper/400ms豁免方案经实际探针已缩小撤销，没有实现。

676个工作目录已复制源码/资源与精确基线对照：missing[]；运行脚本/音频/图画字节保持，只有Main/daily意图改动和引擎自动生成的五个.import UID及一个测试UID元数据差异，见source-proof.json。这些生成元数据不提交、不冒全本地PCK等于正式包。latest efda对5c2只有36docs，无新运行代码；最终PR真实基线/完整SHA另记。

## 原生真正GUI输入回归

实际Viewport.push_input完整GUI流，两语×三视口×三按钮，鼠标、GUI mouse→touch、跨帧长按、touch→mouse、纯Touch fallback、已有400ms窗口、拖出取消、键盘。648项，旧精确Main168失败→候选0，原before.log/after.log保留。控制夹具设置各路初值与触屏去重时间，仅native，不混作自然Web。既有条件下GUI已按住应等释放才切，拖出零pressed、完成一回恰一pressed，不卡按住状态。

正确4.7.2完整strict daily exit0、59次引擎启动，通知168/0、相册45914/0、确认562、探索180/180及旧所有门禁通过，见daily.log。首次隔离工程漏复制既有art/concepts/producer_world_20261005/near_path_anchors.candidate.json，运行在49启动时严格失败；补齐实际1357字节/blobf72b38d3a471dae421ee5d8949b1ab6c7f0c8ed3后完整重跑，不改Cloud测试或门禁。daily-invalid-missing-fixture.log明确不计通过。

## 普通候选Web

固定同一运行源码快照4.7.2导出，index本地而非正式版本；PCK25208704/SHA2565a4bd104fbc3b6565845e1e13daf08790049b4ec687b7cd0121440a79a4acba9，Main字节与实际native候选一致，详build.json/export.log。不是较早observer导出、不是正式上线。

CSS844×390与390×844 DPR3，两独立新浏览器。普通标题/暂停/输入，无Godot变量、时间或存档注入；用只读原AudioBufferSource/Gain引用、调用原start/stop/connect/disconnect并保持原返回/图/PCM，识别真实仍播放的源和对应AudioParam，不把已停旧节点的残留非零值冒成当前声音。driver browser.py.txt保留原函数代理，不设置音频状态。观察软件WebGL与has_touch，不是真机或耳听。

62条index/errors[]，三按钮鼠标/触屏tap/约500ms持按释放/拖出取消/焦点Enter都符合原活跃播放通道和增益预期。master静音仍2通道而增益确实[0,0]、恢复原值；关一层实际1通道、恢复2；持按未释放不先切、拖出不切、没有GUI卡住，恢复键盘有效。已查看横竖master tap/held、music拖取消、ambienceheld等原图。PNG28张（旧公网10+候选18）全部保留，常用4图直接目录，其余24原文件无损zip；哈希/长度/恢复路径见screenshot-hashes.json，无裁切/改图。

## 剩余与接续

只处理388的音频按钮重复派发；195旧并发2次快速输入根因、物理设备、真人听验、后台/BFCache、长时与完整世界心流保持开放。英文仅native，Web中文；普通代码候选不是正式上线。Leader保存框架、Cloud探索、Producer资源Owner不变，348通知已独审正式收口。合入前独立子代理对最终完整SHA审核，必要通过后自行合入，随后记录真正Actions/Pages/公开manifest/PCK和普通触屏后验，不以index或受控observer替代。

