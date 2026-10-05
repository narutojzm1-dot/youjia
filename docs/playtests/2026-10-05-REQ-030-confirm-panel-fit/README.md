# REQ-20261005-030 确认纸片收进手机屏幕：原生截图测量

- Agent-ID: `GROK-CONTRIBUTOR`
- 基线：main `5bb2102aa7d4fbf1c53953d9148762a0495c4c89`
- 环境：原生 Godot 4.7.2 stable + Xvfb，`--rendering-driver opengl3 --resolution WxH`，脚本 [capture_confirm.gd](capture_confirm.gd)（开始假期 → 歇一会儿 → 回到门口，量纸片矩形并截图）。
- 不是浏览器、不是 DPR 2/3、不是真机；真实 Web 复核交合入方/QA。

## 实测（`_confirm_title` 所在纸片的全局矩形）

| 视口 | 修前纸片 | 修后纸片 | 说明 |
| --- | --- | --- | --- |
| 320×568 | x −50…370，宽 420 | x 12…308，宽 296 | 修前左右各出屏 50px |
| 360×640 | x −30…390，宽 420 | x 12…348，宽 336 | 修前左右各出屏 30px，圆角/边框不可见 |
| 390×844 | x −15…405，宽 420 | x 12…378，宽 366 | 修前「好 / 再待一会儿」按钮两端贴屏幕边 |
| 844×390 | x 212…632，宽 420 | 不变 | 横屏本来放得下 |
| 1280×720 | 宽 420 | 不变 | 桌面不变 |

高度在这些视口都是 240（屏高减 24 都大于 240），中英文、「回到门口」「再过一次假期」两种说明文字都在纸片内、每行可见。

我逐张看了修前修后截图（360×640 英文、390×844 中文、844×390 中文）：修前竖屏纸片两侧被屏幕切掉，修后四个圆角和边框完整、左右各留 12px；横屏前后一样。截图本身没有提交：本通道只能推文本文件，复跑上面的脚本即可重现（`YOUJIA_CAPTURE_DIR=<目录> W=390 H=844 godot --rendering-driver opengl3 --resolution 390x844 -s capture_confirm.gd`）。

## 自动检查

- `test/confirm_panel_fit_suite.gd`：修后 562/562 通过；在未改的 main 上 78/562 失败，全部在 320/360/390/412 宽竖屏。
- 本地完整 `tools/verify_daily_life.sh`（临时在列表末尾加 `confirm_panel_fit`）：exit 0，无 `SCRIPT ERROR`；day_label_layout 173、title_card 251、hint_paper_fit 4653、confirm_panel_fit 562 照常通过。
