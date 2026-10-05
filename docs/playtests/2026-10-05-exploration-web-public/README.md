# 公开 Web 版外出探索往返：体验证据（#153 / #305，CURSOR-CLOUD）

对象：GitHub Pages 公开版 `https://narutojzm1-dot.github.io/youjia/`，`game-release.json` 的 `sourceCommit` 为 `bc213f9bea231ac01149d9c818d3fa149de83944`（#322 + #342 合入后的 main）。Headless Chrome（SwiftShader WebGL）1280×720，每轮都是全新浏览器配置（空 IndexedDB）。脚本见 `web-run.py.txt`（第三轮版本；前两轮只差截图节奏与停留点循环）。

| 文件 | 说明 |
|---|---|
| `web-1280-01-painted-path.webp` | 开始假期后点小院左下石板路：走过去直接出门，进入 02 原画近郊，桌面完整构图 |
| `web-1280-02-brook-stone-in-basket.webp` | 点路面走到溪声近处，E 停下看、T 带上：提篮显示「圆石」，可「把圆石放回去」或「接着走」 |
| `web-1280-03-return-notice-sequence.webp` | 第三轮按 R 回院后连续截取的提示区：先「回到院里了。」，存档队列确认后变成「回到院里了。松果收好了。」 |
| `web-1280-04-empty-trip-confirmed.webp` | 第一轮溪边没有东西，空手回院：「回到院里了。空手走一趟也舒服。」 |
| `after-reload.json` | 三轮各自关页重开、继续假期后从 IndexedDB 读出的存档字段与页面错误 |

关页重开后的存档：

- 第一轮（空手）：`exploration_committed_serial` 1，`session` null，`keepsakes` 空。
- 第二轮（四处停留点都停下看，遇到就带上）：`keepsakes` `{"formal.find.brook_stone": 1}`，水位线 1，会话已关闭。
- 第三轮：`keepsakes` `{"formal.find.pine_cone": 1}`，水位线 1，会话已关闭。
- 三轮页面错误均为空。

结论：公开 Web 版上，外出探索经 #336 的异步存档队列落盘，带回物只在确认后授予并显示「收好了」，重开后仍在，空手往返也照常结算。

## 未覆盖

- 不是 #150 / #176 的 Web 持久化验收，也不是手机真机验收；headless 帧率与截图节奏会让提示看起来比真机短（提示本身停 3.2 秒游戏时间）。
- 出现频率未定；每轮遇到什么由随机种子决定，本次两轮各带回一件。
- 画内松果/落羽未清底、正式小物精灵、相邻页仍待制作人交付（#155）。
