# REQ038 暖纸按钮禁用态集成记录

Agent-ID: CODEX-LEAD。按作者 [PR455](https://github.com/narutojzm1-dot/youjia/pull/455) 明确请求与 [6003991606 接收](https://github.com/narutojzm1-dot/youjia/pull/455#issuecomment-6003991606) 集成。基线 `a0bb75e38e59032a6df72a2122af4403c3c3e816` 已含 PR454 相纸与 PR452 完成门禁；原作者 `c79237181d76ab0929952c94b29867dc468425c8` 保留为真实祖先，五个原文件逐字节保留。生产仅 `Main._soft_button` 禁用主题和三个颜色常量，原有禁用时机、文案、尺寸、圆角与行为不变。

## 构建与原生证据

本次真实 Godot / Web 导出源为 `910bdec3fe7bf07833d6b9ccb720f57a5332880c`，tree `9b47ef3a4a78a9ca2cab285e93772b5a9540e381`。引擎 `4.7.2.stable.official.ed1daf0bf`。源中 `native/source.json` 及 `validation-result.json` 的嵌入 source 是执行前保存的范围快照，其中“prepared / 未启动”只描述准备阶段；实际执行状态以带起止时间和直接退出码的 `process-results.json`、日志及结果为准。

| 执行 | 实际结果与证据 |
| --- | --- |
| 引擎版本、import | 均 direct exit 0，版本和 import 原始日志保留 |
| 专项 `soft_button_disabled` | 22:23:52—22:24:00 UTC，精确整行 `PASS: soft_button_disabled 4400 checks`，direct exit 0；空相册条件分支计数在本轮完整执行 |
| 完整 `verify_daily_life.sh` | 22:24:00—22:31:08 UTC，74 次引擎启动 = 1 次 import + 73 套件，direct exit 0；内含禁用态 4400 与相纸 550，保留强完成门禁 |
| 包装器受控反例 | 原有 50 例通过；新增禁用态登记的 8 例（正确 4400、正数 1、零、负数、错套件、后缀、空输出、成功后 ERROR）均符合预期。这些使用 fake executable，明确不冒真实引擎测试 |
| Web 保留与存储发布工具 | 两项 Python 验证 direct exit 0 |
| Web release 导出 | 22:31:09—22:31:14 UTC，strict wrapper / Godot direct exit 0；四个主文件非空 |

完整退出码、命令、时间和日志哈希见 [process-results.json](native/process-results.json)，原始输出见 [daily.log](native/daily.log)、[specialized-engine.log](native/specialized-engine.log)、[export-engine.log](native/export-engine.log)，受控反例见 [result.json](native/disabled-contract-cases/result.json)。复现驱动保存在 `native/runners/`，其中路径是本轮隔离环境路径，不是仓库产品入口。

原 `.import` 生成变化已按 [generated-import-only.diff](native/generated-import-only.diff) 留痕后只恢复这 5 个文件；36 个自动 UID 的内容/哈希已归档后移除，生产源无自动导入变更。最初预检错误地把僵尸 Chromium 列为活进程，诊断断言失败且外层 shell 继续；随后按 `ps STAT` 排除僵尸确认只有本轮 import、没有其他活浏览器。该预检错误记录在 [preflight-correction.json](native/preflight-correction.json)，未删除或冒成预检成功。它不是 Godot 套件失败；每个真实进程的退出码单列。由于此预检断言，初次 untracked 清单未捕获的缺口也单独保留。 导出完成并释放引擎后，只清除本切片 ignored `.godot` 缓存；在 bytes / SHA-256 / mode / 同文件系统均一致检查后，将两个已冻结候选的 `index.wasm` 硬链接以降低内存占用，未动 PCK、源码或日志，见 [resource-cleanup.json](native/resource-cleanup.json)。两个候选目录此后均不得再次导出写入。 原始下载 HTML 的尾空行和 `.import` 原差分上下文空行保持原字节；全量 `git diff --check` 对这三份冻结证据报告空白，代码/台账检查只排除这三个精确证据路径，不清洗原件或修改其哈希。

## 候选 Web 包与普通操作

候选 `http://127.0.0.1:8455/index.html`，entry `index`。PCK **27,089,276 bytes**，SHA-256 **`ef5c5c9e13037e83fd76a5c6764c35faaf00c4c3b5f34e007459889c4276549b`**。10 个 `web/save/*.mjs` 与开源许可页面按同一源 Git blob 补齐；[candidate-release.json](native/candidate-release.json) 逐文件绑定 bytes/hash/source。此地址只为本轮本地候选，不是 Pages 发布证明。

独立助手 `hotspot36_qa` 在 22:33:37—22:35:04 UTC 完成普通鼠标路径，driver exit 0，context/browser 已实际关闭。一个 fresh context 中先 390×844，随后同页 resize 为 568×320；两尺寸分别从标题点击打开空手帐，逐次点击禁用前翻 / 后翻均仍在空页，点击“合上”回到标题。无 pageerror / console error / driver_error。前后实际 HTTP 下载绑定同一 manifest / HTML / PCK / 十模块 / 许可页，未注入业务状态。

完整 [独立 QA 报告](browser/README.md)、[实际输入](browser/inputs.json)、[前后源绑定](browser/result.json)、[辅助分析](browser/analysis.json) 和 10 张完整 PNG 原件保留。两尺寸共四张禁用点击后原图与对应点击前图逐像素相同；四份只读 current 均 generation=1、album=[] 且完整封套相同，这是无业务变化的旁证，不宣称检查了所有内部回调。文字/边线可辨及窄横屏未截字来自完整画面；标签和底色采样另列，不能扩大为全部页面 WCAG 认证。独立助手档案 25 文件共 3,938,560B，24 条 [SHA256SUMS](browser/SHA256SUMS) 校验全过，复制后逐字节复核一致。

## 覆盖边界

- 原生专项直接调用 `_start_holiday`、`_show_album` 和 `_on_save_state_changed`，覆盖主题值、几何及合成输入。writing / acknowledging / resolving 是存档状态夹具，不是真实写入故障或持久化完成。
- 专项的恢复检查实际调用 `_on_save_state_changed("failed")` 后确认重试按钮可用，不能描述成真实写入成功或提交确认完成。备份恢复页两颗按钮没有列入 14 个现有按钮对象；factory 样式复用不冒该页真实流程逐一验证。
- 不透明禁用底 `#f3e9db` 对文字 `#7a6152` 的 sRGB 公式对比度约 **4.7795:1**；这是代码颜色公式结果，不是浏览器像素采样或全部页面无障碍认证。
- 作者的基线 3042 失败、两次 4400 与 12 回归及 PNG 原生截图保留为作者报告；本轮未重复旧基线，PNG 未在仓库中，Leader 不称已见过。
- 普通有照片的首页/末页、备份恢复、真实存档繁忙、真机触摸、听感、全部语言、缩放与屏幕阅读器未在这次主题切片中新增普通体验证明。最终独立 SHA 审查、PR CI 和线上发布验收在各自真实完成后另记。

## 最终集成基线

最终集成保留候选源 `910bdec3fe7bf07833d6b9ccb720f57a5332880c` 与最新 main `870f4faebd6e28c7314e9db97cb39ae27819eded` 为真实祖先；最新 main 相对导出时基线只变更 workflow / 文档，未改候选的运行、测试及 daily 工具。归档和台账是后续文档变更，不冒重新导出。生产、资源、脚本、测试、工具及 Web 源树与已验 `910bdec` 相同；最终独审与远端 CI、上线另由 PR 记录。
