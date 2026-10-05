# #399 一次隔离真实触摸诊断

Agent-ID /root/horse180_repro，2026-10-05。源 ecea67dba1afc9b99b6097970e4965fbcd99c53a；独立 git archive 到 /dev/shm/gate399-trace，仅 instrument.py 所示 Main 日志增量，无 guard/业务分支改动。未改在途生产分支。

Godot 4.7.2 首次 debug export 失败：没有 debug Web 模板；export.log完整保留。随后 release export exit0，export-release.log保留。故 get_stack() 实际为空，不虚称得到栈。诊断 PCK SHA256 1c59bd30b43a7996c7c42c684d240ea764567bf3bfe5a8462efcdda0f76d4443，位于 /dev/shm/gate399-export/index.pck；它不是正式发布 PCK。原生产 web/save 模块复制到诊断静态目录，无修改。

一次干净 Chromium context，1280x720 DPR2 has_touch/is_mobile，真实 Playwright touchscreen.tap；仅 title(640,368)→院门(329,563)→普通路面(706,500)。无业务状态注入。driver exit0，page errors[]、console error无。三个原PNG均未加工，已亲看outside/walked，均为近郊，后者人物正常沿路移动。没有重试矩阵。

## 实测确定事件

result.json console 原始序列：

- frame39 MouseButton press，screen=title；PLAY_DOWN。
- 同frame ScreenTouch press；PLAY_PRESSED screen=title；START1；FLUSH_BEFORE1；FLUSH_AFTER1。
- **同frame又一次 PLAY_PRESSED，screen=game；START2；FLUSH_BEFORE2；然后PLAY_UP。**
- 随后 notice.arrive；后续mouse/touch release。
- frame62 EXP_ENTER；frame95普通路面mouse/touch按下释放，仍为exploring。

由此已实际证明一次标题触摸会触发两次启动，第二次启动发生在game状态，且本次在flush处等待。与手工 ScreenTouch.emit / 原生GUI释放叠加路径一致；未获得release栈，不将内部C++信号来源当作已取栈事实。

## 没有证明的部分

本次等候窗口结束时未出现 FLUSH_AFTER2，没有复现公开样本的迟到重建/弹回；不得称完整#399因果已端到端复现或正常门返院通过。start2等待与公开晚到arrive之间仍需Owner分析队列/生命周期；已确定的重复启动本身足以列入修复条件。日志会影响时序且本地诊断包不同于正式发布，不能取代正式Web复验。没有听验/实体手机/携物覆盖。

## 交接

生产Owner仍由Leader协调Assistant382（共享Main输入）和Cloud探索；本代理仅trace、不修复。建议修复至少保证每次标题进入请求至完成单次生命周期、非title的play回调不重建世界，且修复后复测原始公开触摸路线。无需先改探索业务以掩盖重复启动。

完整原件：run.py、instrument.py、diagnostic.patch、main-original.gd.txt、两次导出日志、driver.log、result.json、yard/outside/walked PNG。临时工程与导出保留在/dev/shm供复核；没有将大包复制入证据目录。
