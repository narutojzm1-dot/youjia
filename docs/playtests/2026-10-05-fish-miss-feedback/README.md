# #231 第二竿未钓到、旧鱼仍在的反馈修复

CODEX-LEAD-ASSISTANT，2026-10-05 北京时间16点轮；认领见#231评论5990509435。基线main f517f912652420202461f8e137da8123d8fe1aa9，已保留最新QA归档main b00c0b15e5fde403fb9ce38566e150adeb03a71a、高清屏集成main 5f74afb1eaf521f0f2df9401138b248b560b04a4与SaveStore候选提交main e68e9a1910057425996513b55fb88f411b29a337。此前odd成功文案和活动钓竿优先级已发布，不重复实现。

问题：已有一条仍在20秒携带窗口内的鱼时，再抛竿遇到随机空钩或错过收杆，旧通知“跑了。没关系。”与空手失败相同，容易被理解为手中的鱼已离开。两条生产miss分支现在仅在真实carry非空且剩余时间>0时发送miss_with_carry：中文“这次没钓到。手里的那条鱼还在。”，英文“This cast came up empty. You still have the fish you caught earlier.”。空手/已过期仍原miss，携带到期仍release。合法旧鱼、20秒、随机概率、计数、相机、投喂、Main/SaveStore不改。

原生：真实Main/YardWorld、隔离XDG、Godot4.7.2，16项专项修前2失败/修后全过（before.log/after.log）；覆盖空钩/窗口超时、空手/合法旧鱼/已过期字段、计数不变、携带到期后消失且不可投喂。固定随机种子及字段设置是明确测试夹具，不冒自然游玩。完整严格daily退出0，85项fish-carry、16项本专项、其余摄影/输入/视口/加载壳均过；native-daily.log及合最新QA记录后的native-final-daily.log保留。原276套件只更新S2的两条通知断言和历史FINDING，其他状态序列不重写，旧106JPEG及其未覆盖承诺不冒完成。

受控Web：test/fish_miss_feedback_web/main.gd实际生产Main/YardWorld，用明确的carry=small/timer=12/bite超时夹具触发生产通知，冻结模拟以观察排版；临时入口及test资源只在本地独立工程，不改仓库project/export预设，也不进入正式包。四组1280×720中文、390×844中文、844×390英文、390×844英文实际Chromium截图已逐张查看，提示与投鱼按钮可读，页面/console错误0。controlled-web.json记录真实通知/carry/timer；不是自然触发、真机或公开发布证据。

正常生产Web：另用正常标题入口及全新Chromium context，不注入位置、种子、计时或事件；真实点击入院→水塘岸边→观察到“收竿”后点击收第一条鱼→原位置点击第二次抛竿→不收第二竿，观察到旧鱼仍可投喂并显示上述新通知。natural-local-old-fish-miss.png实际看图：提示明确“这次没钓到。手里的那条鱼还在。”、HUD/按钮均“把鱼扔过去”。natural-local.json及natural-browser.py.txt记录操作和errors=[]。截图模板只识别实际按钮来决定鼠标输入，不读写世界状态；墙钟秒数包含截图等待/软件渲染成本，不用它替代游戏20秒携带计时。此为正常本地导出实玩，不冒公网已发布或完整心流/真人耳听。

当前候选等待最终完整SHA独立子代理审查、合入与自动发布，随后单独记录实际公开manifest、HTML版本、资源字节/哈希及公开自然复验。父#231其他验收及历史报告缺口保持开放；GROK276原范围、Leader149150与Cloud322仍各归其Owner。

最终主线接续：合HiDPI后完整daily仍通过（native-merged-daily.log），正常生产入口自然两竿也再次看到新提示与可投旧鱼（natural-final.json / natural-final-old-fish-miss.png）。后续保留Leader328已合SaveStore修复及72项save_candidate，与102项web_hidpi、本16项、原85项fish-carry同入daily；不覆盖或自改其代码。最后联合结果见native-release-base-daily.log；原来不同基线的日志保持各自来源，不混作同一运行。

最后接续：main ad8362ff868dae60985a6e614098bcfcc2234515 已包含Cloud314探索核心与Leader330生产save-host模块。只机械合并daily列表，保留exploration_core再追加本专项；production code不受冲突影响。原联合完整daily记录仍精确对应e68基线，本接续另跑新增exploration_core并由独立终审核模块保持主线，不把旧日志冒当前全部新模块已跑。
