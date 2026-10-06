# #399 公共启动生命周期保底切片（候选，未发布）

Owner CODEX-LEAD；实现助手 /root/horse180_repro。原单认领 [5999958180](https://github.com/narutojzm1-dot/youjia/issues/399#issuecomment-5999958180)。基线 main `98c2e6b1664ad77113f7a5f9111c734461f012a0`；运行修复 `fe4f4dd080c2f02a943687e0e1df2a2d2266f8a7`。不接管 #399 全项，不修改 Assistant #382 的 _input/modal/slider 或 Cloud #427 cleanup。

## 原因与修复范围

公开 ecea67d 的两次普通触摸探针出现近郊非正常回院（原档另行留存）。隔离日志候选同源码只加日志，首次标题触摸确实在 frame39 发出两次 play pressed；第一次已到 game，第二次又进入启动并停在 flush。它证明重复启动本身，未完整复现公开迟到弹回：诊断最后普通路面截图仍在近郊。详见 diagnostic/README.md 与完整事件结果，不将推测写作完整因果。

生产仅为标题 play 入口增加来源检查，并对 _start_holiday 整段（包含 await flush）加进行中锁；失败与正常完成释放锁。AudioDirector.unlock_audio 仍在真实 pressed 调用栈，确认 restart 仍能直接启动；无日志、无延时、防抖时间窗或探索业务变更。

## 验证

真实 Main + viewport 原生专项 14/14 通过。先用原生mouse-first touch流复现两个 pressed 信号，受控挂起真实 SaveStore.flush_pending，在期间重复调用不创建世界；解除后只有同一实例，晚到信号不能替换院子或中断已进入探索。覆盖真实标题回程、受控flush拒绝和 ready通知恢复后重试、确认restart替换世界。测试故障仅用于原生专项，不冒正常Web操作/真实落盘故障证据。

第一次直接运行因复制缓存与已跟踪.import路径不一致报missing cloud ctex；原失败 suite.log 保留，正常 editor import 后重跑通过，生产资源和.import不提交。完整daily exit0，68次Godot启动及Loading shell/Node21通过，无SCRIPT ERROR/ERROR/FAIL；完整daily.log保留。

Godot 4.7.2 release Web export exit0；普通无诊断日志候选PCK 27,085,436 bytes，SHA256 `ff17bbbed214843b4cc6738aafb0f285cb4d48322e8d02d0a3c98f3dbf6f1a18`。候选由 /dev/shm/holiday-start-export 提供，仅复制原web/save模块。尚无最终独审、合入、Actions、公开manifest/PCK后验，不称已修复上线。实体手机、携物返院、声音听验及完整#399仍不在此结论内。

## 独立普通候选 Web 复验（review304）

[完整范围](web/README.md)。三fresh profile/两脚本实际exit0，每页PCK实际下载ff17核对，错误为空。真实touch首次7秒门返仍在路上，保留中间原帧且不冒通过；唯一补样本正常等待走完，原图明确“回到院里了。空手走一趟也舒服。”；另fresh键盘明确“回到院里了”。失效点路面touch及追加等待均保持近郊，无原先初次arrive/恢复异常。实现作者和Leader另外亲看这两张返回原图，独立QA不等于最终代码审查。

归档精选8张未编辑原PNG与完整两脚本/结果/QA说明，web/archive-manifest.json记录原23文件全集，未选原图仍在/tmp/holiday-start-candidate-qa，不声称都提交。archive-hashes.json只列本片实际归档原件。HTML生产标识原值null，不伪造manifest；git首末绑定运行fe4，之后本分支只整合main60a324的文档与证据，运行代码相同。

历史正式触摸失败已由[PR429](https://github.com/narutojzm1-dot/youjia/pull/429)归档在[独立目录](../2026-10-06-exploration399-touch/README.md)，不覆盖失败证据，不关闭#399。Cloud427仍独立在途，未包含其代码。
