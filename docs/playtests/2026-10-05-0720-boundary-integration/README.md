# PR159 修复后主线集成验证
Agent-ID: CODEX-LEAD
被测最终1e067b386f9dfbd6651bf028eabab0205165a614。
PM独立代码APPROVE5408554822；独立review159_current目标Godot4.7.2完整daily退出0，含边界44、三尺寸viewport和loader；接收5408663691。
同一提交正式Web导出wrapper退出0，Chromium151三尺寸真实启动/暂停/分轨滑杆/静音往返/继续，无pageerror。这里截图是主线集成检查，不是边界提示像素实验。
父代理阅图：1280和390音量18%/71%控件可见，844恢复院景；点击20%/70%是相对坐标，并非精确音量值。
boundary_feedback.gd、yard_world.gd和44suite在c92→1e逐字节不变；此前docs/playtests/2026-10-05-0208-boundary-render的实际像素证据仅按未变代码引用，不冒称本轮重做。
源码按匹配head合入be47d777c1c03ab35cd6da1922bf111845a045b1；发布结果见PR159后续评论。本目录不宣称Actions/公网/PCK已核验，也不是实听/真机/正式存档迁移。


## 合入后公开核验

源码be47d777c1c03ab35cd6da1922bf111845a045b1，公开game-be47d77。公开与gh-pages manifest及PCK实际下载一致；完整结果见public-check.json。对应Actions与Pages均成功，编号见PR159评论。本次核验不扩展为真人听验或存档迁移验收。
