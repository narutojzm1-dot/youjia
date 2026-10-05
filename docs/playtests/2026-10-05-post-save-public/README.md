# #350 手帐短横屏修复与生产存档后的主流程回归

Owner：CODEX-LEAD-ASSISTANT。PR #351 / BUG-ALBUM-LANDSCAPE-20261005；来源 #40 已由 Leader 验收关闭；#350 为独立新缺陷。本目录同时保存本轮 #195 输入观察，两个范围不混为一项修复。

## 缺陷与候选

实际公网 `game-55cb7ce` 正常游玩、取得五张照片后，将手帐旋转至 844×390，照片遮住日期题词并越过纸页（`public-before-landscape.png`）。原 PhotoMoment 默认最小 184×184，卡片缩小后实例仍被撑大；低矮页面的文字空间也不足。

仅修改 Main._album_page / _photo_card：相册实例最小尺寸随窗口缩放，进入树后再应用窗口尺寸以避开构造时的最小尺寸缓存。按既有文案的真实换行、继承字体的完整行高与行距预算图片空间；低矮宽页文字在照片旁，低矮窄页或长文案页在照片下，通常页保留框内题词。照片快照、存档、资源、探索及标题方法不改，较长文案或极端日期会使用较小照片来保持文字完整可读。

第一次候选 bec5bbf2c265a3a8a41934ea7f3c3d8e73cc4c21 的五实际照片回归 3078/0，但独立 CODEX-LEAD-ASSISTANT-REVIEW-PR-351 扩展全部合法文案后发现英文正文/页码越纸，各8448项失败12/14/16；720×460 goose_horse_mount 的页码进入导航为新增回归。结论 REQUEST_CHANGES 已记 PR，不能用五样本通过覆盖此缺口；原样日志 independent-before-variant-*.log.txt 保留。

返修专用 test/album_layout_suite.gd：保留本轮五张真实照片隔离夹具，再将真实快照仅作几何用途克隆到全部已有合法 polaroid ID，遍历三组合法题词变体、最大日期10000，中英文/八视口（含720×460短双页）/同实例旋转/旧ID/空页/照片存在性/文字照片页面边界/三按钮互斥/方形比例/数据不变，45914项全部通过。克隆只验证静态文案布局，不是自然事件或捕照证明。完全相同最终矩阵在远端7c1608原Main上失败3190项，strict exit1；压缩完整原版日志 native-before-expanded.log.txt.gz，修复结果 native-after.log.txt。旧3078项/271失败作为早期子集证据保留在 native-before.log.txt，不混淆分母。

最终代码保留7c1608c7e826f458eaae979d48727b0e6e2bdf58的标题#354、Cloud#342和Leader#353；6856f07b7fcffb42c869d2bb053c0f6419300f2f只追加正式验收文档，同运行时代码。返修后完整严格 tools/verify_daily_life.sh 从稳定源码运行exit0，native-daily.log.txt包含最终45914/0；早期a936完整门禁另压缩保留，不能充当本次返修验证。真实publisher保留11项、版本化存档模块发布测试也通过，daily保留100755。

本地普通Web：起初基准81d225c的同手帐修复，正常进院摸羊获得照片；最早坐标点到标题空白没有进院，原输入/日志保留，正确流程从10-corrected-enter-yard开始。之后bc/a936各自导出/真实重开；最终返修用7c完整运行时代码+本方法重新导出，真实关闭重开同一独立本地profile，历史照片完全相同、generation3、pending_intent=false，六视口1280×720、844×390、700×400、720×460、390×844、360×640都可读、errors=[]。三张local-fixed-*.png为最终返修候选原截图；candidate-verification.json记录实际源码/PCK/JS/WASM SHA256。Web为中文，英文及全部文案几何由原生覆盖；没有注入世界/时间/存档，候选不是正式上线。合入后公开证据另核原单/公开资源，不能凭候选截图推定上线。

## 新生产存档的普通公网流程

独立持久 Chromium profile，真实鼠标/键盘、软件 WebGL。`public-events.json.gz`、`public-commands.jsonl` 和驱动日志保留全部步骤；名字只是输入意图，以状态与截图为准。最初坐标误点暂停后的数次输入无效，07 正常继续后才推进，未误报失败动作通过。

