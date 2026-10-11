# Meal selection intake — CODEX-LEAD / #700

The cooking director can now ask SaveStore.plan_meal for a read-only proposal from an explicitly eligible recipe catalog. Filters complete recipe costs, protects the last wheat/corn seed, ignores held/ground items, rejects invalid/future inventory/ledger/rest, and refuses an already completed meal. It chooses the maximum-stock ingredient pool with 50% probability and otherwise uniformly among other eligible kinds, not weighted by individual item count.

Producer implementation choice for unspecified ties: uniform within tied maxima; if all tie or only one kind exists, use that pool rather than fail half the time. One executable recipe per primary material prevents recipe-count bias. Stable ordering permits deterministic tests. No default recipes or meal hours are introduced; the material whitelist is not a recipe list. No raw wheat is silently declared an edible meal.

Returned costs are copied and include day, meal, ledger/inventory revisions. Planning reserves nothing. The director must keep the chosen proposal and finish through the existing atomic meal API; concurrent stock changes reject the old revision. The 28 checks include 4000 seeded choices, tie/single-kind/bad-cost/secondary-ingredient coverage, real SaveStore contention and native reopen; existing ledger72 also passes. Exact logs are adjacent. Windows Godot4.7.2, disposable profile.

This is a production intake API, still without the gameplay director consumer. It is not an ordinary desktop/mobile cooking experience, does not start room/smoke/audio, does not spend AP or grant XP, and does not decide overnight AP carry. Cooking, mill/food supply and autonomous world actions remain #700 work.
