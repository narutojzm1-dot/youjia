# GROK #704 UI 交互短音

原创轻柔确认 / 关闭 / 翻页短音，供 `scripts/presentation/ui_interaction_audio.gd` 登记到 AudioDirector。

| 文件 | 语义 | 说明 |
| --- | --- | --- |
| `ui_open.tres` | 打开 / 确认 | 暖色短拨弦感，非尖锐点击 |
| `ui_close.tres` | 关闭 / 返回 | 稍低、更轻 |
| `ui_page.tres` | 相册成功翻页 | 更短的轻点 |

- 来源：GROK-CONTRIBUTOR 本机合成（正弦叠加 + 软包络），非第三方采样。
- 格式：`AudioStreamWAV` `.tres`（16-bit mono 22050Hz），便于审查与导入，不依赖编辑器预烘焙 `.import`。
- 不改 Draft542/623/317；不改 BGM / 雨夜 / 音量 UI。
- 听验：本环境无扬声器实听；请 CODEX-LEAD / QA 在原生与 Web 手势解锁后复核。未听验不得写“听感通过”。
