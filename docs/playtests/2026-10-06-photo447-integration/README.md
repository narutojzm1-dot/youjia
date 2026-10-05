# REQ037 新照片相纸衬底集成验证

Agent-ID：CODEX-LEAD（作者授权集成）。保留原作者 `faf507ae47a1bd999a32b3720b22cf3391ea5b1e` 为真实祖先；原作者六个文件逐字保留。集成新增 daily 入口、完成标记表单行和需求/验证记录，不改变相册、照片取景、题词、卡片缩放、显影时长、输入或存档。

## 实际执行来源

| 工作 | 精确来源与覆盖 |
| --- | --- |
| 首轮完整回归 | `3970488afd79c0419ed0cc0ad7f2d6d4ab10d983`，组合 main `de4ba4227a1ce0eff5db1106a051bdf9845332a9` 与原作者；Godot 4.7.2 专项550、完整daily实际73次Godot启动，两项JS完成；随后retention11和两次本地Git发布辅助fixture通过。见原脚本与日志，外层工具退出状态限制在下节单列。 |
| 完成标记接入后的明确出口 | `85217509f369e2dc06495bb1fa4ff1649b181a47`，整合 main `16ef89a2bcd7245485ad5f116b251cd2978d25d7`。正常import、50项门禁契约、真正 `run_verified_godot_suite` 的550专项、严格 `run_verified_godot` Web导出均由Python直接记录 exit 0，外层工具也 exit 0。 |
| 新专项完成协议 | `test/photo_arrival_mat_suite.gd` 必须整行匹配 `\[photo-arrival-mat\] PASS: [1-9][0-9]* checks`；另核550通过、0/负数/别套完成行均拒绝。没有把固定550写死，保留未来合法增长。 |
| 两来源的生产代码/包 | [逐路径对比](post-gate-source-comparison.json)显示只变工具、测试和协作文档；运行时代码变化为空。两次真实PCK字节完全相同：27,076,376 bytes，SHA256 `812144231f60d96c5b565d0cf735982b356e2efece0eeb0d4ffde865b600e030`。 |
| 最新main整合 | `04808b0483f89cbd76b9769bb9d00961c149ec7e` 合入 main `d788f48b5f8d322d2d1dc86551fcab87770ee897`；对实测852只新增只读PR workflow和文档，生产/tools/test差异为空，原作者六文件逐字不变，[完整比较](final-main-comparison.json)。没有无故重复引擎或浏览器。 |
| 候选发布来源 | [candidate-release.json](candidate-release.json)绑定实际852源码/树、HTML/JS/WASM/PCK及十个保存模块；只用于本地候选，未冒正式Pages发布。 |

新完成标记框架的主线完整验收归 [PR452门禁证据](../../engineering/godot-completion-gate.md)；本切片在已跑完整组合后只补受影响的注册专项和明确出口导出，不把新框架的全量检查冒称本片重复执行。

## 原始失败与限制

- 首轮工具会话29493最终报告外层 `exit_code: 1`、无输出；内部脚本已记录 `run.exit=0`。`validate.sh` 用 `set -euo pipefail` 串行执行，各后续步骤确实到达；这些可推断步骤成功，但没有逐步骤独立数字记录。**外层1原因仍未解释，不宣称首轮外层成功。** 完整文件哈希/时间顺序与逐阶段证据保存在 [first-run-exit-discrepancy.json](first-run-exit-discrepancy.json)。首次导出原包仍单独保留，新的严格导出取得直接测量的0，并与其逐字节相同。
- 整合main前恢复了5个tracked `.png.import` 以免提交生成metadata；首次单独补跑忘记重新import，四个云带旧占位ctex路径令专项明确失败。门禁正确阻断，原日志在 [post-gate-before-reimport-failure](post-gate-before-reimport-failure/cause.json)。正常editor import后同断言、同源码通过，未改源图片或放宽门禁。
- 两轮import只产生已记录的5个图片导入metadata变动和新UID文件，均在执行完毕后精确恢复/清理；具体路径与内容记录保留。未覆盖他人的分支或删除既有证据。
- 首次准备候选清单的静态路径断言遗漏协作文档 `CONTRIBUTING.md`，在复制清单前即停止；核对该文件的纯文档改动后只扩此允许路径，未启动浏览器或改变导出内容。见来源对比记录。

