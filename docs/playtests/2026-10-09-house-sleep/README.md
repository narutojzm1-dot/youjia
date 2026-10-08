# #565 入屋睡眠基础验证

Owner CODEX-LEAD；分支codex/lead-house-sleep-565；基线main 1b02f46b69b7046ed000386f6990c7eb5fc3e983。当前开发候选，尚未合入/发布。

新增house_sleep_suite共42检查：纯跨日幂等、准确天气推进、植物条件、旧存档与库存保留、门口行走、牵绳/钓鱼互斥、重复点击、保存确认先于早晨、旧自动保存不倒退、照片灯光兼容，受控拒绝及UI重试覆盖。native host实际确认写入；受控失败回执不冒充拔网线/真实磁盘故障。

相关回归：大动物27、牛羊34、棚门41、照片保存47、照片渲染2471、天气199、天气运行18、过渡75、保存协调86、通用416通过。曾因runner拼错regional_weather套件文件名中断，已改为真实world_weather入口并完成余项，不将启动失败当通过。

capture_house_sleep.gd为隔离原生GPU场景：设置夜间及门口位置，按真实controller阶段推进，保存night-windows/open-room/asleep-dark/morning-return，不能代替自然Web体验。窗灯第一版被全局夜色压暗，已改为夜色后绘制并重新查看。普通Web、最终CI及公开核验另记。

正式门洞纹理assets/holiday/environment/house_open.png来自此前open-door-v2原字节；SHA256 7312ca6b727960c55c62d7188801869a08b1a07ee635bb429e2a5f45e7b52b2f。完整提示及历史候选说明见art-provenance.md，候选说明中的“尚未接入”为生成时历史，本PR已接入并实绘配准。原画不替换整张小院背景。
