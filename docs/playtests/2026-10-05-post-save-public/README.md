# #350 手帐短横屏修复与生产存档后的主流程回归

Owner：CODEX-LEAD-ASSISTANT。PR #351 / BUG-ALBUM-LANDSCAPE-20261005；父 #40 的功能迭代仍属 Leader。本目录同时保存本轮 #195 输入观察，两个范围不混为一项修复。

## 缺陷与候选

实际公网 `game-55cb7ce` 正常游玩、取得五张照片后，将手帐旋转至 844×390，照片遮住日期题词并越过纸页（`public-before-landscape.png`）。原 PhotoMoment 默认最小 184×184，卡片缩小后实例仍被撑大；低矮页面的文字空间也不足。

仅修改 Main._album_page / _photo_card：相册实例最小尺寸随照片窗口缩放，进入树后再应用窗口尺寸以避开构造时的最小尺寸缓存；低矮宽页将正常字号日期题词、札记放在照片旁，低矮窄页放在照片下。常规纸页仍将题词放在相框内。照片快照、构图、存档、资源、天数标签和探索方法不改。

`test/album_layout_suite.gd` 使用本轮五张真实照片的隔离副本，将日期置为允许的最大 10000 天，并选择合法题词变体；加上仅有旧 ID 的照片和空页。这是受控原生几何回归，不是自然游玩。中英文、八视口（含 720×460 短双页）、同实例连续旋转、页面/文字/照片/导航边界、无覆盖、方形比例及数据不变共 3078 项：基准 main 81d225c 的相同手帐方法失败 271 项；修复全部通过。`native-before.log.txt` 保留原版完整结果；`native-after.log.txt` 为修复套件 stdout 原样片段，原始全日志见 native-daily.log.txt。

完整严格 `tools/verify_daily_life.sh` 在 Cloud #342 的基准 bc213f9 上已过；随后 Leader #353 合入，再于 a936bea68bfb37eea47b00c09e3767af74c72b61 加本切片完整重跑，exit 0，原始输出 `native-daily.log.txt`；另有真实发布脚本的 11 项资源保留测试和版本化存档模块发布测试。首次导入缓存未更新及测试夹具错误已修正，最终门禁从稳定源码重新完整运行；不将中断的早期门禁算通过。

本地实际 Web：先用基准 81d225c 加相同手帐修复，普通鼠标进院摸羊获得照片，进入手帐后旋转；最初点在标题空白的坐标探针未进院，日志与输入记录保留，正确步骤从 `10-corrected-enter-yard` 开始。随后用 bc213f9、再用 a936bea 的最新生产接入分别重新导出，真实关闭重开同一独立本地 profile，历史照片不变、generation 3 不变；1280×720、844×390、700×400、720×460、390×844、360×640 手帐均可读、errors=[]。三张 `local-fixed-*.png` 是最新候选导出的实际画面；`candidate-verification.json` 保存源码/导出包真实 SHA256。本地 Web 为中文，双语几何由原生覆盖；未注入世界/时间/存档，没有将候选当正式上线。正式发布待 PR 终审/合入后补原单与公开资源证据。

## 新生产存档的普通公网流程

独立持久 Chromium profile，真实鼠标/键盘、软件 WebGL。`public-events.json.gz`、`public-commands.jsonl` 和驱动日志保留全部步骤；名字只是输入意图，以状态与截图为准。最初坐标误点暂停后的数次输入无效，07 正常继续后才推进，未误报失败动作通过。

在 game-55cb7ce 实際走动、摸羊、拿草/递草、播种/浇水、正常抛竿并自然钓获。最终五条 album/photo_moments：sheep_pet_gentle、llama_sun_sheep_happy、llama_fed_gentle、llama_overcast_goose_annoyed、fish_first_catch；plant_state=1、planted/watered_day=1、first_fish_caught=true。`public-natural-catch.png` 为普通钓获画面。背景出现阴天后的已有照片兼容观察不替代 Producer #168/#51 的背景质量验收。

实际确认回标题 generation 16；第一次驱动重开等待首帧超时，未算通过（两份失败日志保留）。关闭持久上下文原有页面后，用修正驱动真实重开同 profile，公开版本已更新为 game-3de05fc；全部五张完整照片、日期、种植和首次钓获字段、假期计时逐值相同，generation 16、pending_intent=false、errors=[]。`reopen-comparison.json` / `public-reopen-events.json.gz` / `public-reopened-photos.png` 为证据。此为跨两个正式已发布版本的普通保存/重开观察，不是旧 FS 迁移、容量故障或中止事务验收。

初始正式资源：Actions 37293308869 / Pages 37293814016 success，精确 gh-pages 763b07ba4b7cd90ff5ad2582ad407e96fee8c092；JS/WASM/PCK 及全部 10 个实际 save-55cb7ce 模块 HTTP 200、完整长度、模块 SHA256、Git blob/tree 一致。PCK 22003712 字节，SHA256 18a240270399972993bdac2ef2bc828da72003642df7d7548a667060a56de976。`public-tree-verification.json` 为实际核验，而不是凭截图推定版本。

## #195 输入结果与剩余

普通单浏览器：两轨各 20 次，按住 0/80ms、等 180/80ms 两轮，共 160 次均观察到真实 WebAudio playing 变化；原始诊断与 DOM/RAF 记录分别压缩存档。

同时运行两个软件 WebGL 页面时，第二个实际 game-3de05fc 上 40 次零按住、等 80ms 输入有 2 次未变化：music #16、ambience #2，等到 2 秒仍未变化，starts 也不变。可信 DOM down/up 已到达且后续有 RAF，不等于证明 Godot 收到了按钮 pressed；根因未确认。保留完整 `concurrent-input-result.json.gz` 与复现脚本，不能宣称快速输入全部通过。本 PR 没有修改音频帧守护、资源或状态。

这轮不是物理手机、真人听验、BFCache、容量/离线故障、稀有组合或完整季节体验验收。发现 #350 后整体体验门禁保留缺口，不能因流程能走通就宣布整个游戏心流全过。#195/#40 及资源父单保持余项准确；后续 #195 按已复现输入归因接续。

所有 .json.gz 均为原始 UTF-8 JSON 的 gzip（mtime=0）；可用 Python gzip.decompress 读取。没有上传 PCK/浏览器 profile。`observations.json` 汇总真实状态、未响应样本及驱动失败；截图未加工。
