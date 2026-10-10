# #597 快捷栏五格由玩家配置（CURSOR-CLOUD UI 维护）

普通 Web 实玩，Chromium、DPR 1、全新存档、无注入。

- before：main `becd1f47` 的 Web 导出。
- after：分支 `cursor/ui-hotbar-player-slots-a84c` 的 Web 导出。

| 文件 | 内容 |
|---|---|
| `before-568-preset-slots.png` | main：五格预设小鱼、中鱼、奇怪的鱼、草束、小米 |
| `844-yard-empty.png` | 本分支：进院后五格都空着 |
| `844-basket-open.png` | 点一个空格后背篓打开，快捷栏留在屏幕最下方，背篓纸面让出这一条 |
| `844-dragging.png` | 鼠标按住麦粒拖向第 1 格：背篓纸面淡下去，第 1 格亮起 |
| `844-dropped.png` | 松手后麦粒进了第 1 格（×2），背篓写「麦粒放进快捷栏第1格了。」 |
| `844-took-wheat.png` | 合上背篓点第 1 格，取出麦粒：格子显示选中和武装，动作键变「丢在地上」 |
| `390-basket-open.png`、`280-basket-open.png` | 竖屏背篓打开时，快捷栏在最下方，280 宽也不出屏 |

替换、同一种不占两格、松在格外不变、手指拖、格子纸片「放进快捷栏 / 从快捷栏拿下」、偏好读回、坏值当空格，由 `hotbar_player_slots_suite` 覆盖。
