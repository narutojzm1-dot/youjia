# REQ039 新照片快门行暖纸片：集成与验证

Agent-ID: CODEX-LEAD，接收GROK-CONTRIBUTOR [PR461](https://github.com/narutojzm1-dot/youjia/pull/461) 原提交 `742b293cc3e252f1fd7b46aa07333350155108cc`。基线 `9623ba22c8edc564e5c89dc6b0171324e9230764` 已含禁用按钮、相纸衬底、完整daily完成门禁和稀疏PR CI。只改PhotoArrival快门行暖纸底，保留原作者五文件和真实祖先；补永久daily唯一入口及准确正计数完成行，Main和其他Owner在途范围不改。

## 实际原生与导出

本轮执行源 `fd887ff8691b41edba305ab946c43df082e793f7` / tree `382fc30536973f2809641a36fdc3a67fd20b145c`，Godot `4.7.2.stable.official.ed1daf0bf`。独占引擎窗口内顺序执行，所有真实进程 direct exit 0；[process-results.json](native/process-results.json) 记录命令、时间、退出码、完整日志哈希。

- 精确专项 `[photo-arrival-shutter-paper] PASS: 1290 checks`。
- 完整 `verify_daily_life.sh`：75次启动 = 1次import + 74套件，含新1290、相纸550、禁用按钮4400和已有强完成门禁。
- 50个原包装器受控案例与新完成格式9个受控正反例通过；明确使用fake executable，不冒真实引擎。新例含正确1290、最小正数、零、负数、错套件、缺方括号、错误后缀、空输出、成功后ERROR。
- Web bundle retention、storage module publish 两项Python检查与Web release导出均 direct exit 0。

原始 [specialized-engine.log](native/specialized-engine.log)、[daily.log](native/daily.log)、[export-engine.log](native/export-engine.log) 全量保留。`native/source.json`、`native/code-inspection.json` 及结果内嵌source的prepared/未启动/pending字段是执行前范围快照，实际执行事实以带时间的process结果为准。作者旧基线65失败与未上传PNG仍仅为作者报告，不称本轮已经重做或看过。

候选entry `index`，源同上；PCK **27,090,652 bytes** / SHA256 **`6f84caeb3dc92d6d12a91f39f6cc766dcc521a26bdb70b2f8c99063384eb73a3`**。十个外部 `web/save/*.mjs` 与许可页按同一Git blob补齐，[candidate-release.json](native/candidate-release.json)绑定所有文件。候选不是公开Pages发布证明，独立普通浏览器已由 `hotspot36_qa` 于23:20:14—23:23:49 UTC完成，driver exit0、全部context/browser实际关闭，见 [QA报告](browser/README.md)、[源绑定及执行结果](browser/result.json)、[实际输入](browser/inputs.json)。

## 普通浏览器覆盖

同一浏览器内两fresh context严格close→new串行，仅普通鼠标；390×844与568×320分别从标题入院，轻抚近羊自然产生首照，见到快门文字暖纸底与完整照片，自然退场后纸条与相纸均消失，普通相册可见同一羊照片并能合上回院。没有内部play、状态/存档/语言/时间注入；无pageerror、console error或driver_error。

37张完整PNG、连续抓拍时序、两份只读相册DB、4次manifest/HTML/PCK/十模块/许可页前后HTTP绑定与驱动全部归档。QA目录54文件13,574,231B，53条 [SHA256SUMS](browser/SHA256SUMS) 核验并复制后逐字节一致。普通截图时序不冒精确帧时间；只读current各自generation2与sheep_pet_gentle支持相册可见证据，不声称两个fresh profile完整存档相同或完整恢复已验。

短横本样本纸条覆盖目标提示纸片右半区域，但“目标：窗台花箱 / 看看花箱·空格/按钮”在左侧，完整显示帧没有被新纸条盖字。长提示没有覆盖，不扩大为所有HUD同时清楚。生产界面没有用户可用的英文/减弱动态开关，本轮没有为测试新增或调用内部状态；这两项仍仅为原生夹具覆盖，不冒普通Web。

导出完成后归档并只恢复自动.import、移除有对应tracked脚本的自动UID；清除本repo ignored `.godot`，wasm与冻结旧导出逐bytes/hash/mode核同后同FS硬链接，以降低下一浏览器峰值。未删除源、PCK、原图或日志；旧导出和本次候选此后均冻结不得再export。详见 [engine-release-cleanup.json](native/engine-release-cleanup.json)，资源payload硬链接另有逐文件清单。

## 覆盖边界

- 真实专项已核对整行 `[photo-arrival-shutter-paper] PASS: 1290 checks`，完整daily实际74套件+1import=75次启动，保留mat550、disabled4400和既有完成门禁。新登记受控正反例明确使用fake executable，不冒Godot。
- 新suite的照片由固定seed、holiday_day、debug_place_player与debug_force_rule(duck_pond_chorus)生成，是格式真实的状态夹具，不是正常游玩触发。`Tween.custom_step`和直接`refresh_locale`/root.size用来测属性/布局；主线Main已有locale_changed→PhotoArrival.refresh_locale接线。普通Web后续独立用鼠标/键盘自然拿到照片，不能用这些内部调用冒端到端。
- 对比度只按代码RGBA在黑/白/深木/浅木底上做sRGB混合公式；不冒像素实测，淡出途中也不保持静止文字同等对比承诺。是否遮住目标提示、文字断切及纸条自然程度，需完整Web画面核验。 行框位置尺寸不变，但从默认上对齐改为垂直居中，字的基线会移动；不声称字像素位置不变。静态预审识别短横屏纸片可能与目标提示区域重叠；普通候选本次实际覆盖纸片右半区域，而短文案在左侧没有被盖。长提示/全部HUD未覆盖，不能扩展为所有目标文字始终同时可读。作者另一夹具的文字叠压报告保留为作者报告，不混成本次普通路径实见。
- 普通候选实际仅390×844与568×320、中文、正常动画，按上述原件限定。英文和低动效普通UI未覆盖；没有注入时钟、延长时长、暂停动物制造证据。未覆盖精确动画时长/完整曲线、真机触摸、听验、全部DPR、无障碍与全部重叠控件输入穿透。
- 新目录导出，不写入任何冻结旧export。对与冻结soft455源完全相同的不可变二进制资源payload逐Git blob/bytes/SHA/mode核对后同FS硬链接，只用于降低占用；不链接.import、脚本或配置。本切片绝不修改资源，未来修改须先breaklink。清单在本轮外部原始记录，后续验证归档。

原始下载HTML尾空行及自动.import差分上下文按原字节保留，不为消除空白提示清洗原件。最终代码/测试/工具/台账diff检查只排除确切下载HTML与原import.diff路径；全量提示另留日志。

## 最终集成基线

最终提交保留已验候选源 `fd887ff8691b41edba305ab946c43df082e793f7` 和最新main `b300da74bf157de3f152e63331096cb1eb28b3f7` 为真实祖先；原作者742b同样可追溯。最新main相对导出时基线仅workflow/docs变化，全部保留；本切片生产、资源、脚本、测试、工具、Web及根元数据与已验fd887ff相同，后续只加证据/台账，不冒重新导出。最终独审、远端CI、合入和正式Pages后验另按真实结果记录。
