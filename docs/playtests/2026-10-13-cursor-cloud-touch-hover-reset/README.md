# 触屏点按后按钮不再停在悬停样式：Web 实玩证据（CURSOR-CLOUD）

## 问题

触屏点「大太阳」后按钮变成「阴天」，并一直保持鼠标悬停样式（浅杏底 + 鼠尾草色描边），看上去像被选中；从近郊点右上「回院」后，院子里同一位置的「歇一会儿」也一直亮着悬停样式。Godot 把每次触屏合成一次鼠标按键，悬停落在手指下；手机上没有鼠标移开，悬停就不散。

## 方法

- 修前：main `40db1155`；修后：分支 `cursor/ui-touch-hover-reset-a84c` 的 `ccc4bca5`（此后只改本证据文件夹）。两者都用 Godot 4.7.2 本机导出 Web（release），通过本地 HTTP 打开。
- 浏览器：桌面 Chrome（Playwright，`has_touch`）。触屏通过 DevTools 协议 `Input.dispatchTouchEvent` 发真实 touchStart / touchEnd；「鼠标悬停」一步用真实鼠标移动。
- 不是真机：没有在手机 / 平板上测。下文的像素数值取自截图按钮左边框。

## 证据

| 截图 | 构建 | 操作 | 观察 |
|---|---|---|---|
| `before-01-tap-weather-stuck-hover-1280.png` | 40db1155 | 触屏点「大太阳」 | 变成「阴天」，左边框鼠尾草色 (169,192,154)，浅杏底，悬停不散 |
| `before-02-back-yard-pause-stuck-hover-1280.png` | 40db1155 | 近郊触屏点「回院」 | 院子里「歇一会儿」边框鼠尾草色 (138,172,135)，浅杏底 |
| `after-01-basket-cell-tap-1280.png` | ccc4bca5 | 触屏开背篓、点「麦粒」 | 弹出纸片；没有被当成拖动，也没有冒出提示 |
| `after-02-hotbar-add-once-1280.png` | ccc4bca5 | 触屏点纸片「放进快捷栏」 | 麦粒进快捷栏第 1 格且留住，纸片改为「从快捷栏第1格拿下」，没有紧接着被拿下 |
| `after-03-retap-cell-closes-1280.png` | ccc4bca5 | 再触屏点已选中的「麦粒」 | 纸片合上并保持合上，没有又弹开 |
| `after-04-basket-closed-1280.png` | ccc4bca5 | 触屏点「合上背篓」 | 回到院子，快捷栏第 1 格仍是麦粒 ×2 |
| `after-05-tap-weather-1280.png` | ccc4bca5 | 触屏点「大太阳」 | 变成「阴天」，左边框常态杏橙 (244,182,128)，白底 |
| `after-06-mouse-hover-still-1280.png` | ccc4bca5 | 真实鼠标移到「大背篓」 | 照常显示悬停：边框鼠尾草色 (186,200,163)，浅杏底；桌面鼠标不受影响 |
| `after-07-back-yard-pause-chip-1280.png` | ccc4bca5 | 近郊触屏点「回院」 | 「歇一会儿」边框常态 (237,176,125)，不再亮着 |

浏览器控制台无 error / pageerror。

## 修复过程中发现的问题

- 第一版抬指后立即补发画面外的鼠标移动。在背篓里点格子时，合成的鼠标按下落到了格子上，抬起却被 Main 的触屏 / 鼠标去重（400ms）吞掉，格子一直握着鼠标；补发的移动被格子当成拖动，或弹出提示。
- 第二版（`44e15cca`）改为等去重窗过去再补一个画面外的鼠标松开。独立审核发现：这次松开会让握着鼠标的按钮多触发一次——点「放进快捷栏」后麦粒立刻又被拿下；再点已选中的格子想合上纸片，纸片又弹开。
- 最终版（`ccc4bca5`）：背篓打开时，`yard_basket_panel.gd` 不再让触屏合成的鼠标按键进 GUI（触屏本来就全由 `handle_touch_event` 处理）；悬停复位只补画面外的鼠标移动，不补任何按键；格子在左键没按着时不开始鼠标拖动。上面两个回归在 `touch_hover_reset_suite` 里各有检查，在 `c5d599a5` 上失败、在 `ccc4bca5` 上通过。

## 未覆盖

- 真机触屏。
- 竖屏下的 Web 截图：自动套件覆盖了 390×844 与 844×390；390×844 Web 补证见 `../2026-10-13-cursor-cloud-release-notes-pointer-focus/side-781-tap-weather-390.png`。
