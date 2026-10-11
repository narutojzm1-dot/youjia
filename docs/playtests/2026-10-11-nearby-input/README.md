# 近郊公开窗光、HUD 输入与实际存储故障验证

Owner / Agent-ID：CODEX-LEAD-ASSISTANT；#565、#734。所有原图、视频、JSON和日志按原字节上传；索引见 `evidence-index.json`，完整本地运行文件与未上传PCK/WASM见 `local-full-archive-manifest.json` / `curation.json`。239份原始文件、223,880,639字节；不编辑截图或剪辑视频。

## 已发布窗光：真实公开64c

PR735候选 `a9c24e152a0fff5af0d385d521af8a4145a47855`，完整CI38105254139通过，合入 `64c25672cb384058f73f92818dd323c499f8ef87`。Publish38106423557及Pages38107311681成功；核验的Pages提交 `41c4531b32626c393c1e01f66b728597328acd8a`。实际HTTPS17个运行文件同时核对manifest SHA256与该Pages Git blob；PCK69,620,396字节，SHA256 `6b1b6c3152c5165c205217893704dc81552c649e521e6416d73941e8f3ffe7f8`，Git blob `6885944e5ac0b85e4939ca54c5cc40b9874fe1f3`。WASM使用以前实下载的本地原件重新哈希，未冒称本轮重新完整网络下载。

`public-window64c/browser` 是实际公开HTTPS普通输入，浏览器实收PCK/模块逐字节核对，进院/刷新HTML标记均为game-64c2567。三个DPR1视口390×844、844×390、1280×720各10状态，共30状态；自然第1趟分别圆石、圆石、落羽，拾取、返院、HUD再进出、刷新各保留1件，page/console错误0。未写玩家状态、种子、库存或时钟。实际Chrome154/AMD8060S/ANGLE D3D11，仅桌面浏览器触控模拟，非手机实机。

本轮普通公开流程发生在白天，没有另跑自然夜晚。a9候选25状态及自然过夜、实际GPU三视口18项在[前份原始证据](../2026-10-11-nearby-window/README.md)；候选a9与合入64c的Git tree均为 `b883dbcb492ca1426c094ea3905204517525ab2a`，区别于本轮真实公开30状态。

## #734：鼠标HUD连点与合成Touch

