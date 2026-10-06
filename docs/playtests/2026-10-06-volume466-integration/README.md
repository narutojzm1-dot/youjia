# 466 暖纸音量滑条独立集成：原生与导出证据

Agent-ID: CODEX-LEAD。原作者GROK-CONTRIBUTOR的[PR466](https://github.com/narutojzm1-dot/youjia/pull/466)，原head `1759c69cede5ba69a01bd219748796a7c50fc0d7` / tree `b3ef0b4f5f03820eab7487bd8eaa5d56a5f5852c`；[实际接收6006302562](https://github.com/narutojzm1-dot/youjia/pull/466#issuecomment-6006302562)。在main `b9f68c3c5c4e70e16cefde9b4400bb1d553ff915` 上保留原9blob与真实祖先，另加完成门禁与真实输入专项。

## 准备阶段历史快照

00:28 UTC 初建时只核精确Git字节和Godot4.7.2源码、添加测试/登记；**未运行本候选Godot、Web导出或浏览器**，未独立终审、合入或发布。原作者708通过、去autoload199失败及旧回归是作者文字报告；没有原始日志/PNG入仓可复核，不以新跑替换旧原件。实际新运行应另写精确源、退出、日志、导出hash与原图。

## 输入、DPI与Owner边界

Main配置的rect、范围、step、焦点、mouse_filter、gain handler与路由源字节保持。但Godot Slider原生鼠标采用 `(x-grabber_width/2)/(control_width-grabber_width)`；手柄从16改24会改变有效行程。这是更大手柄固有结果，不称线上BUG，也不能声称物理输入完全不变。

新增 `volume_slider_input_suite.gd` 通过真实Viewport.push_input派发mouse press/motion/release，检查两轨0/40/100、按住拖拽、释放后不拖、真实AudioDirector gain/标签及另一轨不变。一个Main/两原控件经历390×844→568×320→390×844重排；不拿直接set.value当输入。原708样式专项保留，两个新完成格式都登记daily与TSV，并各补14个fake executable合约（共28）；两条独立合法完成行按既有wrapper语义允许，不改唯一性契约。

PaperSliderBoot对进树的所有HSlider自动套样式，包括重排reparent；当前运行源码只有Main构造的音乐/环境两条，不外推永久只影响这两条或覆盖未来定制合理。DPITexture接口与逻辑尺寸经静态核对及下方实际原生专项；Web DPR2普通实图见后节，DPR3仍未覆盖。新增测试内部_start_holiday/_toggle_pause属于受控native，不是普通体验。

#382已由CODEX-LEAD-ASSISTANT接收，Main._input/_drag_volume_slider/_point_sets_slider/_fit_pause_panel不在此改；#459仍待接收，作者原文“都在改”不是当前实际状态。保默认focus不代表可见焦点已验。若普通触摸遇原382，只分列原问题，不抢方法补修。

后续：下方实际原生/full/Web已完成，普通DPR2两尺寸与同页重排已见后节，后续最新main组合另补必要专项/导出与有限普通验收；另一个未参与集成的子代理审最终SHA，真实PR CI通过后才合，再核正式发布。未完成项不得改写成PASS。

## 准备阶段已实际完成的轻量验证

`bash -n`检查daily与gate脚本通过；真实wrapper接fake executable的新增28项/全部92项于准备阶段实际exit0，见[完整原日志](format-mocks.log)和[准备状态](preparation.json)。这不是Godot引擎、声音或真实输入验证；两新native套件仍待运行窗口。最终记录须保留此前未运行的时间边界。

## 首次实际原生执行与夹具纠偏（原失败保留）

准备源89223fdc830eb3698cf3575856cbd74bb0e5e4ad首次严格import直接exit0；随后真实双滑条输入专项实际267项、4失败、直接exit1，运行立即停止，没有继续full/Web。两轨值/gain/标签、拖动释放/另一轨与重排均未失败，4处是同值0点击时夹具错误预期不发value_changed。Godot4.7.2 Slider.gui_input在每次左键按下后调用_notify_shared_value_changed，即便值相同也发通知。只修夹具为每次native按下恰一次通知，保值/gain断言与全部真实输入；不改Main或PaperSlider生产。原日志与退出保留，纠偏源后续实际结果另记，不把892第一次失败改写成功。

## 00:45 UTC 原生与导出完成时点（浏览器结果见后节）

实际运行源 `146c3711537e4fa6657f1fd54e7472747cd0b10d` / tree `2e622f91345fc1a223982480339d86fa9ff94117`；相对准备源只纠偏自有输入夹具并登记实际生成UID，没有改原9blob或Main。当前说明后续只补证据，不把它误称未来最终PR SHA。

- [首跑失败原件](native/special-v1/process-results.json)：严格import exit0、输入267/4直接exit1并立即停止，保留[失败日志](native/special-v1/volume-input.log)。
- [纠偏后真实专项](native/special-v2/process-results.json)：import、双滑条真实输入267/0、原样式708、audio-button648、confirm562、pause168、focus5080、HiDPI102/0，逐个直接exit0与完成行核验通过。
- [全量原日志](native/full-v1/daily.log)、[直接退出记录](native/full-v1/process-results.json)、[逐段标记](native/full-v1/actual-suite-completions.json)：77个不同套件+1次import=78次真实运行，全部直接exit0/严格日志/对应正数完成行通过；fake合约92、loading shell、motion preference21通过。retention11与真实publisher的仅本地bare remote双构建fixture也直接exit0，没有向实际仓库发布。
- [完整进程台账](native/full-v1/engine-processes.jsonl)共80项：另2项是publisher fixture查询Godot `--version`，不是2个新增回归套件。首版汇总脚本因78个引擎header对80条台账断言失败；[原解析脚本和诊断](native/full-v1/analysis-v1-result.json)保留，修正为按真实argv区分后78段全部逐段核验通过，不重跑或篡改原native。
- [严格Web导出](native/export-v1/process-result.json)于00:45:21 UTC结束，Godot直接exit0、整份日志无SCRIPT ERROR/ERROR/FAIL、HTML/JS/PCK/WASM均非空。[冻结候选manifest](native/export-v1/candidate-preview-release.json)绑定源146c与10个精确存档模块；PCK **27,093,724 B / `df8b4807079717a3a51c273f09c617173aa6b50ce29b812e82d595cad62cd92a`**，HTML **357,722 B / `ccd7ab5bb40cdb85dca4b4caec1ac3888ff7e7c3bd6ba121feee199c8bd5e0a6`**。冻结导出含完整根JSON；[源码绑定](native/runtime-source-binding.json)核全部跟踪runtime/root文件无缺失、179个文本工作区blob与source同一。
- 5份自动生成`.import`差异在所有native及导出之后才恢复；[原差异与还原时点](native/generated-import-restore.json)可查，不将生成元数据混入实现，不修改任何既有冻结导出。

此00:45时点普通候选浏览器尚待，随后实际DPR2结果见下一节；DPR3、真机和声音舒适度听验未覆盖，未验证触摸路由/可见键盘焦点，不称#382/#459已解决。实际候选验证不能替代最终远端SHA非作者独审、真实PR CI、main/Pages公开来源和普通公开后验；这些均未在本阶段发生。机器可读总表见[validation-summary.json](validation-summary.json)。

## 00:51 UTC 独立普通浏览器候选：DPR2同页面两尺寸

`hotspot36_qa`在源146c的同一冻结包，真实从标题入院、Escape暂停、鼠标点击/按住拖动两轨0/40/100，松手移向另一轨；390×844→568×320→390×844保留不同40%/0%，返竖仍可独立调端点，Escape合回院子。唯一Chromium/context/page，实际DPR2，00:51:55 UTC全部关闭、实际直接exit0。

[独立完整报告与覆盖边界](browser-candidate-146c/README.md)、[全部输入/前后HTTP绑定](browser-candidate-146c/result.json)、[执行退出](browser-candidate-146c/execution.json)、[42暂停原图标签比较](browser-candidate-146c/label-analysis.json)及44张完整设备像素PNG均原字节保留。前后实际下载PCK/HTML/10模块/许可均匹配冻结源；13条真实加载依赖URL/status均200，不能把这些响应记录说成逐条response body hash。

实际只覆盖DPR2/鼠标/可见百分比，不冒DPR3、触摸#382、键盘焦点#459、实际浏览器gain或听验、跨会话设置恢复。真实gain由native267专项另验，图片标签不能替代音频增益。本轮独立助手人工查看代表整图，42标签区像素比较全部符合；不冒44张逐一人工。55原件/44PNG共14,055,632 bytes，54条SUMS原单自身SHA `7b3ff6c8e4e8fb6d6270f5798ce5e30799c8f251a06ccbabeaf8a7d93c4952f6`，[逐字节归档回执](browser-copy-receipt.json)。

最新主线c501包含Cloud新增探索resize收尾/字体三文件及PM/资源候选/167证据；这份146c实测不能改标新组合。后续仅三方保留主线与466，另验受影响Cloud专项、新源严格导出与有限普通组合，再由非作者审最终SHA和真实PR CI。冻结旧导出及本节原件不改写。

归档字节检查：新代码/编辑说明与JSON的diff检查通过；完整新增档案的`git diff --check`为exit2，仅两份原始HTTP HTML末尾空行、原始Git差异的空白context行。按[精确记录](raw-diffcheck.json)保留原字节，不清洗取证原件来制造零告警。

## 最新主线离线三方整合（新的组合运行尚待）

旧候选原件已先独立checkpoint `38eed59689625b576cae944e0a58371380f6a327`。随后以真实共同b9为基，保留checkpoint与已合入main `c50188a417920e3f400c833ebcf44fe9f28c89b4` 两侧：需求保最新039及所有PM/167行后插入040；decisions保完整主线再追加本片，不覆写Producer/Cloud/GAME-PM成果。全部主线非466路径stage0 blob精确保留，新增候选原画和93个167历史证据不重复checkout。

[三方与原始范围记录](main-integration/merge-summary.json)、[精确main对象导入](main-integration/object-import.json)、[Cloud三文件源码hash](main-integration/cloud-source-blobs.json)、[受影响运行子树](main-integration/runtime-delta.json)。相比真实已测146c，只有Cloud的`find_reveal.gd`/`near_path_scroll.gd`和其`exploration_slice_suite.gd`变动；Main、AudioDirector、原466九blob、资源/Web存档/项目接线相同。后续在新的组合源上做严格import、受影响探索专项和新Web导出及有限普通组合，最后最终PR CI全量；此段不提前写验证通过。

## 01:03 UTC 最新c501组合实际增量验收

新的实际测试源 **`49cf808ae6854406851592301e843bb557639500` / tree `7d5c2c090740e94771d86ede33b07a3a6baaf398`**，已经包含c501的Cloud修正。严格import和受影响`exploration_slice_suite`实际 **278/278 failures=[]**，逐个direct exit0、全日志和正数完成行门禁通过；见[真实运行](native/combined-v1/process-results.json)与[完整日志](native/combined-v1/exploration-slice.log)。没有为了仅文档再跑旧77套，最终PR CI仍须验证最终组合全量。

[新严格Web导出](native/export-v2/process-result.json) actual0、无SCRIPT ERROR/ERROR/FAIL，01:03:38.621 UTC全部Godot结束；[新冻结来源](native/export-v2/freeze.json)：PCK **27,094,188 bytes / `0a1e0f05c5a5a6ef9e2622614a1ee28e993841ab4e68ba4809dfe25dc8ef3eff`**，HTML **357,722 bytes / `142378cc0ebffdd92e46395f6882fab20b2c38f3c50dc64387a2dcaffb1d6c79`**；[manifest](native/export-v2/candidate-preview-release.json)含10个精确存档模块。原146包及普通DPR2截图未改成49来源，新组合有限普通验收仍待；DPR3、触摸、焦点和听验仍未覆盖。自动`.import`在此导出完成后才恢复，原差异/时点留档。

## 最终文档主线同步与独立包核验

在实际组合源49cf的严格导出之后，合入已发布的文档PR474/main `8ae57959ff95117047c4362704c298b583d651a7`。其相对c501仅208个docs路径改变；保留PM/公开验收历史全文，与本片040行和466说明共存。索引级三方整合未重复checkout历史PNG，[精确证明](main-integration/docs474-merge.json)确认全部非docs源码树仍与实际测试49cf完全相同，因此没有仅为文档重复引擎或Web导出。

[非作者实际PCK对比](independent-package-review/combined-web-verification.json)确认两包各402成员，400个payload字节相同，仅两个Cloud探索gdc变化，无新增/删除。旧146普通DPR2截图可证明未变化的滑条范围，但仍不冒新49组合已执行普通浏览器；最终远端SHA独审、最终PR CI、正式发布及公开普通后验待Root完成。
