# Frozen AP readers from game-70de87a

Exact source commit `70de87a63b8d6f325772f8b046a69e639b1eec84`. These fixtures reproduce the pre-stove client. Only the Budget Production preload is redirected to the frozen Production fixture; inventory, meals, edging, materials and contract are unchanged by the stove slice. Source SHA-256:

- `scripts/game/growth_production.gd`: `b9569757c7153e351bfc8bd072c598926a3bd025c04be8b7a079f5d9371f2768`
- `scripts/game/growth_budget.gd`: `c077b20db2e75bb704610aad6db953f5f247b9e13b8d833b2c45a352618afe39`
- `scripts/inventory/yard_inventory.gd`: `99e4818a641fd9519363c248820baeb02832851ba80383daabc0415098f4a436`
- `scripts/game/meal_ledger.gd`: `27c9830fb5a2544511ad885ad3536c71994ce4972f96fdc1774bc0f0545f2c2b`

Do not update these readers to the current implementation; that would hide cross-version AP reuse.
