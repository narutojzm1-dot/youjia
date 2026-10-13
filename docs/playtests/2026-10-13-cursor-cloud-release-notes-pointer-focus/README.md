# 版本公告：点按打开 / 关上不再画键盘焦点圈（CURSOR-CLOUD）

## 问题

「歇一会儿」里点右上「0.2.0 · 公告」打开更新公告，底部「返回歇一下」一打开就带着键盘焦点圈（2px 深棕描边）；点它关上后，焦点交回「公告」，「公告」外侧又画一圈深色焦点圈。触屏和鼠标都一样。背篓格子、小鸡照料纸、菜地纸此前已改为点按打开时不画圈（#769 / #777），公告是 #773 新加的面板，还没跟上。

## 方法

- 修前：main `6612526c`；修后：分支 `cursor/ui-release-notes-pointer-focus-a84c` 的 `dc57a1a5`。两者都用 Godot 4.7.2 本机导出 Web（release），拷入 `web/save`、`web/boot` 与 `site/game-release.json` 后通过本地 HTTP 打开（公告状态行因此显示「暂时无法检查更新」，与本改动无关）。
- 浏览器：桌面 Chrome（Playwright，`has_touch`），视口 390×844。触屏用 DevTools 协议 `Input.dispatchTouchEvent` 发真实 touchStart / touchEnd；键盘用真实按键。
- 不是真机。像素取自按钮左边框。

## 证据

| 截图 | 构建 | 操作 | 观察 |
|---|---|---|---|
| `before-01-pause-390.png` | 6612526c | 触屏点「歇一会儿」 | 「公告」常态边框 (243,178,122) |
| `before-02-notice-touch-ring-390.png` | 6612526c | 触屏点「公告」 | 「返回歇一下」2px 深棕焦点描边 (185,130,78)(189,136,86) |
| `after-01-notice-touch-390.png` | dc57a1a5 | 触屏点「公告」 | 「返回歇一下」1px 常态描边 (189,136,86)，无焦点圈 |
| `after-02-closed-touch-390.png` | dc57a1a5 | 触屏点「返回歇一下」 | 回到「先停一下」，「公告」边框与打开前相同，无焦点圈 |
| `after-03-keyboard-on-entry-390.png` | dc57a1a5 | Tab、Shift+Tab 回到「公告」 | 「公告」外侧出现深色焦点圈 (168,93,40) |
| `after-04-notice-keyboard-390.png` | dc57a1a5 | 回车打开公告 | 「返回歇一下」照常 2px 焦点描边 |
| `after-05-closed-keyboard-390.png` | dc57a1a5 | 回车关上 | 焦点回到「公告」，照常画圈 |
| `side-781-tap-weather-390.png` | 6612526c | 进院后触屏点「大太阳」 | #781 竖屏补证：变成「阴天」，左边框常态 (243,182,128)，没有停在悬停样式 |

浏览器控制台无 error / pageerror。

## 未覆盖

- 真机触屏、横屏 Web 截图（自动套件覆盖 1280×720、390×844、844×390）。
