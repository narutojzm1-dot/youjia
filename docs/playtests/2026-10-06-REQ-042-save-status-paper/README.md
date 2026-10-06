# REQ-20261006-042 保存待确认纸片 体验记录

- Owner：GROK-CONTRIBUTOR；决定见 [REQ-20261006-042](../../decisions/REQ-20261006-042.md)
- 基线 main `267b0cb3df5842170877bf55e438917ad4253ce8`；环境：box Linux，Godot 4.7.2 stable，独立 XDG 数据目录
- 截图：Xvfb + `--rendering-driver opengl3`，`capture_save_status.gd`（复制到仓库根目录后 `godot --path . --rendering-driver opengl3 -s res://capture_save_status.gd`，`CAP_OUT` 指定输出目录）。脚本开假期后调用 `_show_save_pending(false)`，截 `root.get_texture()` 原图并打印纸片、天数标签、目标纸片的全局矩形（视口坐标，非嵌入窗口）。
- 本目录带 `.gdignore`。16 张前后原图（4 视口 × 中/英 × 前/后）**没有放进 PR**：本次只能经 GitHub 连接器按文本提交，传不了二进制。原图留在 GROK 机器 `/tmp/yj043-shots/before2`、`/tmp/yj043-shots/after2`，SHA256 见 `SHA256SUMS`；审查方需要时可用 `capture_save_status.gd` 在任意 commit 上重拍，几何数值应与下表一致。

## 几何对照（视口坐标，x/y/w/h）

| 视口 | 前：纸片 | 后：纸片 | 天数标签 | 目标纸片底边 | 底部按钮排顶边 |
|---|---|---|---|---|---|
| 360×640 中 | 10,90,352,119（右边出屏 2px，压天数） | 10,112,340,119 | 220,76,120,28 | 74 | 516 |
| 360×640 英 | 10,90,352,119（压天数和三行目标纸片） | 10,112,340,119 | 220,76,120,28 | 100 | 516 |
| 390×844 中/英 | 25,90,352,119（压天数） | 19,112,352,119 | 250,76,120,28 | 74 | 720 |
| 568×320 中/英 | 114,90,352,119（压天数） | 10,112,548,57（横排） | 428,76,120,28 | 74 | 196 |
| 640×300 中/英 | 150,90,352,119（压天数，底边 209 压到按钮排 176） | 46,112,548,57（横排） | 500,76,120,28 | 74 | 176 |

原始打印见 `before/geometry.txt`、`after/geometry.txt`。前图英语界面按钮仍是「再确认一次」、消息是中文；后图英语为「Saving needs another check. Please stay here and try again.」+「Try again」。

## 自动验证

- `test/save_status_paper_suite.gd`：**PASS 573 checks**（完整 daily 内）。
- 同一 suite 放到未改的 `267b0cb`：**27/87 失败**，退出码 1（`red-sample-main-267b0cb.log`）。
- 完整 `tools/verify_daily_life.sh`（`GODOT=Godot_v4.7.2-stable_linux.x86_64`，含本专项）：退出 0。`daily-summary.txt` 是按 `godot_suite_completions.tsv` 每条完成格式从原始全日志里取出的完成行加日志末尾；原始全日志 100KB 留在 GROK 机器 `/tmp/yj043-daily.log`。相关回归：`save_feedback` 50、`exploration_slice` 278/278、`soft_button_disabled` 4400、`soft_button_focus_contrast` 5080、`day_label_layout` 173、`hint_paper_fit` 4653 全过。

## 未覆盖

- 没有在真实浏览器、DPR、触屏或真机上看；没有真实磁盘写失败，纸片由测试进程内的受控保存问题触发。
- 底部普通通知切英文后仍是中文、英语 360 宽目标纸片折三行，不属于本切片。
