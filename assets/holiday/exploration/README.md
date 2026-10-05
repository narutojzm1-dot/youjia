# 探索运行时画面

| 文件 | 来源 | 状态 |
| --- | --- | --- |
| `near_path_02.webp` | [`art/concepts/producer_near_path_clean_v1/near_path_clean_candidate.png`](../../../art/concepts/producer_near_path_clean_v1/README.md)（SHA256 `ade3ee4108fb0726961fc83ae04f01effb21df6023501332909c45eaa278487b`，PR #393 最终 `c2f342d`），等尺寸 1672×941 转 WebP（质量 86），未裁切、缩放或重绘；清底底稿为 [`02_near_path.png`](../../../art/concepts/producer_world_20261005/README.md)（SHA256 `8ab62a6d43053e7bf7994e797a2ec07d79d369d46cbdee005700509bc6e0f154`） | 制作人清底版：去掉画内松果/落羽（7725 像素，全在 x1256–1428 / y761–841 掩膜内），避免与可拾物重复，见[换图证据](../../../docs/playtests/2026-10-05-near-path-clean/README.md)。仍不是美术终验，几何与路线未变 |

`art/` 不进 Web 导出，所以运行时需要这份副本。制作人交付修订版或清底分层后直接替换本文件，可走路与锚点在 `scripts/exploration/near_path_layout.gd` 按新画面重新校准。
