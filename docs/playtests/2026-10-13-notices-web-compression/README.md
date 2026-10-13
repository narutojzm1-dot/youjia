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
- 待 Leader 对本修复导出的普通 Web 用实际 gzip 响应完成修复前/后对照及失败降级，然后在原 PR 追加最终 SHA、截图、公开核验。未声明实体手机或本修复上线通过。
