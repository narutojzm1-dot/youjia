# PR354 标题纸片：Leader 最小集成复核

Agent-ID: CODEX-LEAD（内部实施协助，不是独立审阅者）。原作者 GROK-CONTRIBUTOR；REQ-20261005-028。

作者 head `07f836a9d5b706dc3f7ca40d0b1ab00ea07efa99` 与当时 main `a936bea68bfb37eea47b00c09e3767af74c72b61` 无冲突组合为 `60a175d2ceb0ae6fdb7b0002e189745826187389`。保留作者 Main 实现，仅补 daily 的 title_card 入口（100755）、REQ028 登记及本证据；未修改相册、toast、存档、探索、动物业务。

组合运行 Godot 4.7.2：title_card 251、day_label_layout 173、ui_interaction failures=[]，所有进程 exit 0，无 SCRIPT ERROR。生产 Web 导出 exit 0；本轮没有重新跑完整 daily，作者 PR 正文 full daily 仅属于原 head。PCK SHA256 `db698def974105aae00a48ffa4eeb94b661b53c909c1603345fb45b0aa7a4f5b`。导出自上述组合加仅文档/门禁未提交补充；没有测试观察器或游戏状态注入。

Chromium 软件 WebGL，本地 HTTP 新独立 profile，844×390、390×844 各 DPR2/3：等待真实 first-frame 后截图标题，再实际鼠标点标题「走进院子」，等候并截图院子。四组均成功，浏览器 page/console errors 见 result.json。截图以 CSS 分辨率存档；实际 backing canvas 和 DPR 记录在 JSON。逐张查看标题：纸底在屏内、副标题/简介/操作说明完整且清楚，花草仍从四周露出；点击未被纸底拦截，入院纸底随标题消失。加载 shell 能进入标题；没有额外声称覆盖弱网/加载失败/跨设备听觉或全 UI。

这是本地候选验收，尚未独立终审、尚未据此发布；不冒公开 Pages 验收。不同入院截图的随机位置/镜头时刻不作为此标题切片的镜头回归结论。
