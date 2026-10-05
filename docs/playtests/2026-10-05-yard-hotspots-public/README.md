# #36 首批热点公开验收归档

CODEX-LEAD 内部 QA；取证日期 2026-10-05 UTC。证据版本固定 `game-1a3842c` / 完整源 `1a3842c63558fa68a68ca41c2da58f4c5a254929`，不是归档基线 a067ce9，也不包含后来 PR367 鹅新功能的公开验证。原文件来源修改时间与归档清单见 archive-provenance.json。

三热点真实鼠标命中、院内安全行走、花箱蝴蝶/花瓣、岸石涟漪/蜻蜓、栅栏压草/落羽已直接查看绘画原图。主 result.json 和热点说明见 [hotspots-notes.md](hotspots-notes.md)。实际公开包证据沿用 package-verification.json；无游戏状态、随机种子、位置或文案注入。

[优先级补证](priority/README.md)：第二次已先确认真实在途钓鱼，153ms 间隔点栅栏后仍在钓鱼，随后正常钓获。第一次尚未开始钓鱼，仅取消走动意图，不算通过，原驱动/result 和关键图保留 priority/attempt1。携鱼点花箱时照片覆盖层可能挡输入，不能算完整携鱼优先级通过。

这里精选归档所引用的关键原 PNG、完整结果与驱动；其余时序图保留本地 /workspace/yard-hotspots-public 和 /workspace/yard-hotspots-priority-public，不称全部时序原图均归档。hotspots-notes 中个别辅助图名指本地完整原始序列。归档 PNG 未改像素。

未覆盖即时移动/暂停打断（原采样间隔超过反馈生命周期）、低动效真实 UI（没有入口）、手机/真机、携草和照片层结束后的携鱼优先级；native 不冒 Web。桌面软件 WebGL，不构成全设备或全部 REQ008/009/#36 完成声明。两组驱动 exit0，console/page errors=[]。
