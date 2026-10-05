# 独立候选双页写者提示与真实重试验收

PASS 本次普通两页路径。runtime `830320b28ef1592244070683bf0bc3e1acfcdd84`，正式无observer本地导出 `http://127.0.0.1:8194/`，data-build实际为index；不是公开game-SHA。独立HTTP流读取index.pck：27,078,328字节、SHA256 `7ca4ecbfe7c126e3f00ca41d4fb3849cc7098a222175c46fe7e007e01ddb1b86`，与实施者source-build匹配，见package-check.json。候选未宣称已发布。

同一个全新Chromium context、1280×720、软件WebGL。第一页正常标题进入、鼠标点击羊生成自然照片并打开手帐；第二页正常加载同URL，实际Web Lock竞争显示“另一页正在游玩 / 请回到原来的页面，或关闭后在这里重试。”及重试按钮（second-blocked.png）。第二页first-frame未出现，未进入游戏；第一页仍显示原照（first-preserved.png）。没有注入锁、存储故障或业务状态。

真正关闭第一页，实际点击第二页DOM“重试”按钮，由生产location.reload重新加载；正常标题进入再开手帐，原照片、假期第1天、题词均保留（second-recovered-album.png）。已亲看全部四张原图。

readonly全DB在开第二页之前、第二页阻断中、关闭原页并重试后完全相同，见records.json；records仅current，generation2，没有intent。没有第二页覆盖原存档或重复照片。run.py实际exit0；pageerrors=[]，console error=[]。动作时刻、三次build绑定、原日志均保留。

最初driver错误期待本地export为发布game-830320b，而实际为index，立刻断言退出；attempt1保留该脚本/日志，不算产品失败或通过。改为实际index+独立PCK哈希绑定后完整新context重跑通过。

不涉及触摸、真机、掉电、故障矩阵或未知错误真实浏览器注入。未知原因不误分类/first-frame门禁等代码预审及独立node loading_shell_test通过，与本普通浏览器证据分开。最终PR仍需针对最终完整SHA独立批准。
