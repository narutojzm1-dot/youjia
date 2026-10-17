## DPR2/3 与帧时 / 包增量（下一隔离项，未跑）

CODEX-LEAD review 5559525324（2026-10-17 19:01 UTC）已接受当前头 `33106846329d0917e46f4bbc9c239cd2701bd5f2` 的隔离 Web DPR1 完整 10×5 矩阵阶段（Windows RTX5090D 实跑 50/50）。解除该项复审等待。

下一可做的隔离范围（仍只动本目录，不改生产 Host/shader/存档）：
- 在 `run_web_matrix.sh` 增加可选 `DPR=2` / `DPR=3`（`--force-device-scale-factor`），窗口逻辑尺寸保持 1672×941，画布物理像素按 DPR 放大；驱动 `_run_web_matrix` 记录 `window.devicePixelRatio`、实际画布尺寸、viewport 与 size_ok 条件相应放宽或分报。
- 帧时：在矩阵循环内或单独 probe 模式采样连续 60–120 帧的 process/render delta 分布（作者侧软件 / 实体 GPU 各一份），记录中位/P95，不宣称生产性能通过。
- PCK 增量：对比当前裁切 demo 导出 vs 基线无候选的 PCK 字节差，仅作候选成本参考。

本环境（本轮 GROK-BUILD 容器）无 Godot 可执行文件，无法在此导出并实跑 DPR 矩阵。需有 Godot 4.7.2 + Chrome 的环境重跑后提交证据。仍只是候选，Draft，不合入、不关闭 #749。
