# 2026-10-13 磨粉公开发布核验

CODEX-LEAD。实际完成时间：2026-10-13T15:24:13.221323+00:00。

- 最终公开源码 `34740e7e55ab0faebf7b2a2af3d2edf75600c2f7`，入口 `game-34740e7`。
- 发布 Actions：https://github.com/narutojzm1-dot/youjia/actions/runs/38414209271；Pages：https://github.com/narutojzm1-dot/youjia/actions/runs/38419361858，均成功；固定 gh-pages `1da8e14a977eebb9d668db05bebfa2d86a962691`。
- 公开清单、固定 gh-pages 清单和 HTML 的 source / entry / mainPack 一致。
- 独立完整下载公开 PCK 和固定 gh-pages PCK，均为 **89005136 bytes**，SHA256 `c8ce43cefb6f0ff8bff85a28c7cb7d99cf5aaae303e0690eb577fcc39f8f55cd`，并与 HTML 的完整性哈希、文件大小一致。原始结果见 [verification.json](verification.json)；89MB 包留本地核验，不重复入源码仓库。

## 运行来源与自动发布队列

PR797 最终头 `db2d8993dfeb76a5cab3f8f26cfbeb3b5d3a87f0` 已经完整 CI38409019162（201 Godot 套件及适用检查、Web导出）和 Leader review5505024954。与普通 Web 最终受测本地 `58b473abcd12dcbe2b6709dfd5204419a3216ec4` 同树 `e86f1801ae52486a2d19e228837e041097bb1fec`。

PR797 合入 `29904febf394818ee97ae033c821bb0c77fa726c` 仅额外包含 PR801 的四份策划。其 Publish38412871898 和 Pages38416042137 已成功，固定 Pages `dca01e198f692044b180e75649cc94a1cd311b1d`。只记录中间清单身份，没有重复下载它的全包或把它冒充最终版本。

随后 PR755 候选归档形成 `34740e7e55ab0faebf7b2a2af3d2edf75600c2f7`，额外82个文件全部在 art/，无运行代码变化。该目录由正式导出 exclude_filter 的 art/* 排除；这次合入触发另一轮自动发布。本次最终核验采用它实际产生的构建及包哈希，不沿用本地候选或299的哈希，不宣称新云雾已启用。

## 普通正式站点核验

- 既有 agent 测试标签页在中间发布后仍停留在 e13eec3 第24天的已暂停公告页，没有被强制刷新。未操作其他成员或用户的标签页。
- 最后部署完成后，使用普通正式 URL 打开新的浏览器标签页。未附加缓存绕过参数，未清缓存/站点数据/存档，未注入库存、时间或游戏状态。
- 10月13日实际进入普通小院，旧第24天仍保留；新磨盘在场景中。打开「歇一下 → 更新公告」观察到本包 `game-34740e7` 及自主磨粉、面粉三餐的公告。首次联网查询显示「暂时无法检查更新；以下是本版本公告」，未标最新。此观察来自当时实际UI，不补造未保存的公告截图。
- [正式场景](final-public-world.jpg)；[原第24天基线](before-release-day24.jpg)；[中间发布后旧标签保持原状态](old-tab-kept-playing-after-intermediate-release.jpg)。三张图均为10月13日保存的原始JPEG字节，无裁剪/重绘/拼接。
- 冷启动下载明显慢：264秒时仍为61%，随后自然进入首帧和小院，未点击重试、未清缓存。慢下载及公告间歇联网失败如实保留，未宣称已定位根因或所有网络环境均正常。
- 完整取麦/推磨/产粉/正常关页新开/次日用粉已在等价运行代码的普通本地 Web 覆盖，见[原整链证据](../2026-10-13-milling-web/README.md)和[最终候选纸面](../2026-10-13-milling-web/final-candidate/README.md)。本次公网没有重新走完全天所有生产步骤，截图也不冒充完整录像。

实际覆盖为10月13日 Windows 桌面 Codex IAB；不是实体手机或硬件触摸/人耳听验。旧长开标签停绘制根因、完整成长/自主园艺/榛子/经验树及后续院内灶台仍未完成。#700/#642 不因本次局部交付关闭。本记录于10月15日补归档；其他成员已有后续提交及发布，不将这个历史包写作10月15日当前最新版。
