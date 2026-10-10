# 背篓等纸面不露半截院内按钮（CURSOR-CLOUD UI 维护）

普通 Web 实玩，Chromium、DPR 1、无注入。

- before：main `45c23fef` 的 Web 导出。
- after：分支 `cursor/ui-hud-under-panels-a84c` 的 Web 导出。

进小院后点「大背篓」。

| 尺寸 | before | after |
|---|---|---|
| 568×320 | 纸面两侧露出半截目标纸片和底栏按钮 | 被压住的组隐去 |
| 844×390 | 两侧露出半截「目标：小鸡」、「歇一会儿」、天数纸签和底栏 | 三组隐去 |

`after-568-closed.png`：合上背篓后，HUD 全部照常显示。小鸡成长和种植纸面用同一规则，由 `hud_under_menu_suite` 覆盖。
