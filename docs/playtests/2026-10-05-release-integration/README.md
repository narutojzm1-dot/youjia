# 2026-10-05 已发布集成证据归档

Agent-ID：CODEX-LEAD。本次只归档已实际运行的证据，不新增运行、部署或邮件，不将不同构建的体验合并成一次验收。

| 核对对象 | 精确来源与实际验证 | 边界 |
| --- | --- | --- |
| PR321 首次公开版 | `5f74afb1eaf521f0f2df9401138b248b560b04a4`；2026-10-05 08:23:16 UTC 实际读取公开 manifest / 下载 PCK；21,928,960 bytes，SHA256 `4bb5d3aadc897ec5309e258d511c10d6f5e99be3b50837d4eea406c49b070d78`，公开与 raw 一致 | JSON：`hidpi321-public.json` |
| PR321 公开浏览器冒烟 | 上述 5f74afb 发布构建；844×390 DPR2 canvas1688×780，390×844 DPR3 canvas1170×2532；自然首页/入院、暂停/Escape、视口旋转，两个 case errors 均为空 | `hidpi321-browser.json`。未注入状态；未验证动物点击命中。本归档实际查看横屏入院及竖屏暂停两张截图：画面显示、暂停菜单及音量控件可见；不替代完整操作/听觉验收 |
| 后续组合公开版 | `a75ae229430ef4f0329953af70e213ca7d59d622`；2026-10-05 08:53:08 UTC 实际读取 manifest / 下载 PCK；21,955,748 bytes，SHA256 `68ca43d75c56410cdb91833b1b6ae146c54cc168e43ee0178b05dd2fc803403b`，公开与 raw 一致 | JSON：`a75ae22-public.json`；包含已合入321/328/329/314。这里只证明构建来源和公开字节，不声称在该组合包重新完成全部行为回归 |
| PR328 存档候选内存一致性 | [原证据](../2026-10-05-save-candidate/README.md)：真实 FileAccess 故障72项、完整daily、自然照片→手账→真实关页重开恢复，浏览器0错误；候选 PCK `f2c1163e84554b25acc26df033815e298b671ea1180974e9430183771475c9ea` | 浏览器属于原PR源候选，绝不是 a75ae22 上重验；同步文件提交边界不等于新异步Host durable协议完成 |

试玩：https://narutojzm1-dot.github.io/youjia/ 。该可变地址之后可能发布其他版本，以上结论只对应所列时间、精确源 SHA 和 PCK。

关联：[PR321](https://github.com/narutojzm1-dot/youjia/pull/321)、[PR328](https://github.com/narutojzm1-dot/youjia/pull/328)、[PR330](https://github.com/narutojzm1-dot/youjia/pull/330)、[#149](https://github.com/narutojzm1-dot/youjia/issues/149)、[#150](https://github.com/narutojzm1-dot/youjia/issues/150)。PR330 的未启用 JS 模块已合入；Leader 正在独立生产集成树接入宿主、协调器与 SaveStore/Main，尚未发布该生产接线版本，不能从本归档推断新协议已在线生效。
