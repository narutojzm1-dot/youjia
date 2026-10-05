# Draft PR427 共享 cleanup 契约有限复现

Agent-ID: CODEX-LEAD（内部只读兼容审查 host_budget_impl）。仅判定 PR427 精确 `a69979b5c7148034d1598ea00ba6de2c413aa5d0`，不冒后续 head 的结果。本档不包含修复，不是新增前置审批或整单验收。

## 发现与范围

[审查报告](review.md)：正式 pending_commit、已提交水位1的受控记录含 `session.started_clock.future_payload={keep:raw}`。纯恢复返回close，391 cleanup拒绝未知字段；427回退普通record写后确认，当前session变null。真实SaveStore/Coordinator/Native文件链与内存队列各复现一次。属于本地人为构造的兼容边界，**不是公开用户档案已发生数据丢失的证据**。Native原始来源sidecar可能仍保全原文；发现针对当前权威文件被覆写、未满足391的写前拒绝保全契约。

两干净日志均Godot4.7.2运行exit0，Native记录`COORDINATOR true`、`BACKEND_CALLS 3`、`FILE_IDENTICAL false`，事件为cleanup INVALID_ARGUMENT后exploration confirmed。源码hash文件确认9个相关实现均与a699对象逐字节相同。无真实Web/IDB/全量回归，Main时序仅源码审读，未发现另一项已证实缺陷。

## 复现命令与条件

在独立完整检出的精确a699项目中，使用Godot4.7.2先完成正常资源导入。不要在玩家真实项目数据目录操作；以下使用全新的临时数据目录。将本目录两个`.gd.txt`文件复制为该隔离项目的`test/pr427_probe.gd`与`test/pr427_native_probe.gd`（文本后缀避免本档自动导入）。

```sh
mkdir -p /tmp/pr427-memory-data /tmp/pr427-native-data
XDG_DATA_HOME=/tmp/pr427-memory-data GODOT_SILENCE_ROOT_WARNING=1 \
  /path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path /path/to/isolated-a699 \
  --script test/pr427_probe.gd
XDG_DATA_HOME=/tmp/pr427-native-data GODOT_SILENCE_ROOT_WARNING=1 \
  /path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path /path/to/isolated-a699 \
  --script test/pr427_native_probe.gd
```

脚本自身建立测试记录、未知字段与水位，不依赖随机玩家物品，不读生产用户数据。实际诊断在/dev/shm隔离源码与数据目录运行，未改Cloud分支。最初harness曾有Variant类型警告、缺shader链接两个设置失败；补隔离harness/依赖后才获得随档干净结果，早期设置失败不算通过。未复制用户目录或原生存档到本档。

`review.md`中的/tmp路径是原运行位置；对应脚本、最终日志和源码验证已随本目录归档。`archive-sha256.json`覆盖本档全部文件（清单自身除外）。修复建议供Cloud原Owner判断实施：INVALID_ARGUMENT保守拒绝而非无条件直写；没有替其修改生产代码。
