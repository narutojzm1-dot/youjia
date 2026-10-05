# 旧存档业务投影共用入口

Owner CODEX-LEAD；#150，基线 main55030f3。本切片不改产品规则，不切换持久化后端。

`SaveDataCodec.defaults()`、`project(candidate)` 与 `clean_moments(raw, album)` 从现有 SaveStore 逐句提取。正式 SaveStore._load 仍先由 SaveFiles.recover 选来源，然后调用 project；保存及各调用方返回值保持原样。未来迁移来源的业务读入也须复用此入口，不另写第二套照片/关系/植物规则。

## 保全与业务状态是两个层次

- 原始 primary/backup 字节必须由迁移封套原样保留；此模块只产生与当前游戏相容的读入视图。
- 未知相册 ID 仍保留在 album；不合法/不匹配的照片快照沿用既有清理规则。未知顶层字段不进入当前视图，但原始 Dictionary 不被修改。
- `project` 不是版本判定器、输入验证器或 JSON 解码器，不接收原始字节；未知版本、读错误、损坏来源的拒绝仍由迁移层负责。不能因为投影成功就替换或删除源文件。
- `defaults` 只服务既有载入路径；迁移发现坏档时不得用 defaults 静默创建“新档”。

## 后续正式接入顺序（仍归 Leader）

1. 定义启动恢复状态，阻止所有旧业务 setter 在迁移期间更改内存及写盘；仅阻止 save() 不足以保证快照一致。
2. 明确 Web user:// 初次同步就绪及多页/旧客户端所有权。新 Host 的 Web Lock 不能锁住不遵守锁协议的旧发布页，不得据此声称已停止旧写入。
3. 在独占来源下捕获原文，导入封套持久读回，再将被选来源交同一 codec 形成业务视图；异步未决不能显示保存成功。
4. 所有生产提交统一通过 Host durable 回执及恢复消费，不让 SaveFiles 和新 Host 并行写；完成容量/配额与正式浏览器重载检查后才冻结 #150。

本切片仅消除第3步中重复转换逻辑；不把已有隔离139/109/16/8检查替代正式迁移验收，不要求 Cloud 为未改桥接接口重跑旧矩阵。


## 时间与花圃的写入单位
YardWorld 定时/离院的 `_save_progress` 使用 `SaveStore.set_yard_progress`，一次提交同一快照内的时间与花圃字段。提交失败不会把候选发布到 SaveStore 内存；活跃 YardWorld 仍保留自己的状态，沿既有保存时机重试。该修正不回滚玩家场景、不新增失败弹窗，也不保证关闭页面后重试。独立 setter 的历史语义未改变；所有业务消费统一到异步 durable 仍属于后续迁移工作。

`test/yard_snapshot_suite.gd` 通过真实生产 World→Store→SaveFiles 验证完整备份，并用临时目标被目录占用造成真实写入失败。仅允许 daily runner 的临时 XDG 环境，裸跑拒绝；以 `GODOT=<4.7.2> bash tools/verify_daily_life.sh` 执行。浏览器正常启动/重载检查不等于强退、掉电或双页所有权验证。
