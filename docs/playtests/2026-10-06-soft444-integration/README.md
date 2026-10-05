# REQ036 / PR444 授权集成验证

实施 Agent-ID: CODEX-LEAD；原实现 GROK-CONTRIBUTOR。接收记录444/6002032456。

原 cda5ab8ded8384f3f3b7bfeccf996652b65a1a9c 保留为真实父祖先，main基线 a99660937ef2942779d9cf217079559611616efa；运行代码提交14a85a532f9510306b7921b9daa23409d17799c6。只 Main._soft_button/_soft_focus_ring 文字与焦点样式、原专项及daily永久入口；输入、按钮行为、布局、音频状态和存档不变。作者原记录在 [原生说明](../2026-10-06-REQ-036-soft-button-focus/README.md)，未提供的截图不冒已归档。

## 覆盖解释与原作者口径补充

Godot 4.7.2原专项5080项由集成者实际运行通过。该数字包括内部主题取值、几何，以及 grab_focus()/pressed.emit() 驱动的场景状态验证，不能称为真实鼠标/键盘/触屏输入或听验。

独立预审发现 _panel_backgrounds() 只查祖先 PanelContainer；标题 _title_card 是兄弟 Panel，因此5080项**不包含**标题84%透明纸卡混合背景的这项覆盖。保留作者原文不改历史；[预审原件](preliminary-review.md)另用线性sRGB公式算得 TITLE_ACCENT 对84%PAPER叠黑为3.17798:1、对CREAM为4.73944:1。公式结果不是Web渲染像素测量，也不替代实际截图对裁切和可读性的检查。预审不是最终SHA批准。

修复隔离副本后完整daily通过：72次Godot启动（包含import，不称72套测试），新增5080专项已在daily再次通过；loader/motion Node检查、11项Web bundle retention及本地bare fixture上的实际publisher测试均通过。Web export exit0，候选PCK 27,088,652字节，SHA256 c8b05b9bbe0a5359d223b8686212366676c549538e3845279b4b84d4f8a92530；[完整摘要](validation-summary.json)、[候选manifest](candidate-release.json)。

本地候选仅http://127.0.0.1:8444/，独立真实浏览器结果由父代理另行接续，本实施者未开启浏览器。尚未最终SHA独审、合入或发布，候选包哈希不冒公开包哈希。

## 首轮环境失败保留

首轮完整daily未通过（exit1）：隔离稀疏副本漏检出原已跟踪的 art/concepts/producer_world_20261005/near_path_anchors.candidate.json，exploration_slice 第450行读空文件后出现JSON解析/Nil错误；虽然该脚本打印局部206检查PASS，verified_godot仍正确拒绝整轮。此失败完整日志和退出码保留。补回a996精确1357B原fixture并审计test/tools/scripts的art/docs运行引用后，开始另一次完整daily；没有改生产代码、测试断言或跳过失败suite。

## 导入与文件边界

Godot import自动改写5份原有PNG .import的UID/派生路径；[原始diff](generated-import-only.diff)留存，仅作本机导入记录，导出后精确恢复到提交对象，不带入实现。隔离副本中生成的未跟踪 .gd.uid 记录于[清理清单](generated-uid-cleanup.json)后清除；作者已跟踪的新suite.uid保留。源代码、测试与永久入口在运行后对14a85a5没有差异。导出器按正常导入生成缓存，与源码更改分开记录。

原生与Web听觉舒适、实际手机、禁用按钮新设计、#382音频开关/输入状态bug仍未覆盖。独立预审的数学对比、5080内部回归和之后实际浏览器画面属于不同证据，不能互相替代。

## 后续候选与main集成

[三视口普通键鼠候选体验](../2026-10-06-soft444-candidate/README.md)随后已由实施代理完成，41图、6次实际包核对、errors=[]/exit0，非独立终审。该报告覆盖到的真实焦点/按住/音乐标签恢复/确认取消与未覆盖分别列明；本档案先前validation-summary/coverage-limits中的browser pending是创建时快照，由此后续结果更新，原件不改写。初次驱动误断言dataset的失败单独保留。

随后合入指定main85fada2edb5be5c4930a7ccf651ad7bfa1473073（包含Cloud445探索测试及PM446/关系448证据），本地merge6d7e534e89c060d26a2d93a226e83644ab64b280；运行脚本/场景/资源/web/project/export对实际候选14a85a5差异为空，[合并记录](latest-main-merge.json)。只受影响探索suite更新：Godot4.7.2必要import后218/218通过，exit0；自动导入变化再次记录并恢复。未重复导出或伪称在该合并SHA重跑全量，最终PR/合入CI由负责人接续。
