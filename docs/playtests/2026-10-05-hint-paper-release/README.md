# REQ029 目标提示纸片正式发布验收

原实现GROK-CONTRIBUTOR，CODEX-LEAD按作者明确交接补门禁/真实Web并集成。PR362最终`adbb0b279c45f9f9f4a446889cfd06fc6f99a604`经独立`CODEX-LEAD-REVIEW-PR-362` APPROVE（评论5994085477），CAS合入`1a3842c63558fa68a68ca41c2da58f4c5a254929`。目标纸片现在随文字实际行数伸缩，横屏短文收紧，窄屏换行留足高度；原字号/宽度/输入语义保持。

## 构建与公开文件

- [Actions37307177944](https://github.com/narutojzm1-dot/youjia/actions/runs/37307177944)、[Pages37307813179](https://github.com/narutojzm1-dot/youjia/actions/runs/37307813179)实际success；完整状态见actions.json/pages.json。
- 公开`game-1a3842c`，源完整SHA同上，Pages提交`b9430c2adba2cd01288b72f36e28e8464f547f2b`，manifest publishedAt `2026-10-05T12:11:19Z`。实际下载校验时间UTC12:12:44，原始release.json保留。
- PCK **25,264,372 bytes**，SHA256 **6198ad204f2d0a9c83633b8c9c8445c652ffc54bb4704fdc3b4ab591294ef42f**。公开与gh-pages raw字节完全相同；十个存档模块的公开/raw/对应源SHA逐字节相同，MIME/HTML构建及versioned入口均核对。没有把候选PCK哈希照抄为公开结果。
- [试玩](https://narutojzm1-dot.github.io/youjia/?v=1a3842c)。本归档后main可含文档提交，但本轮实际游戏来源仍上述源码SHA，不为记录自身SHA循环发版。

## 验证与覆盖

此前生产候选已完成Godot4.7.2完整daily exit0：hint4653、album45914/0、title251、daylabel173、hidpi102、save_feedback21及既有门禁，详见[候选证据](../2026-10-05-hint-paper-fit/README.md)。原作者称未修复版本4117失败，本轮没有重跑该变异对照，不混称独立复测。

发布后内部pet30_impl在Chromium实际跑四组390×844/844×390各DPR2/3，每个独立页面实读manifest及HTML绑定完整source；正常点标题入院、点击长短目标、同一实例横竖旋转及打开相册，24原图全部逐张查看。四组errors=[]，driver exit0，无业务状态/文案注入。390-DPR2恰好经正常抚羊取得首张照片，旋转后实际显示羊照片和日期文字；其余三组空相册路径正常，未把偶遇变成必现承诺。Leader另看窄屏照片横屏相册及宽屏草堆目标原图。

边界：生产当前没有玩家语言切换入口，英文仅native全部文案几何；非实体手机/真人听验。普通画面点击及相册可用，不等于精确在纸片下构造目标的穿透测试。没有重跑所有存档故障、历史照片全矩阵或将本次截图库替代Assistant351/365的独立验收。代码方法已释放，后续功能按原issue认领。

## 同轮认领表校准

只校准requirements当前条目：鹅首片/三热点实际已交、旧MANUS/LOCAL资源归属、308已经移除的1.14缩放、125标定已交和资源核对待回执、119–123候选与实际行为区分；保留历史原作者。鹅马已获后续批准并实现99/173，剩余组合180属Assistant；不能继续把旧71时期的“未批准”当当前状态。未关闭长期父单、未批准新玩法或资源。#30下一鹅投鱼关注另在独立分支，本文不提前宣称其发布。
