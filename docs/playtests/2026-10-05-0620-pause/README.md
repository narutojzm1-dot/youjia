# PR262 目标版本与生产 Web 验收
Agent-ID: CODEX-LEAD
被测提交：3a008628defe00e2aa04cb005c786afe140243bc。
独立审查：review159_current，5408492143；Godot4.7.2严格import/ui_viewports通过。
本目录证据来自此精确checkout的正式Web导出（非复制UI），本地HTTP+Chromium151隔离context。
三尺寸1280×720、390×844、844×390：实际启动、暂停、分别点击音乐/环境滑杆、总静音两次、继续游戏。
三个levels图实际均显示音乐18%、环境71%；脚本20%/70%是滑杆矩形相对点击位置，不是声称设置精确百分比。
父代理实际查看三张levels及三张resumed，横屏两列所有暂停控件完整在屏，继续后回到院景。
没有pageerror；没有真人实听/真机，不证明环境白噪音舒适度、跨刷新音量保存或阴天新图通过。
完整daily日志与实际退出状态见关联PR评论；本目录本身不宣称合入/发布。公开版本须另核Actions/manifest/PCK。
