# 正式存档接线候选（#149 / #150，PR336）

Owner：CODEX-LEAD。此文描述 PR336 的实现候选，合入/发布/体验以最终 PR 和公开核验为准。探索方法由 CURSOR-CLOUD 维护；本变更不接管其场景、回院适配或共享新字段。

## 启动与确认边界

Web 壳先安装版本化 JS 模块，实际 Godot startGame 成功才放行 Host；引擎 `persistentPaths: []`，不再将 `user://` 挂为旧 IDBFS 写者。新库固定 `youjia-save-host-v1`，页面写者锁和单事务锁分别管理。启动检查完成前不进入默认小院。

首次迁移只读捕获真实旧 IDBFS 主/备两源。受支持的 Web 原文版本目前是 v5；其他版本、未来版本、读取失败或容量超限明确停止，不自动重置或降级。完整原文封存独立于业务投影，特殊空白、未知字段及超过 JSON 数值精度的原始文本仍可从 seal 导出；不承诺这些大整数在业务数值投影中无损。

原生启动从同一次可信读取取得 snapshot/token。旧整数版本1–5保留原主备 bytes 到永久侧档，再允许新写；坏主好备在原字节成功封存后可恢复。缺失绑定证据、未知版本、未保全的新损坏仍阻断，不用空档掩盖。同步兼容 setter 仅在队列 idle 时调用同一 Host 的 prepare/submit/resolve/ack；不能绕过来源守护。

## 游戏侧接口（供探索适配）

- `request_intent(kind, Callable(current_confirmed) -> candidate) -> String`：只表示已接收操作，返回本会话 op_id；绝不是已保存。闭包到 FIFO 队首才基于最新 confirmed 快照执行；保留其他 Owner 字段，不用提交时的旧整档覆盖。
- `request_patch`、`request_album`、`request_yard_progress`、`request_plant_state`、`request_first_fish_caught`、`request_animal_relationship_memory` 是既有生活字段的具体意图。相册合并已确认 IDs/对应照片。
- `commit_confirmed(op_id, kind)`：只有严格绑定的真实事务完成/读回才更新 getters/相册；该事件不是清理 ack 完成。`commit_rejected` 表示确认未写入；`commit_unknown` 不允许发放结果、立即重发或销毁当前世界。
- `flush_pending() -> bool`：等全部意图及 ack 清空；unknown/blocked 返回 false。`is_save_idle()` 区分空闲与两项队列之间的 ready。
- `retry_pending()`：只恢复同一未知写，或重试已确认写的清理 ack。不得拿任意迟到/错误身份回包当作确认。
- Web 旧同步 bool setter 拒绝，调用者必须完成异步消费适配；不能把 accepted 包装成旧 bool 保存成功。Cloud 在自己的分支维护探索新方法，组合生产验收尚须完成。

Main 保留当前会话未保存的照片；照片生成动效和“已保存”提示等待该照片确认。重试保存院子、关系、照片时，前一普通写成功不能提前隐藏照片待确认提示。返回标题/重新开始前等待完整队列，失败保留原世界。

## 旧页面与备份

旧版页面不能被新版本强制停写，因此新旧库物理隔离。每次新页面启动对照永久封存来源只读检查旧库；旧源改变/消失/不可读时显示恢复选择。可下载当前封套、永久初始来源和本次旧库原 bytes；不可读时明确备份不完整。选择继续只记用户已观察的精确来源摘要，不合并、不覆盖、不删除旧库。下次旧页又写入会再次提示。

此检查不是跨数据库原子快照，也不声称实时监视所有旧页面；捕获后旧页仍可能变化。没有账户同步或跨设备保证；腾讯云 #198 按用户要求延期。

## 预算与尚未完成范围

候选预算为源/普通写1.5MiB、导入3.5MiB、留存32MiB。超限保全拒绝，不截断；容量并未作为所有历史档均可迁移的承诺冻结。Web Locks、IndexedDB 与浏览器清理策略仍限制存储可靠性；本地受控事务 abort 不等于真实断电、实体手机或 Safari 验收。

版本化 `save-<source short SHA>` 目录与 HTML、manifest 一起发布，每个模块实际 SHA256 进入 manifest；保留旧目录使旧入口的相对导入不混版。必要门禁为完整 Godot 回归、严格解码/协调器/真实原生文件、真实 Web 自然生成与关页重开、受控迁移/故障和独立最终 SHA 审查。父单剩余共享物品身份/探索生产适配/容量与平台范围不得由本切片自动关单。
