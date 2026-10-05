# BUG382 触摸补证：取消改变音量 / 继续后半暂停

QA only；没有修改运行时，没有注入Main状态、读取引擎节点或DOM造图，没有手动调整音量。所有输入为 Playwright touchscreen.tap，逐步查看真实原图后再选择下一次坐标。两个独立全新测试 browser context；没有操作玩家存档或执行清库。截图原始像素不编辑，原探针 /workspace/confirm373-candidate 保留。本目录是新增补证，不改PR373已审归档。

## 来源及运行环境

- 候选 http://127.0.0.1:8195/，Owner源SHA 6f9d15b8afe2bbc9d9ca0ba2f50a993c06a55b4b；此前实际下载PCK哈希 794fc7656acd4bceaf3c82f9b4f13d08cb52df0df4abcf1bff91905825e7da29。
- 公开 https://narutojzm1-dot.github.io/youjia/；前后 game-release.json 均 source d707113f8dde1636d24dfcff821518cd0555b277，entry game-d707113；实际流式下载 game-d707113.pck 哈希 098a4b70598a6bc261e26cf7ae9e38c5fb10ab5be07c8bdb7284c40f1fafe83a。manifest原文在 public-manifest.json / public/manifest-after.json，哈希在 public/pck.sha256。未重复保存PCK。
- Chromium 151.0.7922.173；390×844 CSS，DPR2，is_mobile/has_touch true；截图780×1688原始像素。实际console确认 Godot4.7.2.stable.official.ed1daf0bf、WebGL2 Compatibility、Emscripten4.0.20单线程。
- 两个driver的 logs.json 保留日志；无console.error或pageerror，存在GPU ReadPixels性能warning，不视为功能通过证据。
- cmdN.json 为实际输入，actions.json 为指令文件创建UTC时间（不是浏览器event精确时间）；对应stepN.png为执行后至少2.5秒截图。人工查看、命令发送间另有等待，截图文件UTC时间另存image-manifest.json。

## 已排除的测试解释

在暂停原图（step1）回门口按钮原像素y638–723，对应CSS319–361；继续待着按钮原像素414–499，对应CSS207–249。因此(195,340)是回门口，不是继续。原自动触摸异常不能凭猜测归为坐标误命中。本次逐步相同坐标能正常打开确认。

## 候选逐步结果

initial 标题；cmd0 (195,430)→step0院子；cmd1 (310,44)→step1完整暂停，音乐100%；cmd2 (195,340)→step2确认纸片。

**最小可见副作用：**只发送 cmd3 touchscreen.tap(195,490)，命中确认纸片“再待一会儿”（原像素y939–1021），step3返回完整暂停，但音乐100%变50%。期间没有调音操作；50%对应背后音乐滑条中部。事件穿透只是待验证解释，未断言根因。

随后cmd4 (195,228)继续：step4纸片只剩标题和继续按钮，其余菜单不见，未回院。cmd5尝试原院子暂停坐标(310,44)，step5仍半暂停；cmd6不发送任何输入，只等待截图，step6仍半暂停；cmd7再次触摸可见继续按钮，step7仍半暂停。该profile的正常离开/续玩链因此没有完成，不能记通过。停止driver，没有执行清库或重置假期。

## 373之前公开版本复验

public/initial→cmd0进院→cmd1暂停音乐100%→cmd2确认（旧版纸片左右超屏可见，符合未含373）。

- public/cmd3只touch(195,490)取消，public/step3回暂停音乐50%。故音乐副作用也存在于373前公开版。
- cmd4同坐标(195,340)再开确认，cmd5同坐标(195,490)再次取消，step5仍50%。没有额外调音；第二次50→50不能当第二次音量下降。
- cmd6再开确认；cmd7 touch(195,434)“好”，step7首张仍确认。cmd8为无输入等待截图，step8已标题。**这里说明首次2.5秒截图不足以判断失败。**
- cmd9在标题touch(195,434)“走进院子”，step9回到同页假期院子；cmd10暂停，step10音乐仍50%。这一段真实完成“好→等待→标题→再次进入原假期”，无重置。
- **之后另一个阶段：**cmd11只touch(195,228)继续，step11再次出现仅标题/继续按钮的半暂停；cmd12无输入等待截图，step12仍半暂停。此现象也存在于373前公开版。

## 结论与边界

可确认两个具体可见异常：取消确认误改变音乐音量；触摸继续后菜单不完整且在本次等待窗口内未回院。候选与旧公开版各有原图证据。没有证明底层原因、修复方式或是否所有设备复现，不能归因PR373引入。仅公开测试的好→等待→标题→回院链已完成，与最终半暂停阶段严格区分。

root已创建BUG382交Assistant接收，独立审查及修复另行进行。本补证不宣称触摸全通过，不宣称已修复；不追加无意义矩阵。
