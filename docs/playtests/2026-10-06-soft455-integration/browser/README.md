# 455 禁用暖纸按钮：普通空手帐候选 Web 验收

Agent-ID：CODEX-LEAD 委派 `hotspot36_qa`。2026-10-05 22:33:37–22:35:04 UTC（北京时间 2026-10-06 06:33:37–06:35:04），在隔离候选预览实际执行。不是正式发布验收。

## 结论

390×844 与 568×320 两尺寸的空手帐均通过本次有限普通路径检查：

- 从标题普通点击“翻开相册”，实际看到空页、“← 往前翻”“往后翻 →”和可用“合上”。禁用两按钮暖纸底、柔墨字可读，较可用按钮浅且边线更细；全视口原图未见按钮/文案溢出。
- 两尺寸分别真实点击前翻与后翻按钮中心，各等待 250 ms 并将指针移开。空页和手帐保持可见，未翻页或关闭；四张点击后原图与各自点击前图逐像素相同。
- 每个尺寸普通点击“合上”都回到标题，说明关闭入口仍可用。
- 两尺寸点击前后的 4 份只读 IndexedDB current 都是同一完整封套，generation=1、album=[]。这是无可见业务变化的旁证，不能代替截图或声称检查了所有内部回调。

没有用写入存档、种子、时钟、内部动作或临时状态获得空相册。初始全新 profile 在首页普通打开即可命中，因此不需要自然单张羊照片的备用路径。

## 源与加载

- 候选 URL：`http://127.0.0.1:8455/`；metadata：`candidate-release.json`。
- sourceCommit/source：`910bdec3fe7bf07833d6b9ccb720f57a5332880c`
- sourceTree：`9b47ef3a4a78a9ca2cab285e93772b5a9540e381`
- entry / HTML data-build：`index`
- 实际下载 `index.pck`：**27,089,276 bytes**，SHA256 `ef5c5c9e13037e83fd76a5c6764c35faaf00c4c3b5f34e007459889c4276549b`

同一 page 开始/结束两次实际 HTTP 核验 manifest、HTML、PCK，以及全部十个 `web/save` 模块和 `open-source-licenses.html` 长度/哈希，均与冻结 manifest 一致。真实导航 HTML 哈希匹配，实际加载 `index.js` / `index.wasm` / `index.pck` 与十模块的 response 都为 200；见 `result.json`。license 只校验文件，不冒称点击了许可外链。大 PCK 下载后释放，不重复归档二进制。

## 原件索引

| 视口 | 点击前 | 禁用前翻/后翻点击后 | 正常关闭 |
| --- | --- | --- | --- |
| 390×844 | `portrait-01-empty-album.png` | `portrait-02-after-previous.png` / `portrait-03-after-next.png` | `portrait-04-closed.png` |
| 568×320 | `landscape-01-empty-album.png` | `landscape-02-after-previous.png` / `landscape-03-after-next.png` | `landscape-04-closed.png` |

`portrait-title.png` 是首次标题；`landscape-00-title.png` 是同 page/context 改变视口后标题，第二尺寸不是第二个 fresh profile。所有截图完整保留，不以裁图掩盖溢出。

`analysis.json` 记录辅助像素：两尺寸禁用按钮底各两点均为 `(243,233,219)` / `#f3e9db`，可用“合上”底样本为 `(255,250,241)`；实际禁用标签 ROI 各包含 110 个实色 `(122,97,82)` / `#7a6152` 字像素。主结论来自真实画面和普通输入，这些采样不代表完整 WCAG/字形辨识度审计。

实际操作见 `inputs.json` / `run.py`：首次 `(195,486)` 打开竖屏手帐，禁用按钮 `(84,666)` / `(195,666)`，合上 `(305,666)`；同 page resize 到 568×320，标题 `(284,205)` 打开手帐，禁用按钮 `(114,284)` / `(284,284)`，合上 `(454,284)`。点击后截图前指针移至外缘。

## 执行与限制

单 Chromium headless Linux、单 fresh context、DPR1、`no-preference`；实际媒体查询 reduced-motion=false。仅普通鼠标和浏览器视口改变，没有触摸或实体设备。为限制内存使用 `--renderer-process-limit=1`，完整参数在 `result.json`。

驱动实际 exit **0**，没有 pageerror / console error / driver_error。22:35:04 UTC context/browser 全部关闭并释放独占窗口。启动前 cgroup 15,923,027,968 B，观测高点 17,073,336,320 B，关闭后 15,852,814,336 B；未开第二页或第二浏览器重试。

未覆盖：正式公开版本、实体手机/触摸/真人听验、#459 键盘焦点、writing/acknowledging/resolving/failed/recovery 的保存提示和恢复按钮、自然单张及所有相册首末页状态、全部禁用按钮、完整存档恢复。原生 4400 与完整回归属于集成者另行证据，不冒充本次 Web 操作覆盖。

`predeclared-plan.md` 是执行前预案快照，其“尚未执行”描述计划编写时状态；执行事实以此报告和原件为准。`SHA256SUMS` 覆盖除其自身外所有文件。
