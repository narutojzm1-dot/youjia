# Exploration trip capacity: public receipt, 2026-10-10

Agent-ID: CODEX-LEAD. Related: #642, PR #696. This is a verified incremental delivery, not completion of the flower garden or the overall playable-game Goal.

## Released build

- Implementation local author: `7b86a1a031766b4ff7be9ba129cf2e5ef3ec8e4e`; equivalent API head: `6ee71221c01c3bf5f328f222b498048657bfc40b`; identical tree: `7e46a03d9e948303deff16bcc178578f8c98d899`.
- Merged/public source: `bfbf652d8c26f5da985f9bf5ab655e5e37d8dfd7`.
- [CI 38047481937](https://github.com/narutojzm1-dot/youjia/actions/runs/38047481937), [Publish 38048667252](https://github.com/narutojzm1-dot/youjia/actions/runs/38048667252), [Pages 38049618015](https://github.com/narutojzm1-dot/youjia/actions/runs/38049618015): success.
- gh-pages commit: `170d0c4c4d1041c9a2a72ebbf9a92faf6af39460`.
- Actual public PCK: 69,548,440 bytes; SHA256 `8aa642ed8486e6bb0a25de5123afccc03368bc000869a7f3c22f06025cca896e`.
- Public HTML: SHA256 `cf15c18f0f142f739dc9a36834d8917123c51267f54634beaae869059259b504`.
- [verification.json](verification.json) records downloaded public bytes, source and hashes. HTML/PCK match gh-pages blobs; ten storage modules, four engine assets and two loader assets verified.

## Behavior and validation

At the FIFO commit boundary, aggregate the entire exploration trip before granting anything. If any keepsake cannot fit, reject with `EXPLORATION_KEEPSAKE_LIMIT` without modifying disk bytes or advancing the trip watermark. The deferred proposal remains retryable. Main releases only this rejected transient save identity; this does not become a global disk-error panel. Duplicate and empty returns remain valid.

- Original SaveStore negative control: 27 failures in 43 checks. Final native suite: 48 checks, zero failures; GPU variant: 49 checks, zero failures.
- Exploration: 300/300; save feedback: 50/0; coordinator: 86/0. CI independently ran the 48-check capacity suite successfully.
- Native coverage: mixed item ordering, aggregate repeated IDs, exact fit, empty return, duplicate replay, FIFO competitor, unchanged rejection bytes, failure/reopen/retry after making room, and Main transient identity cleanup. Native fixture uses capacity 9999; this is not manually accumulated gameplay.
- Local Web export succeeded. Real browser clicks: pinecone → walk and collect → return to yard → basket quantity 1 → close tab and reopen → quantity still 1. No save/time/game-state browser injection. Screenshots: [carried](../2026-10-10-trip-capacity/web/pinecone-carried.jpg), [returned](../2026-10-10-trip-capacity/web/pinecone-returned.jpg), [reopened](../2026-10-10-trip-capacity/web/pinecone-reopened.jpg).
- Public normal URL loaded `game-bfbf652`, showing 0.2.0 / 第2版内部测试. Existing Day 21 night save restored: [yard](old-day21-restored.jpg), [basket](old-basket-restored.jpg). Basket visibly retains stone ×3, pinecone ×2, wheat ×2, corn ×2.

Browser capacity-9999 behavior, physical mobile touch, and actual audio listening were not covered by this receipt. Ordinary Web persistence round-trip and public old-save recovery were covered.

## Next delivery

#642 stays open. Flower art is a separate local unpublished candidate, commit `010c5908bb0bd53856efb4fcaf050060dba9b2ff` on `codex/lead-flower-beds-642`: seven atlas/clear-patch assets plus native contact preview. It is not runtime-integrated, accepted final art, or published. Continue flower removal/restoration, planting/return-to-basket, persistence and frozen photo layers, preserving old photos and Assistant ownership of the nearpath module.

This receipt is not the 23:00 daily release report. No additional outgoing email was sent.
