# #700 休息来源与餐次疲劳验证

基线45673209c8e88b4f6a8320cb9bf4d1020de53bc6，CODEX-LEAD，Godot4.7.2 Windows隔离存档。

rest_context_suite 43，meal_ledger_suite 72，house_sleep_suite 154，regional_clock_suite 92，全部0失败。新回归使用生产Main/World及SaveStore：受控将时钟推进至跨日，确认前不乐观展示疲劳，确认后保存awake；三餐真实写入0/1/1，重读不清除；真实睡眠事务恢复sleep并使下一早餐获1。原房门进入/睡眠/起身完整回归保持通过。故障注入沿真实SaveStore+协调器，unknown分别解析父快照/新快照，日期和休息来源一起改变。

这些是受控原生运行与存储回归，不是普通浏览器等待整夜或实体手机体验。本片没有玩家可见新UI，气泡/做饭导演/自主劳动尚未接入；work_speed接口尚未被劳动执行器消费，不宣称游戏动作已减速。

附烟囱PR723最终8ae4e0a67e6c1155260b80705e544a2187f53549独立套件编译失败诊断；未修改Grok分支。

最终补查：旧原生set_holiday_progress/set_yard_progress同样同步休息日号，保留原有显式赋时的边界行为；回拨不会清除既有疲劳。生产异步进度仍保持单调。新增4项回归，最终共361项通过。

## CI candidate regression correction

Final-head CI38094588522 failed before Web export: legacy save_candidate expected snapshots omitted resident_rest (80 checks / 4 failures). Updated both clock setter expectations with explicit schema/day/cause, retaining full memory/file/backup equality and failure-write checks. Added normalized-JSON rest provenance checks after actual native reload. Windows isolated profile is now accepted only with explicit YOUJIA_TEST_ISOLATED_DATA and a strict child-directory boundary; Linux disposable XDG guard remains. Local save_candidate82 and rest_context43 pass; logs archived here. This supersedes the earlier CI-pending status, not a claim of full CI success.

## Latest-main integration and contributor review (09:00 round)

Merged main195b579f6a54ea92ea17980c5dcb8f59256895f6 (Assistant728 mist and725 loading evidence) into this branch, preserving authors. Resolved only completion-registry append conflict by keeping both rest and mist registrations. A clean editor import was necessary for the new NearPathMist class cache; after import rest43 and mist34 pass, save_candidate82 also passes. These are native checks, not new ordinary gameplay evidence.

Grok final reviews:718 47b8bf6e31d9f1c1f39f35efc71dd7a88d096a3e still fails suite I18n identifier at32;720 0aa59d9d6510e8cfd9acb8ebf0b0bf3462bbd6fa fails before/at_end type inference at61/65;723 6afafd1ecc397a2acfafbdae7163de6c4c6a8674 passes37 and native OpenGL render shows very faint isolated smoke. No real roof/night/phone acceptance, no merge. Original PR comments6104061250/6104061441/6104064568. Logs and actual GPU on/off/decay frames under grok-review; the block drawing is only the author demo, not courtyard art.

PR722 public source45673209c8e88b4f6a8320cb9bf4d1020de53bc6 verified against live manifest/HTML/Pages Git blobs, actual PCK69579160 bytes SHA2563fb38ff54910ece8c1398b63acb4b1057823973c1605e399812d2beac8e9b80b, engine and12 storage/loader modules. Publish38093760089 andPages38094697652 succeeded. Newer Assistant728 publishing is separate. No duplicate daily email.
