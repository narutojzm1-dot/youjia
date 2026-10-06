# 454 相纸与 451 按钮：公开普通路径有限验收

Agent-ID: CODEX-LEAD delegated `hotspot36_qa`。执行时间 2026-10-05 22:16:11–22:22:48 UTC（北京时间 2026-10-06 06:16:11–06:22:48）。仅一个 Chromium headless Linux 浏览器、一个 390×844 / DPR 1 / `no-preference` context，期间真实关闭原 page 再在同 context 新开 page。不是实体手机，也不是浏览器进程重启。运行参数完整保留在 `result.json` / `run.py`，含 `--renderer-process-limit=1`。

## 结果

| 范围 | 实际结果 | 原始证据 |
| --- | --- | --- |
| 454：自然新照片完整显现的照片四周纸衬 | PASS：暖纸实底可辨，不透院子；完整 hold 帧四边采样均为 `#f3e3cb` | `02-natural-photo-02.png`、`02-natural-photo-03.png` |
| 自然羊照片进入相册 | PASS：普通轻抚后在相册看见同一照片及“绵羊愿意靠近我了。” | `03-album.png` |
| 451：重新开始按钮真实按住 | PASS：真实 `mouse.down` 时深色文字在棕黄色按下底上清楚可辨 | `07-restart-held.png` |
| 松开打开确认、普通取消 | PASS：`mouse.up` 后出现确认；点击“再待一会儿”取消，再普通继续，未点击接受重置 | `08-restart-confirm.png`、`11-confirm-cancelled.png`、`16-resumed-after-cancel.png` |
| Tab / Shift+Tab 可见键盘焦点 | **NOT VERIFIED**：5 对暂停截图无变化，含各等待 250 ms 的补测。确认页 09→10 在对话框后方的重开按钮出现轮廓变化，未验到确认框按钮的预期焦点；不作收键或故障因果归因 | `04`–`06`、`09`–`15` 各 PNG，`inputs.json` / `analysis.json` |
| 真关页、同 context 新页后原照与 current | PASS：标题普通打开手帐看见同一照片；三次只读完整 current envelope 相等，generation 均为 2 | `portrait-reopened-title.png`、`18-reopened-album.png`，三份 `*-db.json` |

## 发布来源

公开 URL：<https://narutojzm1-dot.github.io/youjia/>。

- sourceCommit：`a0bb75e38e59032a6df72a2122af4403c3c3e816`
- entry：`game-a0bb75e`
- 实际 HTTP 下载 PCK：`game-a0bb75e.pck`，**27,089,100 bytes**
- PCK SHA256：`111de88653ff4c327a98009062b7b6ba1bea35c51946107041481f45f4b4770e`
- 原 page 前后、新 page 前后共 4 次读公开 `game-release.json`、HTML、PCK、10 个 manifest 指定存档模块；均 HTTP 200，源、entry、长度及哈希一致。两次真实导航 HTML 哈希匹配同轮抓取，页面 `data-build` 匹配 entry。实际 JS/WASM/PCK/module response URL 保存在 `result.json`。
- `result.json` 的 `bindings` 保留每次模块长度/哈希及 UTC；`*-manifest.json`、`*-index.html` 为原件。PCK 逐次下载校验后释放，不重复存储大二进制。

本页同时覆盖已经发布的 454 相纸与 451 按下/确认行为；**455 尚未合入，禁用态不在本次范围**。

## 普通操作及原件解释

完整操作、截图请求/完成时间见 `inputs.json`。首页普通点击进入院子，点击近羊自然获得首照；没有写入存档、种子、位置、游戏状态、时钟或调用内部动作。只使用鼠标和按键；系统媒体条件在 context 创建时设为 `no-preference`，实际读取 `prefers-reduced-motion` 为 false。

首照连续 7 张原图全部保留：00/01 尚未看到卡片；02/03 是完整显现；04 已在淡出，不能用它判定纸衬透底；05/06 卡片已自然消失。取样坐标为左 `(96,390)`、右 `(295,390)`、上 `(195,294)`、下 `(195,493)`，完整 02/03 每点 RGB 都是 `(243,227,203)`。像素辅助肉眼判断，不代替实际观察。截图请求/完成并非精确渲染帧时刻，本次不声称测得精确 1.1 秒保持时长。

相册关闭后真实 Escape 暂停，依次实际 Tab/Shift+Tab；鼠标移到“再过一次假期”后按住拍图，松开打开确认；在确认页也输入实际 Tab/Shift+Tab，随后点击“再待一会儿”。取消后再次普通 Tab/Shift+Tab；有限补测给每次按键留出 250 ms。5 对暂停比较帧像素差异为空；确认层 `09-confirm-tab.png` → `10-confirm-shifttab.png` 的差异仅位于 `(29,260)–(361,303)`，对应确认框后方的“再过一次假期”按钮，10 图可见额外轮廓。确认框的两按钮未验到对应可见焦点，详见 `analysis.json`。本次没有采集 `document.activeElement` 或 Godot 收键事件，故不归因；预期键盘焦点路径仍为 NOT VERIFIED。

取消后普通“继续待着”，只读 current 与最初相册时完全一致。22:21:23 UTC 实际关闭 page，保留同 context，新建 page 从标题普通打开相册；原照可见，重新只读 current、album 与 photo_moments 完全一致。三份只读原件为 `03-album-db.json`、`16-after-cancel-db.json`、`18-reopened-db.json`，只读数据不代替相册截图。

## 执行结束与覆盖边界

驱动实际退出码 **0**；无 pageerror / console error，未抛 driver_error。22:22:48 UTC 全部 context 与浏览器关闭并交还独占窗口；关闭后 cgroup 读数 15,731,372,032 bytes。

本次不覆盖：455 禁用态、382 音频修复与真人听验、舒适度、真机触摸、公开 reduced-motion 再验、全部按钮/状态/无障碍、浏览器进程重启、完整存档验收。原始无变化及确认框后方轮廓变化的帧全部保留，不以其他候选证据替代。

`predeclared-plan.md` 是执行前预案快照，原文“尚未执行”属于计划编写时状态；执行事实以本 README、输入及原始证据为准。`SHA256SUMS` 覆盖目录除其自身外所有文件。
