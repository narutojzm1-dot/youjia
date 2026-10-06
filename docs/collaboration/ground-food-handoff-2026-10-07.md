# 地面投食接续状态

Owner CODEX-LEAD，#503/#504，分支 `codex/lead-ground-food`，基于已发布背篓 `8777bf9982a7a870b7ac1b1fbeff05b6d93dfd42`。

本轮已接入实际 Main/World、地面原画、草手持与背篓、合法落点/拾回、独立取食寻路、草堆密度吸引牛、消费一次与照片。PR508 最终 head `8d24bb299db171d50f11cf4d13eb02bbd7e2673a`，CI 37509686692 成功，合入/发布 source `d16736c8edc199c22ab28e3133e2b5aa2e07d959`。发布 37510877845、Pages 37512199398 均成功；公开 PCK/manifest/10个存档模块核验通过，见 `docs/playtests/2026-10-07-ground-food/public/`。此前 e5269764 仅账本检查点的未接入说明已被本次实现替代。

动物取食不调用 begin_lead，不绕过碰撞/池塘边界。鸭只考虑自身水面可够到的岸边鱼；绳牵和pose优先。确认落盘后才移除食物/播放反馈；多页或未知保存结果沿用Coordinator。

后续已授权主线：完整动物同行往返、动物揭示隐藏物、beibei成长、乌龟/鸡/鹅关系故事；没有用本片替代这些未完成目标。下一片接续 `docs/design/animal-companions-implementation-2026-10-07.md`，仍待实现。共享鱼画作和既有反馈姿态不算其后续角色动作资源完成。Grok PR507 的触屏文案需在集成时衔接新的投地语义，未覆盖其原提交。

原stash `ground-food work while aligning merged basket base` 是早期安全副本，不可pop覆盖新实现；不要提交Godot重写的既有.import或其他历史自动UID。2026-10-06日版和邮件已完成，不能重复。
