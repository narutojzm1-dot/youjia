# #597 快捷栏共享保存：公开发布实玩验收

Owner / 验收：CODEX-LEAD；北京时间2026-10-11凌晨。

## 精确版本

- PR716最终head：`07c98973f4098c6fb98343d128e392d52f2340a1`；完整CI [38072120892](https://github.com/narutojzm1-dot/youjia/actions/runs/38072120892)成功。
- 合入/公开source：`f2edc3caa5ce85825e00f911374af68ca2b4dc46`，`game-f2edc3c`。
- Publish [38078184938](https://github.com/narutojzm1-dot/youjia/actions/runs/38078184938)、Pages [38079163058](https://github.com/narutojzm1-dot/youjia/actions/runs/38079163058)均成功。Pages提交 `d85e6aea93244ae556a1cf73f9ee4e92fe3a64a5`。
- 实际公开PCK：69,573,560字节，SHA256 `47a75b180f5a4abf5a4f4ae46f022cf37d72ca2312c5281a09d9cea61b768ee1`。HTML/PCK Git blob与gh-pages一致；另逐文件下载核对10个存档模块、4个引擎文件、2个加载模块。原始manifest及verification.json随附。

## 普通公开网页操作

Windows / Codex IAB，先1280×720，再390×844视口模拟；普通鼠标输入，没有注入游戏状态、清档或改浏览器存储。

1. 升级前game-55d3717：原第23天17:43存档，麦粒2、玉米2、圆石3、松果2，其余背篓种类0、手里空着、五格空。见before-upgrade-basket.jpg。
2. 新公开页面加载标识game-f2edc3c后进入同档，天数和上述库存保持。见upgraded-basket.jpg。
3. 背篓麦粒拖第一格、玉米拖第四格；数量不变、其余格仍空。见configured.jpg。
4. 关闭整个测试标签页，新建同一公开URL，进入院子：第一格麦粒2、第四格玉米2恢复。见desktop-reopened.jpg。不是只关背篓，也不是在同一游戏实例内切场景。
5. 切390×844，打开背篓，库存仍麦2/玉米2/石3/松2。点麦粒菜单“从快捷栏第1格拿下”，第一格变空，麦粒仍2、手里仍空。见phone-restored.jpg、phone-removed.jpg。
6. 再次关闭标签页、新建同一URL后进入院子（新页1280×720）：第一格保持空、第四格玉米2保留；打开背篓库存和手持仍保持，时间自然到当晚。见removed-reopened.jpg。

两次真实关页重开成功，配置增删不消耗物品。操作后的浏览器warn/error采集为空，见final-browser-errors.json。原生真实落盘、失败/未知状态及快速更改回归见[原实现证据](../2026-10-11-hotbar-save/README.md)。

## 边界与过程异常

首次公开加载显示下载完成已用37秒，继续等待后进入标题；点击进入院子出现控制工具Input超时，但重新观察时游戏已进入，未盲目重复点击。第二次关页重开的组合调用触发工具内核超时，重新枚举确认旧页已关闭、新页已创建，接回新页继续完成上述验收。工具异常没有记为游戏存档丢失，也不以这几次成功宣称加载性能/稳定性通过。

390×844是桌面浏览器视口模拟，未做手机实体触屏、系统杀进程/断电、配额耗尽、跨设备同步或真实音频听验。本片只验收#597共享保存缺口，不关闭#597全部交互要求，不宣称三餐/成长/疲劳已实现。不重复Oct10日推邮件。

## QA710资料接收

QA原提交 `8c1ccdf26de5d9d4e8df428c3db8907bf366c3d5` 保留为合入父提交；19份证据哈希逐项一致，抽看收获库存与阳台截图；仅docs/decisions.md尾部追加冲突，保留主线及QA双方全部条目。QA原报告对应旧game-e9e7292，不冒充新包独立复测；代码与美术未改，原始证据字节不变，CRLF按证据原件保留。
