# PR431 相册短横屏集成候选

Agent-ID: CODEX-LEAD（内部实施 host_budget_impl），原作者 GROK-CONTRIBUTOR。按原PR431明确交接及Leader6000188749接收，保留作者 `db89cf3995ee3e77aa55567c92235f5d3f580d3e` 祖先，从main `96f090a63e0997244924a7463bd0e52a025b57b1` 顺序合入。运行候选 `95a3b0950f7612263e8f3939664fdd1b0906e73f`。

仅相册外框新增_fit_album_frame及_layout调用和紧档常量；没有改_input、_start_holiday、Cloud、照片卡、照片保存规则。补daily永久album_short_landscape入口（100755）、REQ034及专项UID。原作者52319/full只作为原提交证据，本组合门禁另记。

隔离工程位于/dev/shm，既有start-once源码只用作Git对象只读来源与复制可重建Godot缓存；不修改其源码/cache/8200导出。首次纯远端partial checkout下载慢，在尚未完成checkout时停止，改用本机只读对象alternates，随后正常checkout与merge，非产品故障。临时docs/.gdignore避开文档图片导入；生产preset本就排除docs，环境标记不提交。

组合回归及独立普通Web结果待追加。没有把受控中英文几何fixture当真实英语UI或自然照片事件；常用尺寸之外的极小窗不做无依据承诺。未发布、未自审。

## 本组合实际门禁

Godot4.7.2 import exit0；严格9专项driver整体exit0（逐suite隔离用户目录）：album_short_landscape52319、album_layout45914、photo_moment_save46、photo_home75、interaction_photo110、photo_arrival_fit418、photo_arrival_combo656、holiday_start_once14、save_feedback50均通过，loading shell Node通过。日志/退出码/driver随档。这里没有重复不受影响完整daily；最终正式CI仍跑全套，原作者全量结果不冒本组合全量。

生产Web export exit0，独立/dev/shm/album431-export/8201。PCK27086076字节，SHA256 `8e64a09de7735786a50c98ed6ae7a33c297bc422358693d4c6eb762df78051da`。export-files.json为原始HTML index时点，后续根本地stamp另记，不是正式发布。普通Web独立验收待追加。

## 独立普通 Web 候选 QA

[原始档案](web/README.md)由review304完成，全部原件逐字节复制验证见web-copy-verification.json。两页实际PCK均为8e64；四首末源HEAD是71b636d（相对95a3导出仅11文档），没有为匹配断言改检出。最初metadata错误断言在UI执行前停止，保留为排除的preflight失败；final是首个完整UI流程，exit0/errors=[]。

普通自然羊互动产生一张照片；568×300、640×300、568×320相册纸面、题词、页脚和按钮完整；真实合上/重开、恢复桌面、page.close后新page正常入院再翻册，原羊照可读。review304逐看8原PNG，实施者另外看568×300和真实重开原图。仅视觉保存证明，没有DB字节比较或整个浏览器重启。只有1张中文照，未翻前后页、未覆盖全部长题词/英语/触屏/物理手机；广覆盖原生fixture另列，不混成自然体验。

桌面恢复后院景背景右偏为既有#400观察，未推断原因，不属本片修复。相册结果与院景问题分开记录。候选门禁和有限体验完成，待最终完整SHA独立终审/正式发布。