[PR737](https://github.com/narutojzm1-dot/youjia/pull/737)完整候选 `83f4e15796839bd6a744112259ce421471e664ce`，基线c67933f7，CI38107932687于03:32:43Z success，含完整游戏验证与Web导出。03:36:55Z合入 `3caeb1fe6082da0cf0db00e3bea20dc47eb50edf`。这不是3ca公开字节验收；合入前检查最终头对话/行内/评审均0。按最新AGENTS集中交付规则，无Assistant逐PR强制独审要求。

仅修改Main `_input` 两个HUD/快捷栏的touch时间戳条件及院内非模态合成Mouse消费：真实鼠标不写touch token，DEVICE_ID_EMULATION不再在真实Touch前抢执行一次。保留原Touch去重、模态GUI释放路径；不改Actor、Host、库存、时钟或Cloud布局。#734原单6104894407已经实际接收范围。

原生新套件72项（两语言×三个视口），未修基线24项失败，修后0；音频按钮648、模态输入270、滑杆267、直接拾物189、Main探索300、实际磁盘容量/连点/返院/重开48通过。首次探索因稀疏检出缺原锚点JSON而SCRIPT ERROR，尽管输出290项通过，严格runner仍判失败；恢复Git原文件后独立重验300。原始失败和修后日志同时保留，不将290算通过。

`candidate-hud734/browser`是最终83无诊断插桩的普通Web导出，来源及PCK SHA见 `candidate-source.json`，实收PCK/模块逐字节一致。390×844有13状态、844×390有11状态、1280×720有11状态，总35；自然第2/1/1趟落羽，返院、HUD重进和刷新各保留1件，0page/console错误。桌面实际鼠标天气→地面入口间隔117.8ms，正常出门，非700ms等待绕过；触控天气每次仅切换一个状态。DOM输入trusted、只读观察存档，无种子/时钟/库存注入。120个rAF样本及视频容器帧率不等于所有设备的性能保证；无声录像不算真实听验。

## 横屏旧超时的具体原因

`diagnostic-input`是明确的受控诊断，临时Main打印事件/映射坐标，未进生产提交。844×390进院等8秒，触发5.5秒静观抬头后，旧点(67,300)映射world(101.6114,540.912)，入口多边形之外；合成Mouse和Touch都到达 `_unhandled_input`。静观释放后同点world约(101.6114,591.272)，真实Mouse才出门。冻结相机的原生测试不能替代普通流程当时的镜头坐标。

实际公开64c与最终83均按当时画面入口(40,317)触控并通过；没有修改生产镜头规则，也没有据旧超时报告丢Touch事件。前份窗光证据中的旧失败原件保留。最初原生诊断未完成fit_camera_to_viewport，坐标无效；其日志保留，最终源代码是修正fit之后的版本，初版源未单独恢复，不能冒称两次原始源均完整。

## 保存失败：实际IndexedDB事务中止

`storage-fault/resolved`使用同一83实际PCK/模块，在隔离Chrome对真实 `youjia-save-host-v1` 的readwrite事务调用原transaction后abort，仅切换故障开关；未伪造Host响应、未直接写游戏载荷、未改生产Host协议。两类测试共21状态，均有实际abort=true、SavePanel原图、原始trusted点击和所观察载荷。该测试包含故障注入，不能冒称普通无注入实玩。

| 场景 | 故障时的真实持久态 | 确认恢复后的结果 |
|---|---|---|
| 第3趟拾落羽写入中断 | carried为空、keepsakes为空；前两次空回院水位2 | “再确认一次”解析确定拒绝后，持久态仍为空；现场物品保留在内存，正常返院提交落羽1件、水位3；刷新仍1件 |
| 第1趟圆石回院写入中断 | active carried圆石1、keepsakes为空、水位0 | “再确认一次”后返回提交成立，keepsakes圆石1、水位1、session空；刷新仍1件 |

两类0page/console错误。故障时不强制刷新、不证明断电后恢复未提交的内存物品，也未验证永久配额耗尽或其他浏览器。确认按钮坐标通过当时实际PNG核对后输入，`retry-coordinate.json`保留。

初版 `storage-fault/initial-assertion-failure` 错将“再确认一次”当作自动新排队保存拾取，等待carried重新写入15秒超时。该断言超出保守Host的解析拒绝语义，失败原图/载荷/事件/完整视频与初版驱动原件保留；初次terminal stdout未录到文件，没有重建假日志。改的是测试预期，不是Host；修正脚本另存并有真正 `driver.log`，随后正常返院/刷新证明上述明确范围。

## Leader餐食/保存扩展后的原生组合

3ca包含Leader PR731餐食/休息保存扩展。`combination-3ca`重新实跑HUD72、容量48、直接拾物189、Main探索300，零失败；实际运行HEAD `b1329f02771b6f6e593b59ef86a9a79a475589a6` 与3ca只差docs。每套独立profile，原锚点JSON按Git恢复；48项容量是种测试夹具。PowerShell5先受脚本执行策略阻止、后因native stderr警告抛异常而中断导入，未运行测试；保留部分导入日志，不重建未捕获的terminal错误。改用原环境PowerShell7.6.5后，真实导入及四套测试全部完成。无生产代码或Host改动。3ca正式发布/实际公开资源仍独立核验。

## 仍未完成

#565目标保持active。Leader PR623/542音景仍有真实听验和公开接线依赖；以上画面、无声录像、故障矩阵均不替代听验或日版本验收。完整CI已经通过的83候选、正式公开64c和受控诊断分别有精确来源，不能互相冒名。
