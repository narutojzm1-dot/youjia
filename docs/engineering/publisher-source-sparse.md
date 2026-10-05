# 完整历史下的 Pages 发布取源排除（#130）

Agent-ID: CODEX-LEAD；[原单认领6004968169](https://github.com/narutojzm1-dot/youjia/issues/130#issuecomment-6004968169)。基线 `9623ba22c8edc564e5c89dc6b0171324e9230764`，分支 `work/codex-lead/publisher130-sparse-history`。当前是已实现/本地Git与脚本fixture通过的候选，真实最终PR CI、独立终审、合入及正式发布待。必须等460公开普通操作后验closed后再合入，避免在该验收中途切换公开源；#130父单不据此关闭。

## 为什么保留完整历史

现有Pages保留helper按真实first-parent发布顺序保当前和最近构建。此前7例已证明main depth1会让共享Pages工作树带shallow标记，即使另外取回完整Pages历史仍保守不裁剪。本片仍用 `fetch-depth: 0`，仅给原checkout增加：

```yaml
sparse-checkout: |
  /*
  !/docs/
sparse-checkout-cone-mode: false
```

当前 `actions/checkout@v4`（审计精确SHA `11d5960a326750d5838078e36cf38b85af677262`）的sparse输入自动设置 `blob:none`；depth0仍fetch全部heads/tags，有浅边界时unshallow。两个根锚定模式仅隐藏根docs，保留全部art/assets、根metadata、.github、test/tools/web/site和嵌套test/docs。没有改action版本、ref、权限/凭据、并发、回归/导出/发布步骤、publisher/helper或保留数量；也不删除仓库证据。

原publisher后续 `git fetch origin gh-pages:refs/remotes/origin/gh-pages` 会沿用origin的promisor/filter配置。隔离实际验证中，完整main历史3提交、Pages first-parent4提交与tag均在，source与linked Pages工作树都是shallow=false；工作树确实继承非cone模式，根game-*、index.*、manifest及save-*仍物化。原git add-A/commit/push后未物化的历史Pages docs保持原blob，没有误删。全部main历史版本和旁支独有docs blob在两次发布后仍missing，证明此机制可以减少这类blob取回。

这不证明当前等待的根因或性能收益。旧460发布37384961406取源于UTC22:50:19至22:56:09实际success350秒，并非失败；其阶段快照与本候选无因果对照。完整refs树/历史仍有成本，当前保留的旧包、素材仍需按需下载；docs与保留路径共用的blob也必须取回。服务器忽略filter时行为仍正确但可能回到全blob。不得把未压缩字节差或一次计时当提速已证。

## Fresh main 的资源与依赖边界

[最新源码核查](publisher-source-sparse-evidence/fresh-source-scan.json)逐Git树核到915个非docs blob：734文本全部读取并校验精确blob SHA，181二进制路径全保留，无symlink。943处原始res:// token没有res://docs/；非说明文件docs命中逐项核为配置排除、注释或外部链接。原动态角色、照片纹理、I18n/config及隔离user目录约束保持；宽匹配744行只是审阅索引，不冒证明所有动态状态。

对已验a0bb以来的6个非docs变更重新核对：只读PR workflow、Main禁用态样式、disabled suite/UID、daily、完成映射。新增460专项读取scenes/main，没有新增docs依赖；当前daily为**73套+1import**。全art保留涵盖近郊anchors；四个曾漏的根metadata、完整assets和10个web/save模块保留；export_presets原有docs排除不改。未来若新入口需要docs fixture或生成数据，须重新审查，不能静默跳过验证。

## 可重跑的真实脚本 fixture

[证据目录](publisher-source-sparse-evidence/README.md)包含可独立复现脚本、原始输出、直接返回码与源文件哈希。fixture读取当前仓库原publisher/helper和10个真实模块，使用临时file:// bare origin、合成四入口dist；版本查询只运行明确stub，**没有Godot或浏览器进程**。成功的12次发布全部是本地fixture，不是生产发布。

运行源 `93d708d5fb20f8007b47b40bfc58f1845295aa4e`，运行树 `667b61bea97ae00aa55c54be0fe05941a6049deb`。最终文档提交不改该源的非docs文件。

| 配置 | 历史/取源检查 | 保留与真实publisher |
| --- | --- | --- |
| full baseline | main/Pages完整，docs已取回 | 正常裁剪，两构建通过 |
| **full + partial + sparse候选** | **非shallow，全部唯一source docs保持missing** | **与baseline一致，两构建通过** |
| full + sparse无filter | docs隐藏但blob已取回 | 正常裁剪，两构建通过 |
| full + partial无sparse | HEAD docs按需物化 | 正常裁剪，两构建通过 |
| depth1 + partial/sparse负例 | shared shallow仍true | 保守留全部，包数增长；不能替代候选 |
| full候选但服务器不支持filter | filter被忽略，docs blob已取回 | 行为正确、无传输优化保证 |

每配置5个保留检查：顺序裁剪、未知历史包全部保留、缺当前包拒绝、keep0、负keep，合计30项。每配置再实际执行原publisher两次，共12次：sourceCommit/entry、HTML及JS/WASM/PCK、别名、manifest、10模块精确字节/SHA/相对import、旧版本module目录、应删/应保包数与历史Pages docs树条目均核对通过。另每配置创建新源commit但移除dist PCK，**6次原publisher均返回1，本地origin gh-pages head未动**。

审计首轮depth1反例误要求不可达旧docs blob出现在rev-list missing枚举，导致fixture断言失败；已记录并更正为只有完整历史模式才断言所有历史docs missing。完整6模式重跑后通过；原错误没有隐藏，也没有冒称生产失败。实现候选的可重跑脚本及结果再次全部通过。默认重跑写新临时报告目录，不覆盖已归档证据。

## 交付门禁与未覆盖

本片没有玩法、画面、存档格式或音频变化，不生成玩家截图。没有为内部checkout四行重复本地Godot；最终PR CI必须真实执行当前73套、门禁mock、两项Node、原两项发布辅助测试与Web导出，并与独立最终SHA审核绑定。PR CI不执行生产发布，因此不能用它替代main发布验收。

只在460公开普通后验closed、最终独审APPROVE且真实PR CI通过后合入；main运行必须核实际action SHA、blob:none及完整历史、后续Pages fetch/worktree、原有回归/导出/发布所有阶段。部署后实际读取公开HTML/manifest、下载PCK和10模块核来源/哈希，并核当前/最近包保留、未知历史保守行为。若新门禁失败，保留上一可用版，不把触发成功当发布完成。全部生产验收、真实性能比较仍待后续结果，不在本档提前标通过。
