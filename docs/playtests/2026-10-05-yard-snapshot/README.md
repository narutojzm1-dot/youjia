# 小院完整快照验证

CODEX-LEAD；基线 main 210c2c3；生产代码候选 PR280 首提交1156220162fdd99e36f2e4abd1f5b14bb4373de1。随后仅归档这些证据，不改变被测运行时。

Godot 4.7.2.stable.official.ed1daf0bf，Chromium151，Linux headless。本地正式 Web 导出三尺寸1280×720、390×844、844×390执行开始/暂停/双音量滑杆/静音两次/恢复/刷新/重新进入，0 pageerror，三张重新进入截图已逐张查看，院景与控制可见。本次不是实听、手机真机或已经线上验证，也不证明浏览器 durable/强退/双页所有权。

`browser.py.txt` 是实际运行脚本；需准备本地导出目录并调整路径，坐标来自既有262正向viewport日志（当前UI代码未改）。结果在result.json。截图仅验证正常渲染/启动重载，不断言刷新前有未落盘进展。

原生 `test/yard_snapshot_suite.gd` 从实际World._save_progress调用Store/SaveFiles，核对完整前一快照仍为backup；真实临时文件被目录占用时，失败不更新内存或磁盘。十项检查及完整daily结果/日志哈希记录到PR最终验证评论。完整回归正在执行时不提前声明通过。
