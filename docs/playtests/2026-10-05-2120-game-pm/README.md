# 2026-10-05 21:20 GAME-PM公开短体验

实际UTC 2026-10-05T13:28:34.051Z（北京时间21:27附近）。当前源码快照66ae27d6（实际完整SHA见协调记录）；被测页面HTML game-e0d699b，独立curl加载后完整manifest来源 e0d699b8cbaecfabc24a70d2144a7188b5808880，二者匹配；manifest全内容及设备参数保存[result.json](result.json)。未宣称取得公开PCK及十模块实际字节，复用Leader原发布证据也不冒本轮PM自行下载。

Chromium 151.0.7922.173 headless/软件GPU；桌面模拟CSS390×844、DPR2、hasTouch/isMobile，**不是物理手机、真人实玩或耳听**。全新自有浏览器context，无旧玩家档、导入、重置或业务值注入；默认新假期。操作全在正常UI，无故障注入。原驱动[browser.cjs.txt](browser.cjs.txt)，errors=[]；未采集console错误，不能称console零。

1. 鼠标标题进入，等待6秒，正常院景见[01](01-yard.png)。
2. 鼠标右上暂停；音乐100%、环境100%、无提示挡在暂停控件前，见[02](02-pause.png)。这不是377全部时序复验。
3. 鼠标回到门口，确认纸片左右边界收进屏内，文案与两按钮可见，见[03](03-confirm.png)。仅这个尺寸中文范围，不冒562检查或全部DPR矩阵。
4. 唯一真实touchscreen.tap(195,490)“再待一会儿”后，音乐50%、环境100%，见[04](04-cancel-touch.png)。已复现原BUG[#382](https://github.com/narutojzm1-dot/youjia/issues/382)，不新编号；旧d707公开同症已证实，不能归因373新布局。
5. 新独立touchscreen.tap(195,228)继续后只剩顶部“继续待着”按钮/大块纸底的残缺暂停页面，见[05](05-next-touch.png)。只报画面，不猜根因或等同数据丢失。

本次只短体验暂停/退出确认和触摸，未按“好”回门口、未新假期重置、未完整旧档续玩/横屏/英文/全部音量控制/后台/BFCache/10分钟出声/375候选演示/cleanup故障。#195横屏master失败已由Assistant5995407812定位为旧测试点击坐标错误并撤回产品推断，不混同本轮#382真实触摸副作用。
