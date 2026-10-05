# PR438 正式发布与有限回归

Agent-ID: CODEX-LEAD（内部实施子代理 host_budget_impl；非外部 Assistant 接管）。适用 #150/#305；不关闭父单。

438 最终 `e43f1901ddf1c6f7847dea18b5df51aeaf7a6670` 经[独立批准](https://github.com/narutojzm1-dot/youjia/pull/438#issuecomment-6001034317)后合入 `83b893035d76e9cdd1966b724fb748fab5e3ef59`。Actions37359641323、Pages37360554417成功；实际公开PCK 27088028字节、SHA256 `4622287c466f8f736b9ca0325729875ebd468a5127ced6584829281e5faee5f8`，十个存储模块逐字节来源核对见 release-83b8930.json。

439组合 `089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21` 的正式公开核验见 pr439-public-release.json 与 fresh.log；PCK27088396字节、SHA256 `fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8`。CI71验证＋1导出、最终Pages成功；早期Pages in_progress、两次传播/缓存不一致失败日志原样保留，不计核验成功。

[089d受控故障原件](controlled-fault-089d/README.md)：真实授予write8后，cleanup9单次精准put故障→resolve rejected→一次普通“再确认一次”→唯一替代10 confirmed/ack cleared，同页面板消失。真page.close/new page后完整current完全相同、gen10、落羽1圆石1、session:null，两次records仅current无intent；errors=[]、exit0。属于受控存储故障，不是自然线上事故或物理断电。[83b自然空篮尝试](excluded-empty-83b/README.md)未触fault，exit0不计故障通过。原图/驱动/源绑定/审计完整保留且逐字节验证。

[普通无故障原件](ordinary-normal-089d/README.md)：同089d两页各首末manifest/HTML核对，每页实际PCK核对；自然羊照入册、松果1返院，真实关页新页原照仍可读。after-return、settled-return、reopened、settled-reopened四份完整DB JSON原字节一致，gen9、仅current、session:null、水位1、松果1；before-return gen6含intent中间采样原样保留。errors=[]、exit0。输入是touchscreen.tap与键盘E/T混用，不称全触摸、真机或浏览器进程重启。

原件普通README“未知字段拒绝保全由Native及另一独立受控故障档案说明”须按这里的严格区分解读：未知扩展INVALID只由Native51保全专项证明；受控Web档案证明另一条I/O失败恢复，不证明未知扩展Web路径。

根维护者已于2026-10-05T19:25:01Z实际发送稳定性邮件，message/thread `1a10d86cea32b284`，去重键 `milestone:cleanup-invalid-preservation:game-089d453`；[公开回执](https://github.com/narutojzm1-dot/youjia/issues/146#issuecomment-6001504039)及本目录两份mail JSON记录此事实，仅收件人me。邮件发送时标题439四视口验收仍在途，本档不回改历史为已验，不重复发送。

原生51专项验证未知嵌套字段导致INVALID时原文件/记录不变且零后端调用；Web受控真实intent写入失败验证有限重交，是两条不同路径。作者Godot4.7.2完整70门禁与独审4.6.3复跑51分别见原[候选档案](../2026-10-06-cleanup-invalid-preservation/README.md)及独审原文；不混引擎版本。

不安全cdec的Actions37356141984被取消，不等于回滚main。之前候选普通链首次Target crashed/exit1原件保留于候选档案，后续短链不抹去该次中断，也无充分证据归因游戏或OOM。

后续交接：根维护者提交独立文档PR并委托最终SHA审查，本实施者不自审、不推送/合入。#150/#305父单继续保留剩余领域/矩阵范围；本档不覆盖全部未知格式、全部重试竞争、三物件完整矩阵、物理断电、真机或听验，不据此关闭父单。未改生产代码，无须重跑Godot；原始证据字节与清单校验、git diff --check作为本次文档验证。

本目录 archive-manifest.json 为除自身外所有归档文件SHA256/字节；copied-originals-verification.json 为三个QA目录逐文件复制核对，共69个文件（含各自清单）。旧失败/中间采样保持原文与原图，未改原QA记录。
