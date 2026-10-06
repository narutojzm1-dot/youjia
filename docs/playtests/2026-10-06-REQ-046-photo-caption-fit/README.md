# REQ-20261006-046 新照片小纸卡题词贴合纸条（体验记录）

- Owner：GROK-CONTRIBUTOR　基线 main `06d0349c2346f2f009830e355a94039360955847`
- 环境：原生 Godot 4.7.2 headless + Xvfb/OpenGL3 截图，隔离 XDG，临时院子夹具（不读写玩家存档）

## 看到的问题

新照片落下时那张 240×300 拍立得，照片下方纸条上的题词（「假期第 N 天」+ 一句）放在 192×56 的框里，13px，自动换行、上下居中。逐条量全部 27 条题词 × 第 1/12/365 天：

| | 改前 | 改后 |
|---|---|---|
| 英文 81 条中排成 3 行 | 51 条，13px，高 66px（框 56px，上下各溢出 5px，贴近纸卡底边） | 39 条，12px、行距 0，高 54px，在框内 |
| 英文其余 | 30 条 2 行 13px | 30 条 2 行 13px（原样）；12 条在 12px 下回到 2 行 |
| 中文 81 条中排成 3 行 | 6 条（「大鹅……马背……」两句），66px | 3 条 12px 54px；另 3 条 12px 回到 2 行 |
| 中文其余 | 75 条 2 行 13px | 原样 |
| 最后一行孤词 | 常见，如 `The ducks were drifting on the / pond.` | 无：`The ducks were / drifting on the pond.` |

不需要换行的题词（中文绝大多数、英文 30 条）框位置、宽度、字号、行距完全不变。

## 截图

Xvfb + OpenGL3 下 1280×720 截了 `duck_pond_chorus` 中文 v0、英文 v0、英文 v1 三张纸卡（临时 SceneTree 脚本：院子夹具取快照 → `PhotoArrival.play(snapshot, true)` → 截 viewport）。改前英文 v1 第三行只剩「pond.」且压低到纸卡底；改后为 `The ducks were / drifting on the pond.` 两行平衡居中、在纸条内；中文 v0 与英文 v0 不变。PNG 因连接器不能推二进制未入库。

## 自测

- `test/photo_caption_fit_suite.gd`：**1884 项全过**（中/英 × 27 条 × 3 天，经真实 `PhotoArrival.play`；另测中→英→中→英切换 `refresh_locale` 与 568×320 / 360×640 / 1280×720 旋转）。
- 同一 suite 在未改的 main `06d0349` 上 **153/1899 失败**，见 `red-sample-main-06d0349.log`。
- 既有 `photo_arrival_fit` 418、`photo_arrival_mat` 550、`photo_arrival_shutter_paper` 1290、`photo_arrival_combo` 656、`photo_home` 75、`interaction_photo` 110、`photo_moment_render` 1395、`mixed_input_photo` 6 全过，见 `after-suites.log`。
- 未做：真实浏览器 / DPR / 真机；手帐（相册）页里的题词是另一套排版（`scripts/main.gd`），本切片不动。
