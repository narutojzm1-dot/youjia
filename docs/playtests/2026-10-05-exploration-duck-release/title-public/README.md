# PR354 公开标题页验收

2026-10-05；真实公开 https://narutojzm1-dot.github.io/youjia/ 。四个独立 Chromium profile 均读取 HTML game-7c1608c、当页 fetch manifest.sourceCommit=7c1608c7e826f458eaae979d48727b0e6e2bdf58。result.json 逐页保留版本、实际 DPR/backing canvas 和错误。

844×390、390×844，各 DPR2/3：等待 first-frame，截图标题，正常鼠标点击「走进院子」，截图院子。四组成功，page/console errors 全为空。8张关键原图已逐张查看：标题文字与操作说明清晰完整，纸片未出屏/截断，未挡按钮，进入院子后纸片消失。使用 Chromium 软件 WebGL 和模拟 DPR，不是真机触摸/移动 GPU 验证；截图按 CSS 尺寸保存。没有游戏状态注入，没有部署或改生产源码。随机入院时刻不同，不用这些截图断言镜头一致性。

初次尝试在独立 APIRequestContext 请求 manifest 时 IPv6 ENETUNREACH，尚未做交互截图，未计入成功；随后改页面 fetch，完成此四组。browser.py 是最终驱动；browser.log exit0。PCK/source哈希由主线程另验，不在此重复宣称。
