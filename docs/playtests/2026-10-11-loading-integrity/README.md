# 加载完整性修复与实际公开线路回执（#606）

Owner：CODEX-LEAD-ASSISTANT。本目录接续[最初下载停滞证据](../2026-10-08-web-loading/README.md)，保留失败和成功原始记录。用户070ae5a截图约50%/134秒不是已确认的脚本报错；全新无扩展浏览器也出现资产停滞。`runtime.lastError`属于扩展runtime接口报错，不能确定具体扩展或因果，依据[Chrome官方runtime说明](https://developer.chrome.com/docs/extensions/reference/api/runtime#property-lastError)。

|阶段|准确来源|实际结论|
|---|---|---|
|最初续传/缓存|PR609头7ae8f898e8ebadf238ab30551b5e9f6a4d7bbf35，合入7ed6cc0d7b3e56fbe18c04cf223f7ebd5370cf14|有限自动Range恢复、完整CacheStorage、引擎按字节稳定地址；原公开失败和重试记录在旧证据|
|完整性补充|PR616头c5559c012c9dc4e06a1c2be9a1e243d5789ef84a，合入8c7e925a34062ed025b39ed5d5e74e45b72013f2|完整资源按已发布SHA256校验，允许同一内容弱/强ETag表示差异；错误Range、同大小损坏和坏缓存被拒绝|
|c555本地真实Web|candidate-c555|真实PCK51,508,168字节，首段1MiB停滞、20秒后不同ETag续传，首帧26.601秒；重开3.053/2.938秒；普通出门返院后背篓不丢不重收；0页面错误|
|8c7公开尝试|logs/loading-integrity-public-*.log|系统网络暂停`ERR_NETWORK_IO_SUSPENDED`导致失败，字节核验只有未完成.part；没有完整通过结论|
|10-10首次公开尝试|oct10-initial-public-failure及loading-current-public-browser.log|e9e7292在模块阶段60.005秒超时，尚未进入资产下载；0页面脚本错误，不计通过|
|10-10下一次公开尝试|oct10-public-success|同一实际公开e9e7292，无壳替换，无手动重试；约55.3MiB处自动续传，首帧171.596秒；完整缓存重开4.506秒，小院和原Host背篓一致，0页面错误|
|10-10公开字节核验|oct10-public-bytes/verified.json|e9e72920446705415c9a41da7380ab48fe75664e的PCK、引擎与10保存/2加载模块，共17文件的实际SHA256及Pages Git blob一致；PCK69,558,612字节|

公开字节核验的WASM沿用此前已下载并核过的同一内容，明确`reusedPreviouslyVerifiedWasm:true`，并重新比对当前固定SHA与实际Pages blob；不是声称重新从公网下载WASM。公开浏览器是独立全新配置，真实加载WASM/PCK并由运行时SHA校验后才启动。大PCK和WASM只留本机，不上传本证据目录。

完整性实现使用增量SHA256，分段处理已解压字节，不额外分配一份全量资源。旧缓存缺少已发布hash元数据时重新下载；缓存读出的内容也重新校验。校验失败不交出流结束，不写入坏缓存。有限20秒空闲重试、准确Range边界、完整字节数、Host安装和首帧门禁保持；不把SHA成功冒充玩法存档验收。ETag探针观察到同一不可变WASM压缩全量与identity Range的时间戳字段不同，只据实记录；首次7ed失败未保留头，不能把后来的探针冒称已捕捉首次失败的唯一原因。ETag弱/强语义见[RFC9110](https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.3.3)。

PR616保留Grok PR615原提交，仅补Godot无法推断的String/Dictionary类型。首轮CI37807407882失败和补修日志保留；最终[CI37808463420](https://github.com/narutojzm1-dot/youjia/actions/runs/37808463420)、[Publish37810337924](https://github.com/narutojzm1-dot/youjia/actions/runs/37810337924)及[Pages37811897492](https://github.com/narutojzm1-dot/youjia/actions/runs/37811897492)成功。已跑增量SHA标准向量、填充边界、切片/超512MiB字节计数、内容损坏/缓存/Range测试，以及真实发布脚本与11项历史保留测试。

8c尝试和10-10失败测试曾共用同一本机输出目录，前者result.json被后者覆盖，不能宣称保有8c完整JSON；本次归档按实际文件把该目录标为10-10首次失败，8c只有原始文本日志。完整验证对象以各JSON的实际build/source、原始输入和时间为准。复验没有通过更换壳、注入存档或修改种子掩盖失败。

续传和缓存已公开，但首次网络传输仍慢：10-10实际游戏包加WASM约104MiB解压后，这次线路首帧约172秒，不能承诺所有网络快速或连续稳定。未覆盖物理手机、其他真实线路或所有扩展；本记录不是每日23:00整体发布报告。近郊#565仍active。SHA256.json核原始归档字节，README不在清单内。
