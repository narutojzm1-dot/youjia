# #771 Web 公告压缩响应修复候选

Owner / 审核人：CODEX-LEAD。基线 main `6612526c6c3fb3465dd6a7a108f8c3e61af0b5a9`，独立于未发布的三餐/成长候选。本记录不表示修复已经合入或发布。

## 公开版本成功范围与修复前失败

- `12-public-eb8b93d-pause.jpg`：公开 `game-eb8b93d` 的暂停入口显示正确版本。
- `13-public-eb8b93d-notices.jpg`：**修复前失败**。公告正文与实际构建正确，但联网状态显示“暂时无法检查更新”；浏览器报 `core/io/stream_peer_gzip.cpp` 的 inflate 条件错误。不是公告正文或整个公开包下载失败。
- `verification.json` / `actions.json`：原公开 source `eb8b93d2e452c468afadd3d91f71893612c19102`、Pages `66b7896557e62aae80e8cbd5fd2eca64627dfc85`，Actions 与双端 PCK 身份核验通过。PCK 为 74,466,276 bytes，SHA-256 `f4483f9aeb6e9640046df2da61ddc76afefea3b9c429bdbbc859d66bb30587a1`。这里的 PASS 不覆盖上述游戏内联网公告缺陷；未重复归档大体积 PCK。

## 根因与改动

浏览器 Fetch 会解压 HTTP 响应，但同源响应的 `Content-Encoding` 仍可见。公告的 `HTTPRequest` 之前使用默认 `accept_gzip=true`，Godot 因残留的 gzip 头再次解压 JSON。修复只在 Web 关闭 Godot 这一层解压；原生继续使用默认压缩处理，8 秒超时、64 KiB 限制、严格版本身份检查及离线公告保留。

官方 Godot 4.7.2 实现依据：

- [HTTPClientWeb 已读回解压后的字节](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/http_client_web.cpp#L145)。
- [Fetch 适配仍传递响应头](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/js/libs/library_godot_fetch.js#L182)。
- [HTTPRequest 按 accept_gzip 和响应头创建解压器](https://github.com/godotengine/godot/blob/4.7.2-stable/scene/main/http_request.cpp#L314)。
- [accept_gzip 官方属性契约](https://docs.godotengine.org/en/stable/classes/class_httprequest.html#class-httprequest-property-accept-gzip)。

## 验证边界

- Windows Godot 4.7.2，独立临时玩家目录，原 87 项加 5 项回归，`RELEASE_NOTES checks=92 failures=0`，退出 0，最终日志无 ERROR/WARNING。
- 新增：平台解压职责、带 gzip 头的已解码 JSON 回调、无效清单与传输解压失败不谎称最新、联网结果不替换本包正文。**这些回调检查不是实际浏览器 gzip 传输测试。**
- 初跑因切分支后未重新导入旧云层而失败；导入后修订负向用例，避免用非法 JSON 故意打印引擎错误。失败与中间日志保留，最终通过见 `suite-final.log`。
- Leader 已完成下述普通 Web 真实 gzip 对照及无效清单降级；本轮不覆盖实体手机、断网/超时传输或修复上线后的公开核验。

## 普通 Web 真实 gzip 对照（2026-10-13）

体验执行人：CODEX-LEAD，使用 CUA 操作普通游戏页面及“歇一下 → 更新公告”。修复后导出锁定 `c8ea3853818ade88d52a8621fda36cd28423ab84`；修复前复用 `b7929dc7b982788ea4126f9f08424770a09050ed` 旧公告候选。两者使用同一 loopback 服务的实际 gzip HTTP 响应，不是直接调用 `_checked()` 的回调模拟。

| 截图 | 真实操作与结果 |
| --- | --- |
| `14-gzip-before-check-failed.jpg` | **修复前预期失败**：旧版本在 gzip 清单下显示“暂时无法检查更新”，浏览器出现 `stream_peer_gzip.cpp:117` 解压错误。 |
| `15-gzip-after-latest.jpg` | 修复后，相同 gzip 服务返回与当前包一致的身份，公告显示当前是最新发布版本。这里的“最新”仅指本地夹具清单，并非生产发布证明。 |
| `16-gzip-invalid-manifest.jpg` | 夹具返回 gzip 包装但 schema 无效的清单，正确显示无法检查；当前包的公告正文仍可阅读。 |
| `17-gzip-different-build.jpg` | 夹具将清单身份改为 `7c785c03bb80c55dc8deaef4eaea8f854548688d`，正确提示线上版本不同并建议保存后重新打开；未强刷，正文仍为当前包。此处身份是测试输入，不代表成长候选已上线。 |

服务记录的查询时间依次为北京时间 12:30:50、12:31:44、12:32:02、12:32:20（UTC 04:30:50、04:31:44、04:32:02、04:32:20）。Leader 的 CUA 记录自 UTC 04:31 起 warnings/errors 均为空；旧页面较早的解压报错按时间隔离，不算修复后报错。结束后夹具恢复正常 gzip 模式。

`web-gzip-verification.json` 保存导出与传输摘要、版本、截图哈希和验证边界，`fixture-transport.log` 是服务端相关响应记录；不包含私人目录。HTTP wire 核对了 `Content-Encoding: gzip`、gzip 文件头 `1f8b`、398 字节压缩正文解成 870 字节 JSON；无效/不同身份输入分别有独立响应记录。导出退出 0，日志无 ERROR/WARNING；PCK 为 74,466,920 bytes，SHA-256 `1279edf45f95ac326671c5c191c32d37f8a8e45071699656083c8c5d32a2e95c`。

此补充只归档已测 `c8ea385` 的证据，不修改运行代码、不升级被测包身份，也不表示 PR 已合入或修复已公开发布。后续上线仍需核对实际发布包。
