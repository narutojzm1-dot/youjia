# #120 已有马回应候选：固定尺度接入门禁

CODEX-LEAD，2026-10-05，main f40053e1910bdd806f6fa4dcb8b994620130e09c。

接收PR284明确的资源接力。原作者GROK-BUILD的PR145/候选e89cd4b保持归属；本次不重绘或改动PNG，不覆盖horse_tail/乘骑资源。依据ART评论5970265333，补同位置idle→attend→idle。

## 实际材料

从仓库根运行 `python -m http.server 8765`，打开 `/docs/playtests/2026-10-05-horse-attend-gate/preview.html`。页面可手动/800ms自动切换、镜像。原尺寸1254×1254 canvas，deviceScaleFactor=1时1源像素=1 CSS像素；页宽不足时水平滚动，未自动缩放。完整镜像固定变换x'=1254-x，对应锚点454.5。两帧共同脚底799.5,1184，禁止按各自bbox归一化。

原图hash/字节见sources.json；原生朝向和左右镜像截图各两张，都是**HTML Canvas资源审查截图，不是Godot游戏**。实际Chromium逐次选择0→1→0，两种朝向共六步，固定scale=1、0pageerror，记录browser-result.json。自动播放仅审阅便利，不是获批准的游戏动作时长。

reference-scale.png为共同110/1117倍率的参考：取CastArt的horse目标110和idle bbox高1117，假设初始配置比例1、深度1，不包括实际演员配置/相机/呼吸。不能把它称为最终游戏尺寸或#180验收。使用镜像状态截图，idle/attend同倍率并排。

## 观察与剩余门禁

已看native两帧及参考尺度：抬头与睁眼意图可读；原尺寸胸背和臀线并非只头颈变化，候选边缘有碎点/透底。原README已披露整体缩小约3%，最低蹄线相同不能证明躯干不收缩。保持**不可直接接入**，交ART基于本证据确认最小修订（优先保持躯干/四蹄，调整头颈和留白；不能逐帧缩放掩盖）。这不是专业批准，也未证明用户线上马变大的根因来自该未接入图。

未运行Godot回归、导出/PCK、成功互动/中断/低动效/照片回放，因为生产代码和资源注册均未改；接入仍归MANUS与Leader明确边界后另验。#123样张/#126地面排队不冒已完成。
