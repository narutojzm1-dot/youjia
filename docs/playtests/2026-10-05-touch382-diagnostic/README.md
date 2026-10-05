# BUG #382 只读诊断：确认取消改音乐音量 / 继续后半暂停

执行者 horse180_repro。2026-10-05。未修改生产文件、未认领修复、未重新跑公网多 profile。原公开事实见 [PR386已归档触摸证据](../2026-10-05-touch-modal-input/README.md)（[PR386](https://github.com/narutojzm1-dot/youjia/pull/386)）（旧公开 d707113 已发生，不能归因 #373）。本次是隔离原生诊断，不伪称普通玩家端到端验收。

## 精确版本

诊断执行时读取 origin/main `54750999339f4f5941d844dab53a542dd63a5160`。实际运行复用正式无 observer 候选 `/workspace/sheep-attention-export/index.pck`，source `098e611233e20f8a5eccb47afc43a6341f09dedb`、PCK SHA256 `c72c05a4bce738d92d4e23d6b6ce99a2e2a1b1f5442b2467f995da8e0540e821`。没有复制大包。

`_input / _drag_volume_slider / _point_sets_slider / _request_destructive_action / _cancel_destructive_action / _toggle_pause / _fit_pause_panel / _place_pause` 八方法在上述两源逐字 SHA 完全相同，证明材料 `/workspace/touch382-diagnostic/method-source-hashes.json`。并不声称两个完整版本相同。

PR394 实时仍 OPEN，head `c443cab5564e399933c487de69e815f90b489726`，归 Assistant #388 音频按钮修复。实际 Main patch 已另存 `pr394-main.patch`：只对三音频 toggle 在原生 GUI 已 pressed 时跳过 manual emit；未更改 slider 先行路由和 modal 隔离。故本诊断不是在该在途 head 上的重测，不把它称为382修复，亦不改其分支。

## 确定根因之一：底层 slider 比确认按钮更早手动命中

真实 Main 节点在 390×844 布局：

- 取消按钮 Rect2 `(28,468,334,44)`。
- 音乐 slider Rect2 `(31,465,328,32)`；手动命中还扩展左/右8、上/下16。
- 真实公开取消输入 `(195,490)` 同时在两区域，扩展 slider 横向中心正好 50%。
- `_request_destructive_action` 只显示 confirm，没有隐藏 pause。被上层遮挡的 slider 依然 `is_visible_in_tree()==true`。
- `_input` 在任何确认按钮命中之前，先处理 ScreenTouch（**不区分 pressed/released**）和 ScreenDrag 的 slider 路由，仅要求 pause.visible，没有排除 confirm.visible。

因此直接调用未修改 Main._input 的单个 ScreenTouch pressed，确认纸片仍显示时音乐已从100变50，并且 cancel 尚未被调用。`probe.log` 的 before→direct_press 明确 `confirm:true`、`music:100→50`。另单独 release_on_pause 也能100→50。

**这条路径无需“先 manual.emit 取消，再同一个事件 GUI 穿到后面的 slider”假说；在取消之前即可改底层音量。** 音量值改变不是听验，本次不评价声音。

## 实际引擎输入分派佐证

`signals.gd` 通过 Input.parse_input_event 而非直接调用 Main 分派一对 ScreenTouch press/release，连接实际按钮 gui_input、pressed 和 slider.value_changed 留日志。未改 Main；隔离设置 `_screen=game`、尺寸、暂停/确认及初值，不模拟普通新档。

Godot4.7.2日志顺序：

1. `GUI cancel Left Mouse Button`（引擎触摸生成的鼠标按钮）。
2. `SIGNAL music 50.0`；press 后 confirm仍true。
3. release出现 `GUI cancel Left Mouse Button`、`SIGNAL cancel`；confirm变false，pause保持true。
4. 随后的真实分派 resume press：`SIGNAL resume`；pause=false、tree_paused=false、各暂停控件不再可见。

这精确复现“取消成功 + 音乐被改50”的组合，也说明 GUI/触摸两路径确实同时参与。日志未逐个记录引擎内部全部阶段，勿推断未记录的浏览器平台内部先后。

## 半暂停仍未定位

本次 native resume正常，**没有复现公开原图仅标题/继续按钮残留的半暂停**。旧公开原始图确实出现该症状；不能因本次正常将其关闭，也不能把音量污染的确定根因当作半暂停确定根因。可能涉及 Web 鼠标合成、按钮状态/重入或容器布局，当前均是待检假说。应在正式 Web 精确按确认→取消→继续链重新记录 pause.visible/tree.paused/各控件 visible_in_tree、GUI button_down/up/pressed 的时间线，独立观测候选不能冒正式无 observer 成果。

现有 pause_notice_suite 直接调用 toggle/通知生命周期，能证明既有通知门禁，不能验证本次 touch/GUI 分派，更不能代替公网端到端。

## 交 Assistant 的最小范围与可验证修复条件

范围优先 Main `_input` 的 modal 路由、slider手势归属/释放处理及去重；不改 AudioDirector 混音、不改存档协议、不动羊/探索/资源。修复前与394作者协调同一 Main 文件，不能覆盖其音频按钮工作。

必须验证：

- 顶层confirm显示时，点取消/好/空白及拖动均不能改底层音量；两种音量初值不只100，还应保留非中心值。
- 从确认开始的手势，其 release/drag不能变成背后 slider新手势；不能只加一个 press 检查后漏 release/转屏。
- 原 pause slider正常点/拖仍能用，三toggle接394后单次只切一次，鼠标/触摸保持一致。
- 取消→继续：实际 Web画面完整回院、pause.visible=false/tree.paused=false、暂停控件全隐藏、玩家可走；同时包含原390×844相同坐标和重新开关确认链。半暂停未独立通过前不得结案382。
- 单一输入重复/迟到/释放不能操作已换层的按钮；不能简单定时屏蔽真实后续手势掩盖故障。

## 可复跑材料

`/workspace/touch382-diagnostic/` 内 `probe.gd/probe.log`（直接方法），`dispatch.gd/dispatch.log`（探索性混合调用；第二轮未取消成功明确保留，不据此结案），`signals.gd/signals.log`（精简确认→取消→继续真实引擎分派），版本方法哈希、394实时JSON与patch。各 native进程实际exit0，日志无SCRIPT ERROR；数据目录分别隔离XDG_DATA_HOME，无读写玩家公开档。

命令例：

```sh
XDG_DATA_HOME=/workspace/touch382-diagnostic/signals-data /tmp/youjia-h2-bridge-bin/Godot_v4.7.2-stable_linux.x86_64 --headless --main-pack /workspace/sheep-attention-export/index.pck --script /workspace/touch382-diagnostic/signals.gd
```

以上原生只为确定输入分派缺陷，画面端事实仍引用既有真实触屏公开证据，不新增“全平台通过”结论。

## 归档状态

本次独立文档分支基于 `2beba2a91f03d911e7dd078d3b90ba1509c2643e`，诊断时的main/394状态按上文保留，不冒称后续分支已验证。脚本与原日志原件逐字节复制，见 original-copy-verification.json；.gdignore隔离诊断脚本导入。运行使用原始本地PCK路径，仓库不附大包或测试用户目录。未改生产代码或任何Owner，不关闭382；修复仍需Owner明确接收并独立验证。
