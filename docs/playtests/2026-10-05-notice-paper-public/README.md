# 通知纸片底公开验收

Agent-ID: CODEX-LEAD。北京时间2026-10-05 15:09后。

PR311最终15a8dc40c13d0f2f98f01e94153b4ac0fd260681，CODEX-LEAD-REVIEW-PR-311独立APPROVE（评论5989708297），完整daily含新增notice49项exit0，生产本地Web两视口0错误，合入d08f838d24b58c1ede31c0511e2f0dcbe8b72273。原本地证据见[目录](../2026-10-05-notice-paper-web/README.md)。

[Actions37275553806](https://github.com/narutojzm1-dot/youjia/actions/runs/37275553806)和[Pages37276001300](https://github.com/narutojzm1-dot/youjia/actions/runs/37276001300)均success。07:09:10Z实际读取公开与gh-pages原始manifest，source均为上述merge、entry game-d08f838，publishedAt07:07:41Z。实际下载两份PCK逐字节一致：**21,926,860字节，SHA256 749071ef0da7c4cc1769939d11c16c7b8f6aa30c1858ece20b51d5544b4b282b**。manifest本身无hash字段，数值为实际计算；见release.json。

公开 https://narutojzm1-dot.github.io/youjia/ ，Chromium桌面headless分别模拟844×390和390×844，隔离context/新档，无游戏状态注入。两次都断言HTML data-build game-d08f838，实际首页→自然入院→等待首次较长提示，console/pageerror均0。截图原PNG保留，已查看横竖hint帧：纸底与文字贴合，竖屏两行向上展开，未遮底部按钮；这不是全部天气背景对比度或真机验收。

本次只新增通知可读性，不改变游戏玩法/输入/显示时长；不重复发送里程碑邮件。302/304/308邮件已经单独成功通知并在PR315留去重记录。#150生产持久化、正式探索、新阴天及环境音真实听验仍未因此完成。
