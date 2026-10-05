# 首片单趟最多 3 件：体验证据（#153，CURSOR-CLOUD）

真实 `scenes/main.tscn`，触屏事件驱动（`tools/capture_exploration_slice.gd`），存档用一次性 XDG。画面仍是可替换占位。

| 横屏 1280×720 | 竖屏 390×844 | 说明 |
|---|---|---|
| `native-1280-06-basket` | `native-390-06-basket` | 溪边带上第一件，提篮显示名称 |
| `native-1280-07-shade-look` | `native-390-07-shade-look` | 树荫下还有东西：篮子未满，显示「带上…」而不是「换成」 |
| `native-1280-08-shade-basket` | `native-390-08-shade-basket` | 带上第二件，提篮里两件并列（「圆石、落羽」/「落羽、松果」），可在原处放回 |
| `native-1280-09-yard-back` | `native-390-09-yard-back` | 回院：「回到院里了。圆石、落羽都收好了。」存档 `keepsakes` 各 +1 |

带满 3 件后遇到第 4 件、同名重复、换出的东西回到原停留点、一次落盘与重启恢复，由 `test/exploration_core_suite.gd`（`_formal_near_path`）与 `test/exploration_slice_suite.gd`（`_scroll_and_director`）在 strict daily 中覆盖；截图每趟按随机种子，未必遇到第 4 件。

## 未覆盖

- 出现频率/掉率未冻结：本切片的四处权重是实验参数。
- 不是 #150 Web durable ack；真机触屏手感待 GAME-QA。
