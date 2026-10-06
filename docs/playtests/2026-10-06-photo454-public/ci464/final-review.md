# PR464 独立最终审查 — OVERALL APPROVE

审查者：CODEX-LEAD 独立子代理 `leader_scope_audit`；未参与实现或候选运行，不代表既有 CODEX-LEAD-ASSISTANT。本审查仅只读源码、Git/API、原始日志、图片及保存的只读数据库；没有另开引擎或浏览器。

PR：https://github.com/narutojzm1-dot/youjia/pull/464

首次审查的旧远端 head（下文保留当时状态）：`942e402fdfd79975adbeda02defd9716549e76f4`，tree `be3af4a54ae8d35e32f258fa23b3e29c881e55ec`，与本地 `d688301abd546194ff0eccc15a224a0c59024928` 全树一致。

## 首次审查历史：代码及候选证据 APPROVE；当时合入总门禁未通过

未发现此范围需要修复的代码或证据错误。当时 fresh API 的 main 已到 `cd836bf9e823b4e6276731b69e57f167c84547b8`，PR `mergeable=false`、proposed merge 为 null，当前 head 的 Actions runs 为空。因此这不是总体合并批准：需要保留祖先的纯文档整合、新远端精确 head 复核及对应实际 PR CI 全部通过。不能用候选验证代替不存在的 CI，也不能称已合入、已发布。

## 代码、作者成果与基线

- 原作者 `742b293cc3e252f1fd7b46aa07333350155108cc` 五文件逐 Git blob 保留，真实祖先存在；候选源 `fd887ff8691b41edba305ab946c43df082e793f7` 与 main `b300da74bf157de3f152e63331096cb1eb28b3f7` 均为最终本地真实祖先。
- 已验证源到最终本地全部非 docs、非 .github 路径差异为空；最新 main 的工作流逐 blob 保留。此次只有 PhotoArrival 快门文字暖纸底及配套测试/登记，没有 Main、存档、探索或其他 Owner 在途代码变更。
- Panel 只创建一次，作为 ShutterCaption 子节点、behind parent，双方 `MOUSE_FILTER_IGNORE`，继承原文字淡出。纸底随布局/语言变化按文本尺寸重算。`play`、原倍率/照片内容、原持留/退场、`dismiss`、`_finish`、相册与内存清理路径未变。
- 行框位置/尺寸未改，但垂直 CENTER 会改变字基线；报告准确披露，不能声称所有文字像素位置不变。
- daily 增加唯一新入口，74 个唯一套件均有准确完整正数完成格式，100755 保留；新增9例为明确 fake executable 合同检查，不能冒引擎验证。

## 原生与导出原件

独立重算8个 process 日志的 byte/SHA256，与 native 归档逐字节一致，实际直接退出0，`run.exit` 和 `outer.exit` 都是0。完整 daily 按引擎启动分段逐一匹配74个套件的精确完成格式，75次启动为1次import+74套件；包含 shutter1290、mat550、disabled4400，末尾两项 Node 完成行存在。50原包装器受控案例、9新格式受控案例、Python retention/publisher及 Web 导出原件均保留。实际引擎 import/specialized/daily/export 段未发现 ERROR/WARNING/FAIL 诊断。

实际导出20文件（9个常规导出+许可页+10个存档模块）全部对 candidate manifest 逐 bytes/SHA256 重算。候选 PCK：27,090,652 bytes，SHA256 `6f84caeb3dc92d6d12a91f39f6cc766dcc521a26bdb70b2f8c99063384eb73a3`。全部54份 native 归档与 /tmp 原件逐字节一致。准备阶段 source 中未开始字段明确为历史快照，不冒现在未跑/已跑状态。

## 普通候选 Web 与画面

全部54份浏览器档案、13,574,231 bytes、37张完整 PNG、53条 SHA256SUMS 与 /dev/shm 原件重算并逐字节一致。独立检查 driver：仅普通鼠标操作、fresh context、截图与只读 IDB；无游戏/存档/时间/语言状态注入。四次 HTTP 绑定均为候选 fd887ff 源及同一实际 PCK，HTML 与实际导航响应一致，10模块+许可页 bytes/hash 一致；资源状态均200，errors=[]、无 console error 或 driver_error。两个 context 实际 close→new 串行，最后23:23:49 UTC全部关闭。

独立观看竖屏 portrait arrival03、自然退场、相册，以及短横 landscape arrival04、自然退场、相册原图：390×844及568×320中文正常动画的自然首照，暖纸底文字完整、照片/衬底/caption可见；自然退场后纸条和照片消失，普通相册呈现同一羊照片。两个只读 current 各 generation2/album sheep_pet_gentle 与各自画面一致，不把不同 fresh context 的存档说成字节相同。

短横纸底覆盖目标提示纸片右侧区域；本次“目标：窗台花箱 / 看看花箱·空格/按钮”在左侧，完整显示帧没有被盖字。长提示和全部 HUD 未覆盖，不能外推为所有提示始终可读。原作者另一次夹具覆盖文字报告没有被改写成本次普通实见。

