# 460/455 禁用暖纸按钮：正式公开空手帐有限验收

Agent-ID：CODEX-LEAD 委派 `hotspot36_qa`。2026-10-05 23:06:46–23:08:35 UTC（北京时间 2026-10-06 07:06:46–07:08:35），实际访问正式 Pages。该次独立普通操作使用正式 `game-9623ba2`，不是沿用候选 `index` 的截图或 PCK。

## 结果

390×844 与 568×320 的普通空手帐路径均通过本次有限验收：

- 标题普通“翻开相册”后看见空页，实际标签为“← 往前翻”“往后翻 →”“合上”。前后翻禁用按钮的暖纸底、柔墨文字和浅边可辨，和可用“合上”有别；全视口未见按钮/文案被裁掉或溢出。
- 两尺寸分别实际点击前翻、后翻各一次，指针移开并等待 250 ms 后拍完整原图，手帐保持原空页；四张点击后图与各自点击前图逐像素完全相同。
- 各尺寸普通点击“合上”都回到标题。
- 4 份只读 IndexedDB current 完整封套相同，generation=1、album=[]。支持本次没有可见业务变化，不代表检查了每一个内部回调，也不代替图像证据。

一个全新 context、一个 page，先竖屏再通过浏览器 viewport resize 横屏。第二尺寸沿用同一 context，不称第二次 fresh 启动。没有进入院子、写入存档/种子/时钟或调用内部动作来取得空页。

## 正式来源

公开地址：<https://narutojzm1-dot.github.io/youjia/>。

- sourceCommit：`9623ba22c8edc564e5c89dc6b0171324e9230764`
- entry / 实际 HTML data-build：`game-9623ba2`
- 存档模块目录：`save-9623ba2`
- 实际下载 `game-9623ba2.pck`：**27,089,276 bytes**，SHA256 `9de040c80027b41cccc6a331218b39ddd2c765ec108d94197a7fd01febcc0ae4`
- 实际下载 `open-source-licenses.html`：**147,966 bytes**，SHA256 `9215f5fdd50039a9b6f3d8f0271cbc21bbdf64b917fb118dd29c8a16b9974e00`

page 开始和结束均实际 HTTP 下载公开 `game-release.json`、HTML、动态 entry 的 PCK、全部 10 个 versioned 模块和 license 文件。source/entry 一致，模块匹配 manifest SHA，PCK/license 匹配 root 从冻结发布源核定的长度/SHA；前后 HTML 哈希相同，真实导航 HTML 也匹配。公开 manifest 本身不含 license 字段，该文件使用独立提供的准确源哈希，不能说是 manifest 内记录。

`result.json` 保留两次完整来源观测、actual loaded JS/WASM/PCK/十模块 response URL 和 200 状态。license 在本次只做 HTTP 文件核验，没有点击外链。大 PCK 校验后释放，未冗余归档。

## 证据索引

| 视口 | 空页及按钮 | 实际禁用前翻/后翻点击后 | 正常合上 |
| --- | --- | --- | --- |
| 390×844 | `portrait-01-empty-album.png` | `portrait-02-after-previous.png` / `portrait-03-after-next.png` | `portrait-04-closed.png` |
| 568×320 | `landscape-01-empty-album.png` | `landscape-02-after-previous.png` / `landscape-03-after-next.png` | `landscape-04-closed.png` |

首次标题 `portrait-title.png` 与同页 resize 后 `landscape-00-title.png` 也完整保留。四份只读 DB、全部实际输入与截图请求/完成时序分别见 `*-db.json` 和 `inputs.json`。

点击位置按真实画面核准：竖屏标题相册 `(195,486)`，前翻 `(84,666)`、后翻 `(195,666)`、合上 `(305,666)`；横屏标题相册 `(284,205)`，前翻 `(114,284)`、后翻 `(284,284)`、合上 `(454,284)`。完整脚本见 `run.py`，没有任意业务 JS 执行入口。

`analysis.json` 中的像素作为画面辅助：两尺寸禁用底各两个点均为 `(243,233,219)` / `#f3e9db`，合上底为 `(255,250,241)`；实际禁用标签 ROI 各含 110 个实色 `(122,97,82)` / `#7a6152` 字像素。主结论依据真实截图与输入，这不是完整 WCAG 或所有字形可读性审计。

## 关闭及未覆盖

单 Chromium headless Linux、DPR1、no-preference；实际 reduced-motion 查询为 false。使用 `--renderer-process-limit=1` 控制资源，参数保留在 `result.json`。没有第二页/第二浏览器，也没有重试掩盖失败。

驱动实际 **exit 0**，没有 pageerror、console error、driver_error；所有记录的实际资源 response 为 200。23:08:35 UTC 全部 context/browser 关闭并释放独占窗口。启动前 cgroup 15,906,213,888 B、观测高点 16,948,187,136 B，关闭后 15,896,813,568 B。

未覆盖：#459 键盘焦点、音频与真人听验、物理手机/触摸、reduced-motion 再测、writing/acknowledging/resolving/failed/recovery 保存/恢复状态、自然单张及所有首末页、游戏所有禁用按钮、完整存档可靠性。不可把此公开空手帐有限证据扩大为这些项目通过。

`predeclared-plan.md` 为执行前计划快照，“未执行”指编写当时；实际结果以本报告和原件为准。`SHA256SUMS` 覆盖除其自身外所有文件。
