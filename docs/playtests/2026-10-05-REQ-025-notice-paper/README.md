# REQ-20261005-025 底部通知纸片：渲染前后对比

- Agent-ID：`GROK-CONTRIBUTOR`
- 基线：渲染在 main `ed5f1d7d6b025ebb7290bfd470f89aa7ac482a4b` 上做；分支基于 main `c12a3d4750c974a4a34f42c78a2ded89bffefe6b`（中间合入的 #302/#304/#306 都不碰 `scripts/main.gd`，#306 只改文档）
- 引擎：Godot 4.7.2-stable（linux x86_64），`xvfb-run` + `--rendering-driver opengl3`，原生实际渲染、读 `root.get_texture()` 存 PNG。不是 Web/公网包，也不是真机。
- 脚本：`render_probe.gd.txt`（短通知 `notice.fishing.miss`，晴/阴，1280×720 与 844×390）和 `render_probe_long.gd.txt`（长通知 `notice.first_hint` 18px，1280×720 与 390×844）。改名为 `.gd` 放进 `test/` 即可复跑；它们只调用 `_start_holiday`、`set_weather`、`_show_notice_key`，不瞬移、不改计时。

## 看到的

| 场景 | 改前 | 改后 |
| --- | --- | --- |
| 1280×720 阴天“跑了。没关系。” | 棕字压在池边石头和花丛上，几乎认不出 | 字落在贴合的奶油纸片上，清楚可读 |
| 844×390 阴天同一句 | 同样糊在草石里 | 同样清楚 |
| 390×844 阴天首条长提示（两行） | 第二行贴到“翻开手帐/阴天”按钮顶边 | 纸片向上长，底边离按钮仍有空隙，按钮字完整 |

晴天两个尺寸结论相同（前景就是同一片草石）。

## 关键帧

六张裁切 JPEG（改前/改后各三）留在测试机，SHA-256 见 `keyframes.sha256`。本通道只有文本文件 API，无法提交二进制；任何人用上面两个脚本即可在同一 main 上重新渲染。

## 回归

- `test/notice_paper_suite.gd`：三视口 49 项，`failures=[]`，退出 0。对当前 main 的 `scripts/main.gd` 运行：12 项失败（预期，证明 suite 真在测这件事）。
- 完整严格 `bash tools/verify_daily_life.sh`（本地临时把 `notice_paper` 挂在 suite 列表末尾，提交里不改该文件）：基于 main `ed5f1d7` 退出 0（日志 SHA-256 `9a4aea1ad357b9d3d06814f326cc0db11ecc9b6fab29593f572c534f482bcfce`）；rebase 到 main `3ed47d7`（含 #302/#304）后再跑一次退出 0（日志 SHA-256 `fb50d289426cc415c7bc02ec2c5999be14b5c374def30bda57b28f96256c88ae`）。两次都有 `notice paper suite checks=49 failures=[]` 和 `[viewport] failures=[]`；日志留在测试机。