不覆盖：普通 Web 英文/减弱动态（只有原生夹具覆盖）、真机触摸、听验、#459、长目标提示、全部照片类型、精确动画曲线/时长、完整存档恢复/浏览器重启、所有重叠控件输入穿透。专项1290内固定 seed/强制规则、Tween.custom_step、locale 调用如实为原生夹具，不冒普通体验。公式对比度不冒像素实测或淡出全程承诺。

审查辅助材料由原独立审查保留，见[最终公开审查回执](https://github.com/narutojzm1-dot/youjia/pull/464#issuecomment-6005708356)；候选原件仍在[原集成档案](https://github.com/narutojzm1-dot/youjia/blob/0f4226dc6710ef3a11099baf45f707bbfd4fd30e/docs/playtests/2026-10-06-photo461-integration/README.md)，本档不重复复制候选图。

后续只需对新整合 head 做差异/证据保全/实际 CI 增量复核；无理由重复上述已通过且生产不变的引擎或两组普通 Web。

## 新最终提交增量复核

最终远端 head：`0f4226dc6710ef3a11099baf45f707bbfd4fd30e`，tree `63ff0706a9c60dd31a69cb412b9629398a67848d`，与本地 `b472b6a59f214da5716c87567baac77533edc0eb` 全树一致。远端两个真实父依次为旧 head `942e402fdfd79975adbeda02defd9716549e76f4` 和最新 main `cd836bf9e823b4e6276731b69e57f167c84547b8`。

独立增量复核 PASS：28个非 docs/.github 顶层对象与实际已验 fd887ff 全同；原五 blob、daily100755、全部原始日志/图片保留。PM463全部14路径完整保留；requirements 严格等于 main 加039行，decisions 等于 main 加039段。自身原件目录只改README来源说明：fd887ff是实际本地运行源，不冒API生成的远端祖先。前文描述本地 d688 的祖先关系仅属于当时本地，不扩展到远端API提交。

实际 proposed merge `68e674d1030046d90c88a1e29c5d35e282edd44e`，双父为 cd836bf 与0f4226，tree与该 final完全相同。真实新 CI `37389414385` / job `112030653947` 已启动，取得Runner并完成取源、引擎安装和两Python；原生及Web仍运行时，不以这些中间状态作总体批准。旧head空CI历史保留。

增量机器可核原件：[增量核对](incremental-verification.json)、proposed merge及API快照；本地未重启引擎/浏览器。

## 实际 CI 完整独审及最终结论

**OVERALL APPROVE：仅批准最终远端 `0f4226dc6710ef3a11099baf45f707bbfd4fd30e`，完整 tree `63ff0706a9c60dd31a69cb412b9629398a67848d`。** 2026-10-05 23:44:34 UTC最后核对 PR仍为该 head，base `cd836bf9e823b4e6276731b69e57f167c84547b8`，全部适用门禁通过，无阻断问题。合入者须在操作前再次确认 head 不变并使用精确 head 条件合并；本 reviewer 没有执行合并、发布、调度或新开引擎/浏览器。

实际新 [CI run 37389414385](https://github.com/narutojzm1-dot/youjia/actions/runs/37389414385) / job `112030653947` 的所有步骤均为 success。完整日志 ZIP 已实际下载：79,306 bytes，SHA256 `c4b86f2ca32f3edd65bd0e8580d99dbbce32a17459912fe606b51b660c1d2499`；本档收录[安全CI摘要](review-summary.json)和[独立逐套件结果](actual-suite-completions.json)，完整原日志可由上述GitHub运行获取；未复制凭据行或日志ZIP。

注意来源差异已实核：checkout日志真正检出的是 `5dff8817b03ed39467c466922af058e0408a8ae9`；GitHub目前给出的预览合并SHA为 `68e674d1030046d90c88a1e29c5d35e282edd44e`。两者 API 完整 tree 均为上述最终 tree，父提交均严格为 `[cd836bf9e823b4e6276731b69e57f167c84547b8, 0f4226dc6710ef3a11099baf45f707bbfd4fd30e]`。不能把后者冒称实际跑过的SHA；真实执行来源、精确父和完整内容已绑定，没有未验证内容进入此批准。

完整实际CI核验：

- checkout保默认 proposed merge、blob:none、depth1、非cone排除根docs及persist-credentials:false，实际动作与预定工作流一致。
- 实际Godot4.7.2共75次启动=1import+74套件；74份独立日志段逐一匹配最终TSV的准确完整成功行，包括shutter1290、mat550、disabled4400。逐项结果在 `actual-suite-completions.json`。
- 50个完成门禁合同案例、两Node完成行实际存在；Web retention 11项OK、真实publisher双构建fixture通过。
- 实际Web export引擎运行成功，最终HTML/JS/WASM/PCK四文件非空检查成功。原生及导出无 ERROR、WARNING、FAIL 或资源加载遗漏诊断。

此前对旧head无CI/文档冲突的保留记录到此解除；不表示那一个旧head运行曾经通过。候选中文两视口普通首照的可见纸底与自然退场、原作者范围和真实CI共同满足本切片合入门禁。普通Web英文/低动效、长提示、全部HUD、触屏、听验及存档完整恢复仍是明确未覆盖范围；本批准不扩大这些结论，也不宣称main/Pages已发布或正式公开普通后验完成。
