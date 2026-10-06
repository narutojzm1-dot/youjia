# 461 ShutterCaption 暖纸背景：普通首照候选 QA 预案（未执行）

执行者：CODEX-LEAD 委派 hotspot36_qa，只读QA，不改生产源码/业务状态。已读 `/tmp/pr461-code-prereview.md`、`/tmp/youjia-photo461/scripts/ui/photo_arrival.gd`、生产标题/暂停菜单及语言初始化；原作者742b293、准备集成fd887ff8均不是提前声称已验证的浏览器来源，实际运行以root冻结候选manifest/source/PCK为准。

## 开始前与资源安排

等 soft444_integration 释放唯一引擎、root提供实际候选URL/完整sourceCommit/entry/PCK字节与SHA256并明确授予独占浏览器窗口。现在只准备、只做Python语法compile，禁止提前启动浏览器/Godot。

**执行前修改（root明确同意）：** 原拟全程onecontext，改为同一browser内两个fresh context严格串行；390×844完成普通首照、相册与只读DB后明确关闭context，再创建568×320的新context。任何时刻最多一个page/context。这样两个尺寸各有真实首次羊照片，不修改或清空存档、不对同一事件强制重播。浏览器使用renderer-process-limit=1，PCK取body核哈希后释放，结束全部close并立即释放窗口。

## 范围与真实入口

1. 两个尺寸均中文、DPR1、no-preference、鼠标普通操作。生产Main初始化固定zh-CN，标题仅进院/相册/声明，暂停仅会话/音频；未发现面向玩家的语言和减弱动态开关。因此**英语与减弱动态UI端到端在本轮未覆盖**；不会通过locale setter、TuningStore、JS或内部状态设置冒普通E2E。原生受控矩阵由集成者独立报告；系统prefers-reduced-motion模拟也不冒成此次游戏UI入口。
2. 首次载入后拍完整标题，普通点击“走进院子”，待画面稳定拍院子基线。坐标参考此前454/447真路径：390×844标题(195,430)，近羊曾为(236,474)；568×320标题(284,160)，羊曾为(205,113)。动物会走动，按实际截图校准，参考坐标不当固定内部位置。
3. 普通点击近羊自然轻抚取得首张真实照片，不注入seed/位置/快照/保存状态，不调用PhotoArrival.play。将该click与连续截图放在同一stdin批次，中间不等人工确认；约12–15张全视口图、间隔30–80ms，具体以实际capture request/complete timestamps说明，不冒精确帧率。
4. 需要同时抓到“旅人随手拍下了这一刻。”的纸底/文字完整显现，以及自然退场后不遗留纸片。完整hold与淡入/淡出分开选图，不把消失后的图冒完整显现；若窗口错失保原件并记未覆盖，不以内调用重播。之后等待约500ms再留退场图。
5. 短横屏要如实对照首照前目标提示、题词显现期间与退场后：暖纸题词是否可读、在文字后方、未裁边，与卡片是否分离；纸底若暂时盖住左上目标提示某段，应准确写出，不声称“二者始终完整可读”。不为了美化报告裁掉遮挡区域，也不主动改Main布局。
6. 普通点击“翻开手帐”并看同一新照片，普通“合上”返回院子留图。参考390×844院内手帐(100,744)，合上(307,667)；568×320手帐曾(140,220)，具体以本次画面校准。可只读current/album/photo_moments辅助证明原照保留；不代替可见相册图，不宣称完整存档覆盖。
7. 首个context完成图与只读DB后执行显式close（含该页after来源核验），关闭记录落盘后才new第二个fresh context。第二个完成后end，报实际exit、UTC关闭与内存，之后只离线README/analysis/SHA256。

## 来源和原件

每个context前/后共4次实际读取候选candidate-release.json、HTML、动态entry.pck、十个web/save模块和license依赖（以冻结manifest files为准），哈希/字节对manifest和root给定PCK；真实导航HTML一致，data-build等于实际entry。源变化或导出不完整即停止保存失败，不把candidate index和正式game/save目录混用。记录实际JS/WASM/PCK/modules response URL/status及page/console错误。

输出拟 `/dev/shm/photo461-candidate-qa`（尚不创建）。驱动 `/tmp/photo461-candidate-driver.py`（已compile未运行），必填 --url --runtime --entry --pck-sha256 --pck-bytes --out；普通输入/截图/只读DB，新case要求先显式close，不能任意JS。

## 限制

不覆盖英语/减弱动态UI、真机/触摸/真人听验、459键盘诊断、所有照片类型与完整保存恢复、精确动画时长/帧率。亲眼截图与像素只是本次观察，不将静态draw_center/IGNORE代码或原生夹具当真实输入透传全覆盖。未发生的偶遇或错失的短窗口明确留未覆盖，不无限刷新。
