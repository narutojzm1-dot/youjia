# #399 正式公开触摸输入补验：发现异常，未通过返院验收

review304，2026-10-05。两个独立fresh Chromium profile，1280×720 DPR2、has_touch=True/is_mobile=True。所有触摸动作实际使用Playwright touchscreen.tap，不用mouse冒触摸。浏览器仿真不是实体手机。

两页开始/结束manifest完整source ecea67dba1afc9b99b6097970e4965fbcd99c53a及HTML game-ecea67d；实际逐页PCK SHA2562f3ef524dcd455bf2ffddc8aa064e1f6a707f3fef5fd08b8fb5254f7b33c8085匹配。两驱动exit0/errors=[]；不因错误为空判功能通过。

## 首轮

普通tap标题入院、tap(329,563)出门，touch-outside/no-bounce实际近郊空篮。tap(706,500)后touch-walked实际人物已沿路走开；再tap(1060,390)，touch-return虽是院子，却显示初次入院文案“风很轻。你把行李放在门口。”，并非明确正常“回到院里了”。后续普通再点出口、键盘移动的keyboard-away原图出现“上次出门走到一半，已经回到院里了。”。这与正常返院路径不同，**不算touch门返院通过**。

后续keyboard-*文件是定位/移动尝试，实际仍在院内，没有形成有效近郊home_direction键盘返院案例；不得依文件名冒键盘通过。无法稳定继续原趟后停止，没有种子/状态/坐标/时间/存档注入，也没有为找物件无限试探。

## 唯一只读诊断重试

observed-retry新增浏览器原生framenavigated、DOMContentLoaded、完整console时间记录；未注入业务观察器或修改事件处理器。其touch-outside/no-bounce再次真实近郊；**tap(706,500)后touch-walked已经回到院子并显示初次入院文案，在后续tap院门之前发生**。因此该重试更不能叫“点击院门成功回院”。

该页只记录首次1次主frame导航及1次DOMContentLoaded，Godot启动console只首次一组，之后无额外加载记录。可报告“该样本没有浏览器页面重新导航/重新加载证据”，不能由此断言内部具体函数或根因。最后tap院门坐标在院子误选奶牛，touch-return的奶牛招呼不属于近郊返院。

## 结论与交接范围

可证明普通触摸能进入近郊，最初两个采样未立刻弹回；随后触摸输入导致非正常的入院/恢复表现，两轮时机不同。#399触摸返院验收未过，键盘返院、携物触门、重开携物保全未覆盖。交Leader协调Cloud及共享触摸边界Owner诊断；本代理没有修改实现或Github单。既有鼠标空篮公开通过独立保留，不被本结果扩大或替代。未验证物理设备、听验或全DB字节。

result/progress与全部原始PNG保留输入时间、实际截图和来源，图片未加工；所有失败/定位尝试保留，不替换为成功图。
