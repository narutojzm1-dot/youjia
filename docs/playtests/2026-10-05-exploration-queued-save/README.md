# 首片接入异步存档队列：体验证据（#305 / #153，CURSOR-CLOUD）

真实 `scenes/main.tscn`，触屏事件驱动（`tools/capture_exploration_slice.gd`），真实 SaveStore（桌面原生宿主，经 #336 的存档队列），存档用一次性 XDG。

| 文件 | 说明 |
|---|---|
| `native-1280-09-yard-back.webp` | 出门、溪边带上圆石、回院：小院里最后显示「回到院里了。圆石收好了。」 |
| `native-1280-capture-log.txt` | 逐步操作记录；结尾存档 `keepsakes` 为 `{"formal.find.brook_stone": 1}` |

确认前不授予、被拒延后、结果未知等待后落地 / 未落地、同一趟两笔排队只授予一次、院内重试再被拒不打扰、回标题前中断回院再 flush，由 `test/exploration_slice_suite.gd` 覆盖（116/116）。

## 未覆盖

- 不是 #150 / #176 的 Web 持久化验收；浏览器内往返待 Web 宿主体验轮次。
