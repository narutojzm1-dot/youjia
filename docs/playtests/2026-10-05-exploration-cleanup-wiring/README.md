# 探索收尾 cleanup 接线（CURSOR-CLOUD，#305 / #150）

接收 CODEX-LEAD 在 #305 的请求（[5995821794](https://github.com/narutojzm1-dot/youjia/issues/305#issuecomment-5995821794)，Cloud 回执 [5999078476](https://github.com/narutojzm1-dot/youjia/issues/305#issuecomment-5999078476)），按已冻结的[清理契约](../../architecture/exploration-cleanup-commit-contract.md)接探索侧。

## 之前的缺口

公开 `a067ce9` 受控故障：回院授予已确认后，紧接着的“清成空闲”那笔写入出错；一次“再确认一次”查明被拒，之后页面一直停在“保存暂时无法继续”，存档 session 仍是 pending_commit，直到关页重开。原因是 `ExplorationHost._persist_idle` 直接 `request_exploration_record`，没登记这笔 op，被拒后既不重交，Main 也没有能清掉它的后续编号。

## 现在的做法

- `ExplorationHost._persist_idle`（回院确认后的 `_finish`、重启时 `HOST_CLOSE`）：取 `get_exploration_record()` 完整原值、同一次的已提交水位、核心 close 后的空闲记录和本页 cleanup 身份，调用 `request_exploration_cleanup`，把返回的 op 登记为 `cleanup`。
- 明确拒绝之后：
  - `EXPLORATION_CLEANUP_PRECONDITION_CHANGED`：停，不重交、不覆盖。
  - 本页会话已不在这次收尾（例如新一趟已开始），或存档里已不是那份原记录、水位变了：停。
  - 其余拒绝（写失败、未知后查明被拒）：重交同一份冻结请求，最多 `MAX_CLEANUP_RESUBMITS = 2` 次，每次仍经队首完整比对。
  - `EXPLORATION_CLEANUP_INVALID_ARGUMENT`（契约外记录）：保留接入前的直接写入。
- 结果未知时不动，等 unknown/resolve 给出同一 op 的结论。
- `HOST_QUARANTINE_AND_RESET` 的隔离记录不在契约范围内，保持原来的直接写入。
- 每次重交（以及契约外回退写入）发 `cleanup_resubmitted(failed_ops, op_id)`，经 `ExplorationDirector` 转给 Main。Main 只把同一 cleanup 此前失败、`kind == "exploration_cleanup"` 的原样快照放进 `_save_retry_coverage[op_id]`；新编号确认后按快照精确清除，失败在绑定后又变了就不清；面板仍在队列空闲（`ready` 且 idle）且没有其他问题时才收起。
- 内存夹具 `test/fixtures/exploration_memory_store.gd`：清理接口的写前拒绝按真实协调器带回 typed 码；新增 `fail_kind_once` 注入一次写失败。

共享 Host/Gate/Coordinator、磁盘 schema、`request_exploration_cleanup` 本身均未改。

## 检查（`test/exploration_slice_suite.gd`，216/216）

新增 16 项。把宿主、导演、Main 三处改动换回接入前（只补测试引用的符号），10 项失败（205/215）：

- 正常回院一次清空；
- 清理写失败一次 → 重交 → 清空，带回物只授予一次，重交带上被拒编号；
- 清理结果未知 → 等待；查明被拒 → 重交一次 → 清空（公开复现的那种）；
- 新一趟已开始时旧清理被拒：不重交，存档是新旅程的 active 记录；
- 一直写不上：重交 2 次即停，每次带上此前全部被拒编号，记录留在已提交待清，授予不重复；
- 重启后原记录在队首前被改：`PRECONDITION_CHANGED`，不重交、不覆盖；
- 再重启：照常清空，不重复授予；
- 真实 Main：清理被拒显示面板 → 无关确认不收 → 重交编号确认后同页收起；绑定后失败又变了不收；
- 真实 SaveStore 回院往返后存档清成空闲，没有挂着的 cleanup、没有保存面板。

另跑 `tools/verify_daily_life.sh` 全量（一次性 `XDG_DATA_HOME`）。

## 范围

内存队列与真实 SaveStore 的 headless 检查。不是公开 Web 版受控故障复验，也不是 #150/#176 Web 持久化或真机验收；公开复验需在发布后按原受控注入路径重跑。
