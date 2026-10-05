# 启动防重入候选独立普通 Web QA

运行源码fe4f4dd080c2f02a943687e0e1df2a2d2266f8a7，localhost8200；这是普通本地候选，非正式发布，无线上manifest/HTML生产标识。每页前后实际git HEAD完整SHA绑定，逐页下载index.pck核SHA256 ff17bbbed214843b4cc6738aafb0f285cb4d48322e8d02d0a3c98f3dbf6f1a18。HTML实值null如实记录，未伪造生产身份。两次脚本总3fresh profile，每个1280×720/DPR2、has_touch/is_mobile。所有触摸均真实Playwright touchscreen.tap；键盘使用真实keydown/up。不注入业务/位置/随机种子/时间或存档；仿真非实体手机。

## 真实结果

首touch profile正常标题进入、触摸出门后停留仍近郊空篮；tap(706,500)走开后和追加等待均仍近郊。原失败“走开即初次入院/恢复”未在本候选此链复现。tap门后固定7秒的touch-return.png仍近郊，人物向门行进；该图是未走完中间状态，**不是正常返院通过，也不判断门功能失败**。

独立fresh keyboard profile：普通触摸出门后实际键盘ArrowLeft 1800ms离门，keyboard-walked为近郊；ArrowRight 5000ms再等待2500ms，keyboard-return.png明确院子“回到院里了”。实看正常返院，不是首次arrive或恢复文案。

仅一次额外touch-wait profile复用同触摸链，保存7秒中间原帧，再真实等待14秒（不快进游戏）。最终touch-wait/touch-return.png明确“回到院里了。空手走一趟也舒服。”。走开/等待时一直近郊，门点击后走完才正常返院。已实际看图。此为真实空篮触摸回院PASS，7秒旧中间帧原样保留。

两脚本实际exit0/errors=[]。导航/DOMContentLoaded及console原生日志保留，没有额外页面重载证据。只报告该限定普通链修复复现结果，非因果追踪日志，不等同所有触摸问题已解决。

## 未覆盖

携物回院、三物矩阵、关页持物保全、物理触屏、音频、全部保存故障及正式公开发布均未覆盖。本轮无需找物而未随机刷取；既有公开鼠标425对照独立，不冒此候选鼠标重测。正常键盘与触摸空篮范围可供独立最终审核，#399其余边界仍须单列。
