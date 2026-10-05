# 旧 IDBFS 两源原子只读捕获

CODEX-LEAD内部协作切片，基于研发分支 PR251 `39516cb02d491837a6943b01a3a81b157a9dac5d`。仅新增adapter/测试，不改store、bridge、生产SaveStore/Main、Cloud。尚未安装到生产，不是Host已冻结或探索可发布的结论。

## 接口及安全边界

```js
import {captureIdbfsSource} from './idbfs_source.mjs';
const snapshot = await captureIdbfsSource({
  primaryPath, backupPath, // 必须由生产Godot ProjectSettings.globalize_path提供
  budget: CANDIDATE_BUDGET // 复用既有明确budget profile；默认仍fixture
});
// snapshot直接供既有 decodeSourceSnapshot(snapshot, budget)
```

只枚举数据库名称/版本以确认固定`/userfs`存在，不打开其他数据库；只接受同一父目录下`youjia_save.json`、`youjia_save.bak`两个绝对`/userfs/...`路径，支持实际中文项目名，拒绝空段、控制字符、反斜杠、`.`/`..`及不同父目录。调用方必须信任引擎产生的路径，不能把玩家提供的任意路径直接转交本接口。

已知Godot4.7.2 schema：数据库version21，唯一store FILE_DATA，out-of-line键，无autoIncrement，唯一timestamp索引且keyPath=timestamp、非unique/非multiEntry。未知schema拒读，不尝试升级或修复。

两个get与两个getKey同时放入**同一个readonly事务**，区分缺键与已有undefined异常值。成功后冻结返回两源 `{status:'absent'}` 或 `{status:'present',base64}`；读取/能力/版本/schema/路径/记录类型/容量异常返回两源read_error，绝不降级为新玩家defaults。值只接受普通record对象、合法常规文件mode、有效Date、Int8Array或Uint8Array单字节内容；真实Godot本次实际写出的是Int8Array。保留原始字节，包括零长度和非法UTF8；UTF8/JSON/v5判断仍交既有decoder，不在捕获时投影或“修复”。

缺库时直接absent而不开库。枚举后库被删除的竞态：open触发onupgradeneeded立即abort，待open错误再枚举验证无新空库；若有并发重建则read_error且不删除它。任何情况下adapter都不调用createObjectStore、put、delete、deleteDatabase或挂载IDBFS。open/read等不到完成10秒返回read_timeout；较晚连接成功会关闭。indexedDB.databases缺能力或拒绝明确read_error。

这提供某一事务时间点的两源一致快照，**不持有旧页排他锁**，不承诺包含之后旧页的进展；也不把两份快照写入新Host。root仍须组合永久raw封存、独立新namespace、业务pending/confirmed以及旧新分支分歧处理。预算检查拒绝整份超限而不截断；IndexedDB结构化克隆已先把值读入内存，本上限不是浏览器RAM/磁盘quota保证。

## 真实验证与复跑

```sh
export GODOT=/path/to/Godot_v4.7.2-stable_linux.x86_64
# XDG_DATA_HOME需有4.7.2 Web导出模板
bash test/save_recovery_r1/export_idbfs_fixture.sh /workspace/idbfs-export
TMPDIR=/workspace/browser-tmp python test/save_recovery_r1/run_idbfs_source.py \
  --engine /workspace/idbfs-export --out /workspace/idbfs-result.json
```

夹具是独立最小Godot4.7.2项目，同生产项目名《悠长的假期》，真实FileAccess写两个user://路径；不是用JS伪造“Godot已同步”。旧页默认persistentPaths，用实际IDB字节轮询判同步完成。新页传persistentPaths:[]，真实引擎报告userfs不持久化，FileAccess写内存；旧库仍保存原值，旧页随后继续同步第二对。第三个全新浏览器context只运行无持久化页，写后不存在/userfs库。没有用用户浏览器profile，测试删除/造库只在新隔离context中。

实测globalize结果：`/userfs/godot/app_userdata/悠长的假期/youjia_save.json`与`.bak`，不得猜成固定hash路径。证据`idbfs-source-evidence.json`记录Godot双页断言、两次原始base64和Chromium版本。schema测试另覆盖：只读单事务且精确两键、缺库/空库/单键缺失、零字节、非法UTF8原字节、错误类型、未知version/store、fixture超限/candidate完整接收、30次并发写读的成对稳定和多个代际、捕获后写不改变已返值、事务abort、枚举缺能力与枚举后删除竞态。所有数据是合成夹具，不包含玩家存档。

这里只验证Chromium，不宣称Safari/Firefox、真实用户数据库权限失败或低端大档性能已通过。生产加载壳和完整游戏启用persistentPaths:[]仍需root组合验收；本切片只证实该配置在实际Godot引擎的隔离边界。

最终本切片验证：8/8真实Godot双页/浏览器检查、58/58真实IndexedDB/schema检查，console/pageerror=0，Godot4.7.2导入/导出通过，node --check通过。验证产物保留的不是生产发布证据；尚无远端PR/合入/公开部署。
