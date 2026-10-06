# 探索运行时画面

| 文件 | 来源 | 状态 |
| --- | --- | --- |
| `near_path_02.webp` | [`art/concepts/producer_near_path_clean_v1/near_path_clean_candidate.png`](../../../art/concepts/producer_near_path_clean_v1/README.md)（SHA256 `ade3ee4108fb0726961fc83ae04f01effb21df6023501332909c45eaa278487b`，PR #393 最终 `c2f342d`），等尺寸 1672×941 转 WebP（质量 86），未裁切、缩放或重绘；清底底稿为 [`02_near_path.png`](../../../art/concepts/producer_world_20261005/README.md)（SHA256 `8ab62a6d43053e7bf7994e797a2ec07d79d369d46cbdee005700509bc6e0f154`） | 制作人清底版：去掉画内松果/落羽（7725 像素，全在 x1256–1428 / y761–841 掩膜内），避免与可拾物重复，见[换图证据](../../../docs/playtests/2026-10-05-near-path-clean/README.md)。仍不是美术终验，几何与路线未变 |
| `finds/pine_cone.webp` | GAME-PRODUCER [PR #361](https://github.com/narutojzm1-dot/youjia/pull/361) `5428245544a0c04bb14db2c0b6c89e6269271579` 的 `art/concepts/producer_pinecone_v1/pinecone_master.png`（SHA256 `a3bd4466d6954dce1d59b35a008a5346fdf9863f8f2ed2ebd75a5555d390fb1d`）；按 alpha>16 外框加 12 px 裁切，LANCZOS 等比缩到长边 256，无损 WebP（SHA256 `3b4b85319bd517bea1011eb3987b6445ea7e7851f811c7cc87bf54e3f5f7bfe6`），未改色或重绘 | 制作人独立候选，只供首片拾起演示；未标 runtime-ready，不是美术终验 |
| `finds/feather.webp` | GAME-PRODUCER [PR #364](https://github.com/narutojzm1-dot/youjia/pull/364) `23b776a2394a8507532e93219819b2e4d1553885` 的 `art/concepts/producer_feather_v1/feather_master.png`（SHA256 `f35d0c4f97127abb530f45307fef0c371bf3b18a0faae17474d81c7e668c211e`）；同上处理（SHA256 `3a210daa485c2a08c3a61ac9270d584d6833a1503f02d5923e72291ed23daa05`） | 同上 |

`art/` 不进 Web 导出，所以运行时需要这份副本。制作人交付修订版或清底分层后直接替换本文件，可走路与锚点在 `scripts/exploration/near_path_layout.gd` 按新画面重新校准。

`finds/` 下没有贴图的物件（目前是圆石）继续用 `KeepsakeArt` 占位画法；圆石候选 PR #285 仍带宽柔影、未通过审查，没有接入。
