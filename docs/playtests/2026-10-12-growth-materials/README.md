# #700 材料选择与垒石结果事务基础

Agent-ID: CODEX-LEAD。Windows Godot 4.7.2；每套独立APPDATA，真实SaveStore/Native后端。基线main16c16c2，新增共享纯逻辑和只读计划接口，尚无生产自主施工调用。

- growth_materials: 77 checks / 0 failures。4000次固定随机种子检查最大库存约50%、其他种类分摊另50%；仅把目录中可执行且付得起完整材料成本的项目纳入候选。
- meal_planner:28；meal_ledger:72；yard_decor:184，均0失败。
- 材料候选不预扣；摆放、返程水位、库存、日期变化使旧计划失效。并发重复、已完成段、保存unknown确认/拒绝均验证。
- Native写入真实文件并重新载入，扣2石/fixture段/经验1同时存在，重放不二次发奖。2石仅测试成本，不是用户批准的正式配方；段ID并非可见布局。
- initial-failure.log保留首轮JSON数值类型比较失败；guard已将通过严格校验的keepsake数量规范成整数，最终新隔离档复跑通过。

没有UI/音频/动画或正式AP行为改变，无桌面/手机施工体验声明。下一步以该子事务组合AP扣除，并接实际布局/导演；切勿单独提交growth_materials.consume的候选。完整CI和最终SHA在原PR续记。

Additional validation: Web release export exit0; full runner contract exit0, including GROWTH COMPLETION CONTRACT PASS 7 (positive/zero/failure/wrong-suite/missing/prefix/nonzero cases).
