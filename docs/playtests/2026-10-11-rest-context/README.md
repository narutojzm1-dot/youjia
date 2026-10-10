# #700 休息来源与餐次疲劳验证

基线45673209c8e88b4f6a8320cb9bf4d1020de53bc6，CODEX-LEAD，Godot4.7.2 Windows隔离存档。

rest_context_suite 43，meal_ledger_suite 72，house_sleep_suite 154，regional_clock_suite 92，全部0失败。新回归使用生产Main/World及SaveStore：受控将时钟推进至跨日，确认前不乐观展示疲劳，确认后保存awake；三餐真实写入0/1/1，重读不清除；真实睡眠事务恢复sleep并使下一早餐获1。原房门进入/睡眠/起身完整回归保持通过。故障注入沿真实SaveStore+协调器，unknown分别解析父快照/新快照，日期和休息来源一起改变。

这些是受控原生运行与存储回归，不是普通浏览器等待整夜或实体手机体验。本片没有玩家可见新UI，气泡/做饭导演/自主劳动尚未接入；work_speed接口尚未被劳动执行器消费，不宣称游戏动作已减速。

附烟囱PR723最终8ae4e0a67e6c1155260b80705e544a2187f53549独立套件编译失败诊断；未修改Grok分支。

最终补查：旧原生set_holiday_progress/set_yard_progress同样同步休息日号，保留原有显式赋时的边界行为；回拨不会清除既有疲劳。生产异步进度仍保持单调。新增4项回归，最终共361项通过。