## 补全稀疏导出中的根元数据

独立审阅发现首个852候选PCK少了4个Git已跟踪、但本稀疏工作目录未物化的根JSON：`template-provenance.json` 10,886B、`game-sharing.json`775B、`template.json`433B、`game-verification.json`344B。原包与其manifest、44张实际候选截图都保留，不把27,076,376B的稀疏候选宣称成正式完整checkout发布包。原[逐成员审计](photo447-pck-independent.json)及[说明](photo447-pck-summary.md)记录与前一门禁包的精确差异，没有归咎于UID/cache。

合入PM453的main `67c87f08c673c18b33fd14ddfe8be54991024f3c` 后，导出源为 `d22f28f40d72d9860eb5bb267a7a45df84253fe1`。对实测852的生产源码、工具、测试及四JSON本身均无Git差异；见[完整对比](final-pm-main-comparison.json)。精确物化四个原Git文件后，单独正常import与严格Web导出均直接捕获exit0、外层exit0；[输入来源](full-metadata-input.json)、[执行脚本](validate-full-metadata.py)、[出口](full-metadata-exit-codes.json)、[输出哈希](full-metadata-export-files.json)。新的完整元数据候选包 **27,089,100B / `faa935055fb62250c137625da28e15d2ac28ef3880db1e8993e5991afec84df6`**。

[独立新旧包审计](photo447-full-pck-independent.json)逐成员真实校验MD5及SHA256：394个旧成员全部原字节相同（包括场景ID），没有删除或变更，只新增四个与该SHA Git blob逐字一致的metadata，共398项。因此旧候选实际画面可在这项明确的运行内容等价范围衔接；没有重写原QA来源，也没有声称四组浏览器在新包上重跑，更不等于最终公开发布。导入生成5个metadata与36个UID再次按精确清单留证后恢复，不提交生成变动。

## 画面验收边界

独立静态像素检查从真实相框PNG洪泛得到透明窗 `[24,23,338,342)`（纹理坐标），99,746个窗口像素均落在衬底内；[alpha-geometry.json](alpha-geometry.json)。它只证明像素与几何，不是游戏画面验收。

原作者550与修前19是其原生夹具报告，本次实际550也仍是受控原生几何测试，不能代普通玩家留影。独立候选浏览器按[预案](predeclared-plan.md)从首页分别以390×844、568×320及normal/reduce媒体偏好开始，禁止seed/存档/照片状态注入。[四组合真实候选原件](../2026-10-06-photo447-candidate/README.md)现已归档：44张原PNG，四个新profile一次正常点羊均生成首照，完整显现或reduce静帧四周实纸衬可辨；每组普通相册可见同照。正常短横屏02是预期淡入，保留并排除出不透明结论；该组合未独立拍到自然收起，未冒其时序验收。10轮完整HTTP来源核验同852/PCK，driver exit0/errors空；390正常真关页→同context新页相册及完整current一致，仍不是浏览器进程重启。四组合通过本片限定候选画面验收，未代正式发布。

普通模式0.20秒淡入、1.10秒完整显现、0.28秒淡出保持原设计；reduce为1.6秒静态。纸窗是否透院子在完整显现或静帧判断，过渡中整张相纸透明不属于此修复缺陷。不宣称真机/物理触屏、声音舒适度、全部语言或完整旧照矩阵覆盖。

[archive-manifest.json](archive-manifest.json)登记本目录原始验证文件长度与SHA256。最终SHA独立审查、合入、Actions/Pages以及公开包验证仍需后续实际记录；候选不等于发布。
