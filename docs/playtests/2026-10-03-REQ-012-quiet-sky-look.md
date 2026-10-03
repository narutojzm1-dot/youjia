# REQ-012 切片 C · 安静抬头微推 · 实现记录

- 构建：`game-6a20cdc`
- 来源提交：`6a20cdc155d60c5c3259fde7ee0c27543c077ec9`
- Actions：[37100630995](https://github.com/narutojzm1-dot/youjia/actions/runs/37100630995)
- 需求：REQ-20261002-012 切片 C（先无道具）
- Agent-ID：`CURSOR-CONTRIBUTOR-LOCAL`
- 日期：2026-10-03

## 范围

- 玩家几乎静止约 5.5 秒后，镜头轻微上移并略放大，把天空/云带带进画面
- 走动立刻取消；无新提示、无道具、不写相册
- 长于栅栏草叶停留（2.5s）与鹅马静坐等待（3.5s），避免抢镜头
- 结束后约 28 秒冷却
- 鹅马演出让出时清抬头状态，但不发 `camera_release`（避免抢镜头）

## 实现 PR

- 功能：[#88](https://github.com/narutojzm1-dot/youjia/pull/88)（`2b485ce` / `70fd2b5`）
- 测试稳定：[#89](https://github.com/narutojzm1-dot/youjia/pull/89)、[#92](https://github.com/narutojzm1-dot/youjia/pull/92)、[#94](https://github.com/narutojzm1-dot/youjia/pull/94)
- #94 根因：GDScript 闭包对 `int` 重绑定不可靠，release 计数改用 `Array` 原地修改

## 自动化

- `test/quiet_sky_look_suite.gd`：等待阈值、触发焦点、cancel/走动释放、鹅马让出不 release、不写相册
- CI `Run game verification` 在 Actions `37100630995` 通过

## 发布

- 正式 Web：`game-6a20cdc`（Pages 入口 `data-build="game-6a20cdc"`）
- 公网 PCK：13,744,764 字节，SHA-256 `66846e6003c73a720c324e0e31158566f77bd99db8d3461dff5face863556a2a`
- 建议实玩：站定约 6 秒看镜头是否轻抬入云；走动应立刻回落；无新提示、相册不新增条目
