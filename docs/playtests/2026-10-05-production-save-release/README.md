# PR336 生产持久化发布与摄影收口

CODEX-LEAD，2026-10-05 09:49–09:56 UTC；这是白天里程碑验收，不代替23:00日版本。

## 来源与发布

- PR336最终 `720db375618062f1941d97fe664ba4b84f7722c1` 经独立 CODEX-LEAD-REVIEW-PR-336 [APPROVE](https://github.com/narutojzm1-dot/youjia/pull/336#issuecomment-5991959878)，合入 `d2425099947b7ca7d17e8ea0cbd928e477e3ebf1`。
- [Actions 37291830245](https://github.com/narutojzm1-dot/youjia/actions/runs/37291830245) 和 [Pages 37292355193](https://github.com/narutojzm1-dot/youjia/actions/runs/37292355193) 成功。
- 实读公开manifest：`game-d242509`、source=`d2425099947b7ca7d17e8ea0cbd928e477e3ebf1`、publishedAt=`2026-10-05T09:47:19Z`。
- 实际公开PCK 22,003,712字节，SHA256 `17c64e4c061b340c70bf62811e5a7580b9eb30ea8d3e602b61d959d8407c2084`，与部署raw相同；10个 `save-d242509` JS模块实际下载均与source文件和manifest哈希一致，Content-Type、HTML模块入口一致。[原始报告](public-release.json)；[复核脚本](verify-public.py.txt)。
- 实际结果先记入[PR336](https://github.com/narutojzm1-dot/youjia/pull/336#issuecomment-5992168396)，再由此独立PR归档。文档合入不倒推改变上述线上来源。

## 自然浏览器链路

Chromium 1280×720，全新独立context，真实标题入口和鼠标按钮，不写游戏状态、不注入种子或时间。

1. 羊：入院→轻抚→照片→手账→暂停→返回首页确认→首页→重入→手账→真正关闭页面→同context新页→入院→手账。已查看[回到首页](natural/title-return.png)与[关页恢复手账](natural/reopened-album.png)。
2. 只读IndexedDB观测：仅 `youjia-save-host-v1`，没有创建旧 `/userfs`；generation 2→3，album=`sheep_pet_gentle`及photo_moments完全相同，errors=[]。[摘要](natural/summary.json)、[记录](natural/records.json)、[驱动](natural-browser.py.txt)。
3. 首次鱼：正常点池塘，实际截图识别收杆提示后点击；看到首次鱼照片原位显影→手账→真正关页重开同照片，errors=[]。[过程与限制](first-fish/README.md)。原始PNG [显影](first-fish/capture-04.png)、[消退](first-fish/capture-05.png)、[恢复手账](first-fish/reopened.png) 已看。18帧两处背景固定大小裁块平移搜索最佳(0,0)，支持构图稳定，不当连续录像或每像素相同。

## #40 验收范围与证据映射

- 真事件/真快照/当天双语随笔、旧11规则及v1/v3回退、重复不重播、低动效/中断/窄屏：PR43/102及最终生产daily中的photo_home46保留通过；见[早期马事件真实体验](../2026-10-02-REQ-010-photo-diary.md)和[原位克制显影](../2026-10-03-REQ-010-photo-arrival-subtle.md)。原单早期“飞向相册”已按后续用户“仅克制生成动效”收敛为原位消退入册，不恢复强移动/缩小。
- 普通动物：PR320修羊主体匹配并有[公开自然照片证据](../2026-10-05-photo-species-release/README.md)，本次正式宿主再次验证照片及日期恢复。
- 首次钓鱼：本页新增公开自然链路；大鹅骑马：既有PR233三阶段Web与92项[结果](https://github.com/narutojzm1-dot/youjia/pull/233#issuecomment-5980979769)，属于受控触发，不能冒称本次自然遇见。
- 静观天空另一路1.14推近由PR308修复，见[对照](../2026-10-05-quiet-sky-scale/README.md)及已归档公开发布；不混同马贴图大小问题。
- #40 摄影本身完整验收已具备，按此收口。#48自由构图、#45/REQ-011新关系故事、#180完整姿态资源、#51阴天修画各自保持原单，不随#40关闭。

## 平台与父单未覆盖

完整daily、Native200/恢复24、桥接45/legacy22、实际受控abort重试/旧页分歧下载/手机视口材料详见[合入前完整证据](../2026-10-05-production-save/README.md)。旧源只读封存；新快照只在确认后入内存；未知结果保留待解决，不把接受意图当保存成功。

本次公开体验只覆盖上述Chromium路径，未验证Safari/实体触屏、操作系统断电、所有配额环境或真人听感。#149原始可靠提交/恢复范围在下述补证后完成；#150物品身份/去重与各业务（含Cloud探索）真实消费矩阵独立继续，未来平台覆盖不反向无限扩大#149；共享宿主已发布，不再是探索整条主线等待原因。Cloud322/342仍独立开发，未合入部分不称可玩上线。

## 已通知

里程碑 `youjia-production-save-336` 已在 2026-10-05T10:04:04.383479+00:00 通过 Gmail to: me 成功发送，message ID `1a10b84e92115c73`；[去重记录](https://github.com/narutojzm1-dot/youjia/pull/336#issuecomment-5992287075)。邮件明确提交中关页仍在补验，不将此前证据扩为该项完成；后续补证写本页，无需重复里程碑邮件。私人邮箱不公开。

## #149 最后一项：真正提交中关页恢复

初次审计没有用“保存完成后关页”代替原单要求。随后在公开 `game-55cb7ce` 补齐[实际实验](inflight/README.md)：先正常轻抚羊得到已确认A（gen2），再真实暂停返回产生B（gen3）。仅测试层在真实current put发出后用同事务40次get保持其尚未complete；关页前记录put_success=true、transaction complete=false、abort=false、真实prepared intent，然后实际page.close。新页恢复整个封套严格等于A，无部分B、无残留intent，羊照片可见、errors=[]。

[摘要](inflight/summary.json)、[原始记录](inflight/records.json)、[驱动](inflight/driver.py.txt)、[关页前](inflight/inflight.png)、[恢复照片](inflight/reopened-A.png)。只读观察加受控延长真实事务，不写存档值、不主动abort、不注入世界状态；不是物理断电证明。新profile没有旧seal，不用此项冒称老来源场景，老来源保全由迁移独立用例覆盖。失败坐标探针单列且未计成功。

该构建来自PR346仅隔离标定工具/文档的后续合入 `55cb7cebcf8b61f8e524f38121c997b6bba8553c`；[Actions37293308869](https://github.com/narutojzm1-dot/youjia/actions/runs/37293308869)/[Pages37293814016](https://github.com/narutojzm1-dot/youjia/actions/runs/37293814016)成功，实际下载PCK SHA256 `18a240270399972993bdac2ef2bc828da72003642df7d7548a667060a56de976`、22,003,712字节，十个模块与源字节及manifest一致，见[原始复核](public-release-55cb7ce.json)。不要把此浏览器运行标成d242509；PR346没有扩大生产可走区。

#149原验收映射：真实tmp/rename故障→Native200；坏主好备继续保存/永久保全→恢复24及Native200；写失败不先提交业务内存/历史字段保留→候选80与photo_home46；同origin实际保存重开→本页natural；提交中关闭→本页inflight。至此按原范围可验收收口，#150领域事务、未知非照片提示UX和未来平台测试各按自身范围继续。
