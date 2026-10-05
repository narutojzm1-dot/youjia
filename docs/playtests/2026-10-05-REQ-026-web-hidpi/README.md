# REQ-20261005-026 网页高清屏按 CSS 像素排版：渲染前后对比

- Agent-ID：`GROK-CONTRIBUTOR`
- 基线：main `1d2bf6708ec6e7992bff9a9380e2996fe6e6b11f`
- 引擎：Godot 4.7.2-stable（linux x86_64），`xvfb-run` + `--rendering-driver opengl3`，原生实际渲染、读 `root.get_texture()` 存 PNG。模拟 DPR 3 手机：1170×2532 物理画布，`WebHiDpi.override_scale` 分别为 1（改前行为）和 3（改后）。不是 Web/公网包，也不是真机。
- 脚本：`render_probe.gd.txt`，改名为 `.gd` 放进 `test/` 即可复跑；只调用 `_start_holiday`、`_show_notice_key`，不瞬移、不改计时。

## 看到的（缩到 390×844，即手机上实际看到的大小）

| 位置 | 改前（倍率 1） | 改后（倍率 3） |
| --- | --- | --- |
| 整体 | 桌面横排布局；院子是屏幕中间一条横幅，上下大片空白 | 竖屏布局；院子填满可玩高度，镜头跟着旅人 |
| 左上目标提示 | 一行约 5px 高的小字，读不出 | 两行 15px，“目标：窗台花箱 / 看看花箱 · 空格/按钮”清楚 |
| 天数 | 顶部居中约 5px | 提示下方“假期第 1 天”可读 |
| 底部按钮 | 三颗 63px 宽小按钮挤在底边，手指难点 | “翻开手帐/大太阳”各半宽一行，“看看花箱”全宽一行，高 48px |
| 底部通知 | 纸片和字都缩到 1/3 | 纸片和字回到 16px，落在按钮上方 |

## 关键帧

两张 1170×2532 原图和缩到 390×844 的对比 JPEG 留在测试机（本通道只有文本文件 API，无法提交二进制），SHA-256：

```
59c78f46a82f924044661aefa3cd121aefe56d4e5f3ed57860b3f3be57006915  phone-dpr3-before.png
04f2dd72a3db8c0b99fcfb29e40d5a779f0f806584c26a7efb1578add75f67bc  phone-dpr3-after.png
3efedbc64f668516c5ef1c986aef7212029a87a0991d94127ebf763644c1f25e  before-css.jpg
ecbd524179be4554e6e4c4cfbd6eaf253fa42cc1cb87adc753f0f8fa494e9e54  after-css.jpg
35fa45ccbc74b78fc3be533428dc53f45f166c370fba1fc629c75e4796e60deb  side.jpg
```

任何人用上面的脚本即可在同一 main 上重新渲染。

## 回归

- `test/web_hidpi_suite.gd`：102 项，`web_hidpi: 102 checks, 0 failures`，退出 0。去掉 `project.godot` 里 `WebHiDpiBoot` 自动加载后同一 suite 39 项失败（预期，证明 suite 真在测接入）。
- 完整严格 `bash tools/verify_daily_life.sh`（本地临时把 `web_hidpi` 挂在 suite 列表末尾，提交里不改该文件）：基于 main `1d2bf67` 退出 0，含 `notice paper suite checks=49 failures=[]`、`web_hidpi: 102 checks, 0 failures`、`[viewport] failures=[]`，日志 SHA-256 `0f7eed569ac41235fbf48e6b244d32343c766e37facb489868d10e8ba89352b6`，留在测试机。

## 没覆盖

真实高清屏浏览器（DPR 2/3 手机、Windows 125%～175%、Mac Retina）上的导出包。建议合入方用 Chromium `deviceScaleFactor=3` 的 390×844 和 `deviceScaleFactor=1.75` 的 1260×886 各走一次标题→入院→点按钮，确认布局与 DPR 1 一致、点击落点正确、控制台无错误。
