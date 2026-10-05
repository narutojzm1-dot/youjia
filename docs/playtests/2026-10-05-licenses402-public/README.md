# PR402 正式公开 Web 许可外链无回退烟测

PASS 本次普通鼠标Web路径；不代表原生许可对话框resize已在网页体验。正式源 `82f902a0f22f50032bff9acbe542d0f1953ae684`，操作前后实时manifest完整SHA与HTML `game-82f902a`均严格匹配，未混入前源或后续Cloud构建。

全新Chromium context，CSS568×320/DPR2，headless/SwiftShader。普通标题点击许可按钮，实际打开open-source-licenses.html（网络HTTP200、text/html，正文含Godot），关闭该页回到原标题，普通点击进入院子成功。已亲看license-html.png、returned-title.png及yard.png，title.png保留初始画面；run.py为原始驱动，result.json包含输入时间、前后manifest/HTML、真实网络响应与错误。

独立HTTP读取正式game-82f902a.pck，200，27,080,504字节，SHA256 `eb9cbbc9bbc59e1f5d704692a64e71161360834e1b39781e44029e567eb4a442`；同页实际引擎PCK网络亦200。未声明本QA核了raw分支/十模块，它们由Leader另核。driver实际exit0，pageerror及console error收集数组为空。

没有业务状态注入，没有触摸、真机、原生窗口、听验或全游戏覆盖。PR402运行变更针对原生许可弹窗，此处仅核既有Web外链分支没有回退；四张原图和原始JSON可按原字节归档。

## 合入、发布与证据归属

原始公开体验由 review304 完成，review301仅归档；本段为归档补充，其他原件按 original-copy-verification.json 逐字保留。PR402最终 `80238c32abfe7feffe2c5361ee1220a98205c65a` 获[独立终审5997465923](https://github.com/narutojzm1-dot/youjia/pull/402#issuecomment-5997465923)，合入 `82f902a0f22f50032bff9acbe542d0f1953ae684`。审核原件为 final-independent-review.md。

[Actions37332039893](https://github.com/narutojzm1-dot/youjia/actions/runs/37332039893)与[Pages37332724280](https://github.com/narutojzm1-dot/youjia/actions/runs/37332724280)均success，Pages gh-pages提交 `25e7f1880a67b852f01e8381c16867d264ab81a3`；原始运行响应为 actions.json、pages.json。Leader于2026-10-05T15:26:53Z实际核验公开manifest/HTML/PCK与十模块，公开/raw/source一致，见 public-release.json。公开PCK 27,080,504字节、SHA256 `eb9cbbc9bbc59e1f5d704692a64e71161360834e1b39781e44029e567eb4a442`。

原生小窗124项、X11真实指针/同窗缩放及完整daily、候选Web导出见[既有集成证据](../2026-10-05-licenses402-integration/README.md)。原生修订在候选X11体验，本次正式Web只是既有外链防回退，不能用Web图代替原生窗口验收；不同构建PCK即使长度相同也不能混用哈希。

本归档基线 `0c7f5d7283cdfd2412205b53653468c59ba3b544` 已包含后续Cloud410底图改动；本目录实际公开证据只属于上述82f902a，不为410背书，不覆盖其源码或台账。
