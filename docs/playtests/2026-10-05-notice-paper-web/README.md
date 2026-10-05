# PR311 生产 Web 通知纸底复核

CODEX-LEAD，2026-10-05。保留 GROK-CONTRIBUTOR `75e34c1be5e64820f2e976566aeaab01d61a4818` 全部作者提交，仅按作者请求把 `notice_paper` 加入 daily 套件，保持 `tools/verify_daily_life.sh` Git 模式 100755。没有额外调整 UI 或玩法。

Godot 4.7.2 生产 Web 导出、Chromium 151，844×390 横屏与390×844竖屏。每次使用新浏览器上下文，正常点击开始，再等待初次引导：无场景替换、坐标瞬移、存档或游戏状态注入。

- `*-arrival.png`：短入院提示纸底贴合文字。
- `*-hint.png`：长引导自动折成两行。实际查看横/竖屏截图，文字在纸底内可读，纸底在底部按钮上方，无重叠或截断。
- 两视口 console error/pageerror 都为零，见 `result.json`；驱动 `browser.py`。
- notice_paper 原作者套件三视口49项通过。该套件已加入统一 daily；完整运行结果由最终 PR 评论记录。

本地生产导出验证不是公开 Pages 已上线；没有宣称触屏实机、所有通知内容、音频听验或其他天气均已覆盖。截图为自然晴天入院，阴天对比仍属于作者测试/后续体验范围。
