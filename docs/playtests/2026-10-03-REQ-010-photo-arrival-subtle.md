# 留影动效克制修正：候选验证记录

- Owner：`CODEX-LEAD`；PR #102；已合入并发布（首次核验版本 game-562ad5d）。
- 整合主线：`3350c892cd45f1c8fb7f2db14bd8fc984fb8e34d`；运行时实现与此前草稿相同，保留 REQ-017 道具快照修复和傍晚云资源。
- Godot：4.7.2 stable；Chromium 1280×720，SwiftShader，本地 Web 导出。

## 回归与实际操作

`GODOT=/tmp/youjia-godot-472/Godot_v4.7.2-stable_linux.x86_64 npm run verify:daily` 退出 0。全量涵盖步态、动物、草互动、真实照片、输入、场景热点、鹅马演出、低动效快照及桌面/手机视口。之后补一项淡出阶段位置/比例断言，独立照片保存专项 46 项全部通过；无 SCRIPT ERROR 或 ERROR。

浏览器从新档进入院子，点击草堆拿草，用空格执行当前“去喂草泥马”行动并等待真实走近/喂食。首次成功保存后出现同一张真实成片；中心边界约 (520,210) 到 (760,510)，大小 240×300，随后原位消失，没有向左下相册飞行。持续帧采样与原生淡出阶段比例断言互为补充，不声称单张截图能证明完整时序。打开手账仍能看到同一天、同一事件的照片及题词。浏览器 pageerror/console error 均为空。

- [中心成片](2026-10-03-REQ-010-photo-arrival-subtle/web-photo-developed.webp)
- [展示结束](2026-10-03-REQ-010-photo-arrival-subtle/web-after-photo.webp)
- [已保存的手账](2026-10-03-REQ-010-photo-arrival-subtle/web-saved-album.png)

移动、暂停、打开相册和低动效的中断/持久保存由照片专项覆盖；浏览器本轮实际操作覆盖普通模式喂食、显影、结束和打开手账。没有伪称本轮做过真机触屏或所有低动效浏览器路径。天空观察和鹅马的独立镜头保留原规则。

## 候选导出

导出成功，PCK 13,814,384 字节；SHA-256 `0824663b31820d85d8eab5fa52cdb0edfcc460e2645c7a400487c95f3eb52977`。这是本地候选，不是公开版本或发布哈希。补充测试和文档不会改变本候选运行时逻辑。

后续同步 main `ad33975`，仅增加 REQ-017 发布台账，无运行时改动；两方追加的决策段落均手工保留。

## 合入/发布门禁

共享需求清单和台账已补 REQ-010-SUBTLE 子项，父 REQ-010 历史 Owner 保持 MANUS。独立最终 SHA 已批准并满足合入门禁；正式发布结果见下节。

[决策与协调](../decisions/REQ-010-photo-arrival-subtle.md)。


## 独立审查与首次正式发布

- Reviewer `CODEX-LEAD-REVIEW-PR-102` APPROVE 最终 SHA `d0a9de7d15e8fffd49fc07acae96e5339b3e32cf`；独立复跑保存 46、渲染 1332 及临时移动/相册取消等 51 项通过。[审核记录](https://github.com/narutojzm1-dot/youjia/pull/102#issuecomment-5967084160)。
- [PR #102](https://github.com/narutojzm1-dot/youjia/pull/102) 合入 `562ad5d3d1cce77e9001b558abd50e5efb7b356e`。
- [Actions 37109042156](https://github.com/narutojzm1-dot/youjia/actions/runs/37109042156) 完整回归/导出/发布成功；[Pages 37109230817](https://github.com/narutojzm1-dot/youjia/actions/runs/37109230817) 成功。
- 2026-10-03 16:20 左右（Asia/Shanghai）公开清单 sourceCommit 与合入提交一致，入口 data-build 为 `game-562ad5d`。公开实际 PCK 13,814,368 字节，SHA-256 `8b3c5edb0a8518ecba4f4b6d3292918c3406b9eb3b3e85261ec3ebe4f8bbf8cf`，与 gh-pages 分支对应文件的独立下载哈希/长度一致。此正式哈希与本地候选分别记录，不宣称不同构建字节完全一致。
- 公网 Chromium 1280×720：确认正确 data-build、收到首帧、点击标题进入院子；pageerror/console error 为空。[正式院子截图](2026-10-03-REQ-010-photo-arrival-subtle/public-yard.png)。实际拿草/喂食/显影/手账证据是同运行时本地候选；公开检查覆盖版本与启动，不伪称公网重做全部交互。
- 本节保留首次发布版本证据，不覆盖后续其它 Owner 的发布。REQ-010-SUBTLE 完成，天气同构图/过渡及动物表情仍分别由 #51/#30 跟进。