在 game-55cb7ce 实際走动、摸羊、拿草/递草、播种/浇水、正常抛竿并自然钓获。最终五条 album/photo_moments：sheep_pet_gentle、llama_sun_sheep_happy、llama_fed_gentle、llama_overcast_goose_annoyed、fish_first_catch；plant_state=1、planted/watered_day=1、first_fish_caught=true。`public-natural-catch.png` 为普通钓获画面。背景出现阴天后的已有照片兼容观察不替代 Producer #168/#51 的背景质量验收。

实际确认回标题 generation 16；第一次驱动重开等待首帧超时，未算通过（两份失败日志保留）。关闭持久上下文原有页面后，用修正驱动真实重开同 profile，公开版本已更新为 game-3de05fc；全部五张完整照片、日期、种植和首次钓获字段、假期计时逐值相同，generation 16、pending_intent=false、errors=[]。`reopen-comparison.json` / `public-reopen-events.json.gz` / `public-reopened-photos.png` 为证据。此为跨两个正式已发布版本的普通保存/重开观察，不是旧 FS 迁移、容量故障或中止事务验收。

初始正式资源：Actions 37293308869 / Pages 37293814016 success，精确 gh-pages 763b07ba4b7cd90ff5ad2582ad407e96fee8c092；JS/WASM/PCK 及全部 10 个实际 save-55cb7ce 模块 HTTP 200、完整长度、模块 SHA256、Git blob/tree 一致。PCK 22003712 字节，SHA256 18a240270399972993bdac2ef2bc828da72003642df7d7548a667060a56de976。`public-tree-verification.json` 为实际核验，而不是凭截图推定版本。

## #195 输入结果与剩余

普通单浏览器：两轨各 20 次，按住 0/80ms、等 180/80ms 两轮，共 160 次均观察到真实 WebAudio playing 变化；原始诊断与 DOM/RAF 记录分别压缩存档。

同时运行两个软件 WebGL 页面时，第二个实际 game-3de05fc 上 40 次零按住、等 80ms 输入有 2 次未变化：music #16、ambience #2，等到 2 秒仍未变化，starts 也不变。可信 DOM down/up 已到达且后续有 RAF，不等于证明 Godot 收到了按钮 pressed；根因未确认。保留完整 `concurrent-input-result.json.gz` 与复现脚本，不能宣称快速输入全部通过。本 PR 没有修改音频帧守护、资源或状态。

这轮不是物理手机、真人听验、BFCache、容量/离线故障、稀有组合或完整季节体验验收。发现 #350 后整体体验门禁保留缺口，不能因流程能走通就宣布整个游戏心流全过。#40 保持已验收关闭；#195 及资源父单保持余项准确；后续 #195 按已复现输入归因接续。

所有 .json.gz 均为原始 UTF-8 JSON 的 gzip（mtime=0）；可用 Python gzip.decompress 读取。没有上传 PCK/浏览器 profile。`observations.json` 汇总真实状态、未响应样本及驱动失败；截图未加工。

## 33b105 最新保存提示修复组合

633bb阶段在6856/7c基准的独立45914/0与title251、ui_interaction、day_label173通过；随后Leader357合33b105f075a1b851450f647c623302070ffafe1f导致append冲突，保留33最新完整Main，仅移植完全相同两相册方法；daily同时保留其save_feedback21和本相册入口，需求/决策记录放稳定节前，未覆盖Leader新记录。新实际4.7.2 Web导出/同profile真实关闭重开及六视口再次通过，8事件gen3/pendingfalse/全部照片和保存数据不变、errors=[]。执行者查看本阶段两张原截图；candidate-integration-33.json绑定实际组合Main与PCK/JS/WASM哈希。之前candidate-verification/native-daily/local-fixed证据继续精确属于6856/7c返修阶段，不冒本组合新构建。

本组合第一次完整门禁误设GODOT_BIN，wrapper实际默认4.6.3；该日志native-integration-33-wrong-engine.log.txt.gz明确作废，不作为正式4.7.2通过。已改正确GODOT变量指定4.7.2重新完整执行；本提交冻结时在途，合入前必须在PR记录4.7.2最终exit/完整日志结果且独立终审通过，正式证据归档在后续文档PR；未通过不得合入。独立最终完整SHA结论以PR记录为准，正式公开发布另留证据。

## 正式结果归档

最终e8ec19fa经独立完整SHA批准后PR351合bc8a048；正确4.7.2组合完整门禁及正式CI、Actions/Pages、实际公网13资源/旧五照片六视口重开全部已核。候选阶段待验不再代表当前状态，原始阶段记录不抹去；详见[正式分列证据](../2026-10-05-album-landscape-release/README.md)。#40维持已完成；#195并发短输入根因等未完不因此关闭。
