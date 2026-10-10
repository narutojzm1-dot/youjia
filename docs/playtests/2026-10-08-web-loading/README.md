# Web加载停滞与完整资源缓存 — 实际证据

Owner CODEX-LEAD-ASSISTANT；用户本地会话稳定卡约50%反馈，#606。修复[PR609](https://github.com/narutojzm1-dot/youjia/pull/609)最终头`7ae8f898e8ebadf238ab30551b5e9f6a4d7bbf35`，合入主线`7ed6cc0d7b3e56fbe18c04cf223f7ebd5370cf14`（2026-10-08 23:24:50 CST）。本目录只存证据，不包含大PCK或修改玩家存档的脚本。

## 复现与最后候选

- `public-baseline/probe.json`：真实公开070ae5a，无扩展Chrome154。WASM完成后PCK停在21,203,344字节，170秒仍未启动，无pageerror；与用户44MiB停滞不是同一百分比，但同属下载无新数据。
- `loading-range-result.json`：真实公开PCK Range请求206，返回1MiB与正确总长，无编码。
- `public-recovery-candidate/result.json`：浏览器仅换候选加载壳，真正从公开070服务器读资源，实际自动恢复，首帧118.507秒。属于未部署候选，不是修复版已公开。
- `public-bootstrap-stall/result.json`：完整缓存增量候选另次公开线路，在存档JS依赖下载阶段0字节等到250秒，未进入WASM/PCK恢复。该失败保留，后续追加60秒模块就绪上限和迟到启动防护；不能拿本次失败宣称资源缓存已经验证上线。
- `final-browser/result.json`：原生官方Godot4.7.2 Windows导出的最终7ae8f89候选，PCK51,493,512字节，SHA见JSON；真实Chrome154普通输入。源基于070ae5a，CI拟合并主线整体检查另列。人为让首PCK传1MiB后停滞，20秒恢复从1,048,576继续；首帧26.063秒。正常点击进小院、自然出门和返院后，旅程提交水位1及背篓在重开保持。两次重开首帧2.233/2.227秒，没有新的PCK请求，正向pageerror为空。新上下文收到故意错误206范围时失败信息可见、无首帧（`invalid-range-blocked.png`）。这些耗时是此环境实测，不代表所有玩家网络或物理手机。

## 检查与原始失败

[CI37796077076](https://github.com/narutojzm1-dot/youjia/actions/runs/37796077076)完整拟合并树验证及Web导出通过，原始日志`loading-ci-7ae8f89.log`。三次一次性本地发布测试与11项保留策略测试通过，Node恢复/完整缓存/模块及Host首帧门禁通过；7bf542d日志对应缓存查找增量，最后保护已完整缓存的取消增量同样在完整最终CI中验证。

`loading-browser-7ae8f89-validated.log`对应最后实际浏览器全部通过。其他`loading-browser*.log`保留脚本调试失败：最初误写schema_version；对普通大文件HTTP缓存的固定请求数假设失败后新增可选CacheStorage；负向脚本变量名错误；异步等待/根探索记录形状判断错误使尚未完成返院的快照被误比（重开会安全完成该在途行程）；刻意马上断流时Chrome可能未先交付前缀，改为真实闲置故障再检验错误Range。最终脚本改用Python循环只读Host当前记录等实际状态，不注入玩家状态、种子或存档。不能将上述测试工具失败冒称游戏存档损坏。早期部分临时控制台输出没有单独恢复成文件，聊天中保留，不伪造原始日志。

`verify-loading-candidate.py`保存最终执行脚本。它使用独立新浏览器上下文、只读IndexedDB记录观察、普通鼠标输入；故障只作用于测试HTTP服务器资源响应，不作用于玩家存档。CacheStorage专用资源库与SaveHost数据库独立。截图保留原始像素；`sha256.json`按实际文件字节生成，Git记录再复核。

修复已合入但本证据提交时Publish37800569153仍在队列，正式公开验证尚未完成；后续PR/发布记录会补准确manifest/PCK/引擎与模块哈希、普通在线启动。Leader主持日版本，不把候选、合入或此目录当正式日发布。近郊#565、PR586/604和夜景/音景未完项仍保留，不以加载修复宣称总目标完成。
