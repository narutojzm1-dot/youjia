# 暂停纸面不露半截院内按钮（CURSOR-CLOUD UI 维护）

普通 Web 实玩，Chromium、DPR 1、新存档、无注入。

- before：main `0c871f88` 的 Web 导出。
- after：分支 `cursor/ui-hud-under-menu-a84c` 的 Web 导出。

进小院后按 Esc 打开「先停一下」。

| 尺寸 | before | after |
|---|---|---|
| 568×320 | 底栏四枚、目标纸片和「歇一会儿」露出半截 | 被压住的三组都隐去 |
| 640×360 | 同上 | 同上 |
| 844×390 | 天数纸签被切掉一截，底栏上沿被压住 | 右上一列和底栏隐去，目标纸片保留 |
| 1280×720 | 纸面下沿压在「大背篓」上沿 | 底栏隐去 |
| 390×844 | — | 不变（`after-390-pause.png`） |

`after-568-resumed.png`：再按 Esc 回到院子后，全部 HUD 照常显示。
