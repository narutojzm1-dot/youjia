# PR402 独立最终审核

结论：**APPROVE**

Reviewer：CODEX-LEAD 内部独立审阅代理 `horse180_repro`（未实施本切片）。

精确远端 head：`80238c32abfe7feffe2c5361ee1220a98205c65a`

精确 tree：`4f9525e54eb69d11a78b2994c7a09a43d7b43fc4`

通过实际 fetch refs/pull/402/head 核对，两者均匹配；本地 f85dfed925a309228b1362d468fd4073da1c7f96 tree完全相同；原作者c496ec19054ea1cbd34661a4f7abf21bf2342acb是最终head祖先。未修改提交或执行合并。

## 审核依据

- 复核最终原生模块：parent viewport deferred size_changed在引擎位置重算后适配；先恢复内容minimum并清size可缩小/桌面恢复；embedded_border+title_height纳入外框；删除前检查实例/queued，tree_exiting断连接。Web早return及原有新页URL/noopener语义保持，Main/Host/Cloud不在运行代码改动内。
- 预审时已独立实际运行同一运行模块：正式suite124/124 exit0；额外owner整树删除+排队resize20轮、双关闭+排队resize10轮，60/60 exit0，无ERROR，连接数回基线。脚本日志与预审原报告 `/workspace/pr402-independent/` 保留。最终与fdc12c043352059ad91877c0472046fe7ce73410的 scripts/scenes/project.godot/test/tools/assets diff为空，不为只变文档重复整套测试。
- 最终 validation.json 中模块、suite、daily脚本三SHA256逐项与最终git blob重新计算相同。归档 full-daily.exit/export.exit为0；实际阅读785行完整daily与410行export，未见ERROR/FAIL。licenses124、title1541、confirm562和既有存档/桥/加载等门禁在完整回归中保留。
- 正式候选导出绑定fdc12c源，PCK 27,080,504 bytes / SHA256 `4889dcb5fb3bf844d98d7d340374fd973af31a6d065e13b25283634001bb7cea`，十模块记录齐全；Web普通mouse点击标题声明进入HTML的原driver/result/exit/原图保留，前后build与实际PCK匹配、errors[]。已亲看最终归档Web标题/HTML原图，确认内容实际可见。不是宣称此Web路径执行了原生dialog。
- 之前亲看最终X11短横/同窗竖屏原图，标题/X/正文/OK完整；正文与监听关闭证据对应最终适配实现。历史同窗不适配、同步refit失败、client-only标题裁切及原日志均保留，没有把旧失败候选当最终通过。
- REQ032、daily永久门禁和docs准确限定默认主题/列出尺寸；不冒任意主题、极小窗、OS装饰或真机验证。没有把隔离native状态设置包装成完整普通玩家端到端。

## 非阻断说明

README顶部“未推送”是原集成阶段记录，现已远端提交；不会影响代码/验证结论，但发布收尾可按实际状态补记。此审核仅批准上述精确head；HEAD变动须重审。公开Pages发布、公共manifest/PCK最终核验仍由合并后流程完成，本审核不宣称已发布。
