# PR391 共享 cleanup API：正式发布与普通路径验收

**共享接口已独审合入、冻结并发布；普通保存/照片路径已体验。探索领域cleanup重试和Main提示恢复尚未接入，不能据此宣称故障修复完成。** #150/#305保持开放。

## 来源与发布

PR391最终 `9d2dcd88e447628f610b230b397661c9cf2469ae` 经[独立审核5995798603](https://github.com/narutojzm1-dot/youjia/pull/391#issuecomment-5995798603)，合入/公开源 `4fa150819c304b03fb6a36a149e71d4bcd911000` / `game-4fa1508`。

- [Actions37319685225](https://github.com/narutojzm1-dot/youjia/actions/runs/37319685225) success，原结果 [workflow-actions.json](workflow-actions.json)。
- [Pages37320835249](https://github.com/narutojzm1-dot/youjia/actions/runs/37320835249) success，gh-pages `d5926d04489e5c96505ba88484e87478d4295e6a`，原API响应 [pages.json](pages.json)。
- 发布时间13:57:19 UTC；Leader实际包核验13:58:45 UTC，见 [package-verification.json](package-verification.json)。PCK **25,274,848字节**，SHA256 `0f44318330faa48e80097f1e701faa2294e7bfd98e07e50b842dbcfbbcf9d167`；公开/raw字节一致，HTML/storage入口和十模块public/raw/source/MIME一致。未再复制PCK。

[共享契约](../../architecture/exploration-cleanup-commit-contract.md)及[原专项/组合门禁](../2026-10-05-exploration-cleanup-contract/README.md)保留各自真实运行树，不将既有候选测试冒称新做native全套。接口冻结范围是expected完整记录/水位及合法idle目标、队首CAS、明确写前拒绝，不增磁盘schema。

## 独立公开烟测

review301原始报告 [qa-notes.md](qa-notes.md)、[run.py](run.py)、[UI坐标动作](actions.json)、[两页版本绑定](page-builds.json)、[完整只读DB](records.json)、[原日志](console.json)均按原字节归档。

全新context桌面Chromium/headless/SwiftShader，普通鼠标进入→点羊自然生成照片→[打开手帐](album.png)→[暂停](pause.png)→[回门口确认](confirm.png)→实际“好”并见[标题页](title-return.png)→正常进入[续玩原照](return-album.png)→真page.close后新页再校验源并见[恢复原照](reopened-album.png)。两页均严格上述完整公开SHA，无业务状态/存储故障注入。

前current gen2，正常回标题保存后恢复为gen3；payload仅holiday_day_elapsed变化，album及完整photo_moments完全相同，单条sheep_pet_gentle未重复，日期/题词保留。只存在youjia-save-host-v1，没有旧/userfs；records仅current、无intent。**不称整个封套字节相同**，时间保存确实改变generation和提交封套。最终driver exit0，page/console errors为空。

原始attempt1错误地把院子截图命名title-return，不能证明回标题；最终新profile完整链已纠正。早探针未纳入本次通过项，保留于 `/workspace/cleanup-contract-public/attempt1/`，不是已证实产品缺陷。本目录六张必要原图不重编码，所有原件字节/hash见 [archive-provenance.json](archive-provenance.json)。

## 尚未完成

本次没有调用新cleanup API，因此不证明[既有cleanup异常](../2026-10-05-exploration-idle-cleanup-public/README.md)已修。Cloud仍须实际接收并登记领域op、unknown/resolve/ack及受限重交；Main须按精确cleanup身份/失败revision清提示。未收到领域接收回执，不称已开工。不是听验、真机、物理断电或完整故障矩阵，也不是日版本节点。
