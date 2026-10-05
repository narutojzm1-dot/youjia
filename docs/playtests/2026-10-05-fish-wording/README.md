# #231 奇怪的鱼成功通知修正

运行时差异仅两个JSON目录中的notice.fishing.caught.odd；JSON可解析、键集合一致、其他值逐项不变。随机成功类型、20秒携带、投喂及真正到期release均不改。

## 最终文案与实际Web
中文：钓到一条奇怪的鱼。英文：Caught a peculiar fish.

Godot4.7.2严格导出测试入口，Chromium151在1280×720和390×844分别实际渲染两种语言；四次结果均key=notice.fishing.caught.odd、carry=odd、timer=20、pageerror为空。手机两图已查看，短句在通知区域一行显示，不挤入按钮。先前较长候选在手机换行拥挤，已舍弃；结果文件和图片均为最终短句。

方法：probe调用真实Main/YardWorld和_reel_in_fish，使用seed并最多40次得到odd，随后冻结Main推进供截图；人物位置与鱼咬钩状态受控设置。这是实际生产handler/通知/携带状态的浏览器证据，不是自然输入、完整垂钓体验、投喂Web或新发布版本验证。投喂/失败三序列仍由GROK原PR276补齐。测试入口不进入正式提交/发布。

复跑：在一次性checkout，将probe.gd.txt与probe.tscn.txt还原到根目录wording_probe.gd/wording_probe.tscn，临时设置project.godot run/main_scene到后者，以Web预设导出到/tmp/fish-wording-web；用Python Playwright及/usr/bin/chromium执行browser.py和browser-mobile.py。复跑后恢复project.godot，删除根目录测试入口。使用独立user data/context，勿导入玩家档。正式CI使用原main场景，无探针。

## 原生现状检查的边界
preliminary-native.log是GROK PR276 8ffefdf测试脚本在本轮较长文案候选上的58项实际通过日志，使用独立XDG目录；不是最终短句测试。它保留源码中的静态S7 FINDING旧诊断行，不能将该行当成当前界面文字，实际text字段见上一行。

ASSISTANT随后对原测试指出_fresh先reset后清旧world会回灌进度、README独立执行缺隔离保护（2765986358795）。因此该日志只作原始排查记录，不作为本修复最终门禁或父缺陷完成证据；GROK仍须修订其PR。最终本切片证据是运行时仅两文案差异、真实handler双语Web与独立最终SHA审查。父#231不关闭，旧鱼再次miss及其他反馈歧义未修。
