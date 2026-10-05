# PR336 正式异步存档接线验证

Owner CODEX-LEAD。2026-10-05 实际连续执行；候选PR336，尚未公开发布。说明和接口见 [架构契约](../../architecture/production-save-integration.md)。

## 实际覆盖

- Godot4.7.2完整daily最终退出0（`daily.log`）：原有验收保留，新增异步测试等待实际flush，各独立suite用独立profile。修复真实“返回首页/重新开始未保存半日进度”；原坏主好备恢复后可继续保存24检查保留。对应代码tree与PR336修订4a267129一致，main后续334/340资源保留实现也已整合；新增native故障修订另列结果。
- 导出与Web：localhost8140 的export4，真实Chromium鼠标/触屏浏览器环境；不是实体手机。主流程未注入世界/相册状态。脚本里的绝对路径是当次执行环境，复跑需改成自己的URL/输出目录，依赖Playwright和Chromium。
- `natural/`：真实走进院子、羊交互、生成照片、翻册、暂停→回门口→确认，回标题再进院，实际关闭页面并在同一browser context新建页面；照片和题词严格一致。只存在新Host库，没有新建旧/userfs写者。截图已由执行QA和Leader查看。
- `migration/`：用真实旧IDBFS v21 FILE_DATA构造受控历史来源，包含特殊空白、未知字段与超安全整数的原文。正常提交/重载不改原始seal；独立旧页面实际transaction改变旧主档，新页面发现分歧，真实下载包含current/初始seal/当次旧源原bytes，继续不覆盖旧库。坏JSON主档+好备份启动；未来version999明确停止，不生成空current。这些是受控来源，不冒称真实用户旧档抽样。
- `mobile/`：390×844 DPR3真实下载/继续；纸面UI无裁切，继续后标题可用。异步导航最终以15秒观察确认；早期2.5秒按钮灰的截图不判成功或卡死，也不将此等待当性能指标。
- `fault/`：正常产生照片时只对含album的实际IDB事务注入一次abort。未知状态保留旧gen1及intent；第一次实际UI重试resolve至旧parent；第二次重试gen2/3尚无照片时提示仍显示且按钮禁用，gen4照片confirmed才消失；实际关页重开仍保留。是受控真实transaction中断，不是物理断电。修复前“普通院子写先成功就隐藏提示”的失败结果不计通过。
- 浏览器pageerror均为空；自然流程还保存console日志。

## 门禁与边界

独立review已两次REQUEST CHANGES；前三项原生来源守护/snapshot-token/绑定问题已修，第二轮坏主清理后tmp失败恢复链已由40e64eae修复，新增真实故障矩阵后200 native、24恢复、80候选、9过场检查通过（`native-final.log`），仍待新最终SHA独审，不能用上述通过掩盖该阻断。最终批准/合入/公开manifest/PCK以PR评论为准，本文不预告成功。

native之外的Web runtime在上述浏览器export4与修订4a之间唯一新增防线是直接_start_holiday也拒绝未解决的保存问题；实际菜单确认已具备同样保护。最终代码再次导出通过，重新执行自然回首页/关页恢复的结果另列。测试没有覆盖Safari、实体手机、真实断电、容量上限全部旧档、主观声音舒适度。非照片unknown已恢复后提示可能需第二次重试全量保存，是已知保守UX；不能简单在任意confirmed后隐藏。探索PR322/342自己的新增方法仍须由Cloud适配异步接口，父单#149/#150不因本切片关闭。

发布模块fixture实际在临时bare remote连续发布两次，HTML入口、相对导入、全部模块原bytes/hash和旧模块保留通过；资源实际发布时间保留11项通过，含新main PR340 rename规则。无真实origin试发布。

最终源13230b6（游戏源码hash见final-source.json）重新Web导出并重复自然照片→首页→重新入院→实际关页重开，通过；`final/`相册/照片数据严格相等，只有新Host库，pageerror空，标题/重开相册由Leader亲自看图。该次只覆盖自然路径；前述受控迁移/abort仍准确标作export4。
