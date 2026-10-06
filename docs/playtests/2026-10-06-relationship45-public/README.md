# 2026-10-06 · REQ-011 普通牵引关系记忆与公开关页恢复

**结论：首个已批准切片的普通牵引→关系记忆→关页恢复路径通过一次有限实测；后续 10% 停留回响的可感知性仍未覆盖，#45 保持开放。** 本次没有修改运行时代码，没有新增故事、关系 UI 或美术，也不关闭 #150 的完整业务组合验收。

Agent-ID：`CODEX-LEAD` 下的独立 QA 子代理 `relationship45_qa`。原单认领：[issue #45 回执](https://github.com/narutojzm1-dot/youjia/issues/45#issuecomment-6002058484)。执行北京时间 2026-10-06 04:21–04:28；精确 UTC 与每步单调时钟见 [result.json](result.json)。桌面 Chromium、1280×720、DPR1；鼠标及真实键盘事件。浏览器 context / browser 已关闭，驱动退出码 0，page errors 和 error 级 console 均为空。

## 正式来源

- sourceCommit：`089d453dc7b4ac8a8b5dbe8fc250d032c6e80b21`；HTML `data-build`：`game-089d453`。
- 两个实际页面，各自打开前与结束后均读取公开 manifest、HTML，并实际下载公开 PCK。四次均为相同正式源，PCK **27,088,396 bytes**、SHA256 **`fb7b1473608a999f76eb46a8fd18b7f6fa2e8456f0508ee0db0693b2cddba1f8`**，HTTP 200。
- 全部绑定原始字段在 [result.json](result.json) 的 `bindings`。这是 QA 独立 HTTP 下载与页面入口核对，不声称截获了引擎实际读取的响应体；不替代发布 Owner 的 raw/source/storage 模块核验。
- 本次期间后续 main 有 PR445 等后台活动；首尾实取仍全是 `089d453`，未把 main 或正在发布的新源当成本次运行版本。

## 普通 UI 路径与现场图

同一个全新 profile，事先限定最多三次牵离→带回→放开，每次放开观察15秒；首轮成功后不使用剩余次数，不重建 profile 挑结果。无 seed、游戏时间、位置、动物状态或存档注入；没有调用内部游戏方法。IndexedDB 全部使用 `readonly` 事务，只作为独立技术证据。

1. 标题进入院子，普通点击羊自然获得首照，打开手账核对。关系此时为空：[首照手账](02-album-before.png)、[采样](02-before-relationship-db.json)。
2. 点击画面中的羊驼，旅人自然走近并开始牵行；HUD 实际显示“松开牵行”：[牵行开始](attempt1-leading-near-start.png)。初态两动物已近，因此按既有条件先普通点草地牵离。牵离图中羊驼与鹅间距明显拉开，约170屏幕像素；没有读取或改写内部坐标：[牵离](attempt1-leading-away.png)。此时[只读关系仍为空](attempt1-away-db.json)。
3. 普通点击鹅附近可走草地，带羊驼回到附近：[带回](attempt1-leading-returned.png)。真实按 Space 松开，HUD 和通知显示已松绳：[放开](attempt1-released.png)。15秒后采样中唯一关系标记变为 true：[现场](attempt1-after15s.png)、[技术采样](attempt1-after15s-db.json)。截图证明实际牵行和相处路径；隐藏关系标记是否落盘由独立只读证据说明，不伪称画面存在关系提示。
4. 继续自然静观90秒，每15秒一帧。羊驼后来离开鹅附近；保留全部六张 `linger-observation-*` 原图，[90秒末帧](linger-observation-90s.png)。未通过概率刷取或改变条件寻找回响。
5. 打开手账暂停世界，在[关页前手账](05-album-before-close.png)核对原羊照。执行真实 `page.close()` 后在同一 context 创建全新 page；重新进入院子、打开手账：[重开手账](08-reopened-album.png)。再次等候5秒采样，随后关闭页面和整个浏览器。

自然游玩期间天气自行变化，既有 `llama_overcast_goose_annoyed` 与 `goose_horse_mount` 照片也被正常保存。这些是原有独立摄影事件；本次没有逐帧验证其完整演出，也不把它们当成新增关系故事或10%停留回响的证据。

## 只读存档结果

[comparison.json](comparison.json) 保存逐样本 keys、generation、文件哈希、照片内容哈希及比较结论。

| 采样 | generation | 关系标记 | 照片数 | records |
|---|---|---|---|---|
| 恢复声音设置后初始 | 1 | 空 | 0 | current |
| 原羊照入册后 | 2 | 空 | 1 | current |
| 首轮牵离 | 4 | 空 | 2 | current |
| 首轮放开15秒后 | 7 | true | 3 | current、intent |
| 自然观察90秒后 | 8 | true | 3 | current |
| 手账内关页前 | 8 | true | 3 | current |
| 真关页后新页面标题 | 8 | true | 3 | current |
| 重开院子及手账 | 8 | true | 3 | current |
| 重开手账再等5秒 | 8 | true | 3 | current |

末五份完整数据库 JSON 原字节完全一致，SHA256 `54314ab26758f998660c746c930e6d5de752210c7288c03b5e15e417cb781244`；关系键仅 `goose_llama_shared_space_after_player_lead: true`。原羊照在所有含它的采样中内容哈希一致，且关页前后普通 UI 实際显示同一照片。这里只陈述末五份稳定 generation 8 采样时 `records` 仅有 `current`；首轮放开15秒的早态采样仍含 `current`、`intent`，原件完整保留，不据此推断未读取的内部队列状态。

## 明确未覆盖

- **后续10%回响是否自然出现且玩家能辨认，仍未覆盖。** 既有普通安静停留与回响延长的时长范围有重叠，本次静帧与记忆位不足以把一次停留归因于回响；不能把“记忆已存”写成“后续变化已体验”。
- 未覆盖重复牵行去重的完整矩阵、读旧版关系档、受控存储失败、未知字段、并行标签、浏览器进程退出、物理断电、触屏/物理手机、主观听验及全部动物互动。
- 当前原有晴阴构图差异、镜头画面偏移等仍由各自 Owner 跟进；截图不表示这些问题已修复。
- 本报告补齐2026-10-03旧报告中普通浏览器牵引与持久记忆路径的证据，保留旧报告的历史原文；不冒称当时已经完成这次体验。

## 同页 #444 最小基线旁证（与关系结论分开）

开始关系测试前，执行普通 Tab 与空白画布点击后 Tab，保留 `444-baseline-title-tab*.png` / `444-baseline-title-canvas-tab.png`。这些画面没有可明确识别的新增焦点框，**不能声称完成了“走进院子按钮实际聚焦”的基线验收**。随后正常 Escape 暂停，点音乐关闭、移开鼠标截图，再点音乐恢复、移开鼠标截图，最后普通点击“继续待着”。[音乐关后](444-baseline-music-off-after-click.png)及[恢复后](444-baseline-music-restored-after-click.png)文字均可读；本轮**没有复现旧版白字缺陷，也不是 PR444 候选验证**。关系初始 DB 在上述设置恢复之后才读取。此旁证仅供后续候选对照，不增加关系尝试预算。

## 原件与复核

所有 PNG、九份完整只读 DB、[驱动](run.py)、[实际日志](driver.log)、输入/来源原记录和比较结果均保留。[archive-manifest.json](archive-manifest.json) 列出归档文件实际字节与 SHA256；未纳入 PCK、导出包、浏览器缓存或私人邮箱。报告与链接同步通过独立文档分支 PR 审核，运行时代码不变。
