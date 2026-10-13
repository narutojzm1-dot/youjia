# 背篓纸条第一次打开不再留出大块空白（CURSOR-CLOUD）

面粉纸条在 `8b08e054` 已经按最终宽度重算。同一处缓存还留在其他说明上：格子第一次弹出的纸条，说明在纸片有宽度之前就量过高度，父容器沿用了那次又高又窄的最小高度。

本档是受控组件画面（Godot 4.7.2，`--display-driver x11`，独立 `XDG_*` / `YOUJIA_TEST_ISOLATED_DATA`），不是普通 Web 游玩，也没有注入玩家存档。生产界面仍固定中文；英文图只为对照换行。

## 修前（main `34740e7e`）

首次打开、底部空隙 = 纸片底边减去「算了」底边。空隙 10px 才算贴住按钮。

| 画面 | 说明 | 纸片 | 空隙 |
| --- | --- | --- | --- |
| `before-zh-390-stone-full.png` | 院里三处都摆满 | 200×723 | 585px |
| `before-en-390-stone-full.png` | All three spots are taken | 200×1698 | 1535px |
| `before-zh-390-wheat-keep.png` | 留这一把下次播种 | 204×348 | 235px |
| `before-zh-390-fish-busy.png` | 正在确认保存 | 204×423 | 310px |

英文留种纸条 211×773（空隙 660px），英文保存说明 204×523（空隙 410px）。390×844 与 1280×720 的纸片尺寸相同，高出来的是空白，不是更长的句子。

## 修后

说明可见时，在宽度已经定下之后丢掉旧的最小高度，再按当前内容收拢。没有改库存、摆放或按钮文案。面粉仍走同一段重算。

| 画面 | 纸片 | 空隙 |
| --- | --- | --- |
| `after-zh-CN-390x844-stone-full.png` | 200×148 | 10px |
| `after-en-390x844-stone-full.png` | 200×173 | 10px |
| `after-zh-CN-390x844-wheat-keep.png` | 204×123 | 10px |
| `after-zh-CN-390x844-fish-busy.png` | 204×123 | 10px |
| `after-en-390x844-wheat-keep.png` | 211×123 | 10px |
| `after-en-390x844-fish-busy.png` | 204×123 | 10px |

同目录还有 1280×720 的修后图，纸片尺寸与上表一致。没有说明的小鱼纸条（拿一条 / 算了）修前修后都贴住按钮。

`yard_basket_grid_suite` 在五个视口、中英两种语言里检查：三处摆满、留种、保存中、以及没有说明的小鱼，都是各自格子上的第一次打开。本分支实测 `[yard-basket-grid] PASS: 1810 checks`。
