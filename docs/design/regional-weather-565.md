# #565 共享时辰与持久天气首片

Owner CODEX-LEAD；近郊表现由ASSISTANT消费。候选未公开验收，不代表雨天、夜景、归棚或睡眠已完成。

`YardWorld.environment_snapshot()` 返回独立字典：`day`、`elapsed`（秒）、`day_fraction`、`hour`、`weather`（sun/overcast）、`weather_remaining`（秒）。一天600活动游戏秒，从06:00开始；暂停不推进，不按离线墙钟补算。Main在探索期间调用同一个`advance_world_time`，不运行隐藏小院动物。ASSISTANT接入近郊表现前须核对最终提交，不能以此接口已提供冒充近郊画面已同步。

天气每段随机300–1800游戏秒，到期独立随机晴或阴，允许相同天气续段。存档`world_weather`保存weather/remaining/seed/episode；随机序列独立于动物行为随机数，重开保持后续序列。旧存档首次入院默认晴并创建随机时长，立即排队保存；手动天气变化/自然天气变化保存，周期检查仍保留。天气与日期在同一yard事务提交，旧五参数调用不清空已有天气。缺失/非法天气投影为空后走初始化，不修改原始损坏源。雨天暂不入随机池，等待资源和行为实际接通。

验证：175项序列/时长/原生落盘与跨日检查、13项生产Main出院/暂停/返院/重开、75天气视觉过渡和416通用检查通过。最终日志分别为本机`%TEMP%/youjia-basket-check-41f446b8-5a68-46a7-87ac-048cd2931b42`及`%TEMP%/youjia-basket-check-6700d4b7-e8f7-41b1-b2ba-196c65da930f`。原生runtime是受控流程调用，不称普通鼠标实玩。旧照片测试使用的`_weather_timer`仍作为同一episode剩余时长的兼容属性，没有第二计时器。

Web候选已成功导出，PCK SHA256 `0e4cf824a96a16d17621e8ef19c23eab2ff903e6d1406bf3b69a74ee21b2a50e`。普通localhost旧档第2天可入院；长时天气节奏、手机实机和最终公开包仍须验收。运行时未实现新夜景/蛇声/睡眠，不将基础时钟算作全部需求完成。
