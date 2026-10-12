# 绘本风格云体与薄雾候选（#749）

Agent-ID: GROK-BUILD

本目录为候选样本，不覆盖任何运行时资源，不接入动态，不改变现有 shader 或场景。

## 候选文件
- cloud_candidate.png ：低对比、不规则软边云带示例，水彩纸纹感，避免硬边或圆形斑点。
- mist_candidate.png ：半透明分层薄雾示例，底部接地、随高度变淡，保持原画质感。

## 隔离对照预览（叠加于现有原画）
回应 CODEX-LEAD 反馈（检查 SHA c388962cc6dc31e13709419331fc57e94c7220b3）：补充叠加对照，标明底图与参数。同一构图两个时间点（静态模拟轻微变化，非运行时动画）。

### 云体于小院晴天
- 底图：assets/holiday/environment/yard_sunny.png （1920×1080）
- 候选：cloud_candidate.png ，缩放 1.8× ，位置约 (200,50) 覆盖天空区域
- t1：alpha 乘数 0.7 → overlay_cloud_on_yard_sunny_t1.png
- t2：位置微移 (220,60)，alpha 乘数 0.5 → overlay_cloud_on_yard_sunny_t2.png
- 检查点：软边是否形成贴片边界、是否洗白主体建筑/院子、晴天可读性。

### 薄雾于近郊小路
- 底图：assets/holiday/exploration/near_path_02.webp （1672×941）
- 候选：mist_candidate.png ，缩放 1.5× ，位置约 (100,400) 贴合中下区域
- t1：alpha 乘数 0.6 → overlay_mist_on_near_path_t1.png
- t2：位置微移 (120,420)，alpha 乘数 0.4 → overlay_mist_on_near_path_t2.png
- 检查点：局部浓淡是否洗白主体路径/植被、边缘是否矩形/全幅泛白、近郊可读性。

参数为静态合成示意，用于判断方向；真实动态（内部舒卷/聚散）仍待后续技术验证与 ART-DIRECTOR 样片评价。保持现有运行时、shader、场景和生产素材不变。

## 风格要点
- 云体：位置可固定，内部仍有舒卷明暗变化的余地；保留手绘色块。
- 薄雾：局部浓淡聚散，贴合湖面/山坡，避免矩形边或全幅泛白。
- 溪流部分留给后续技术验证后补候选。

仍只是候选。请 ART-DIRECTOR 审阅这些对照画面后决定修改方向或是否进入接入。

## 2026-10-12 回应审查（review 5485498088）
本轮按 CODEX-LEAD 要求在隔离候选目录返修：
- 云体：新增 overlay_cloud_sky_masked_t1.png ，使用天空区域软遮罩，限制在天空，避免覆盖屋顶/山体主体。
- 薄雾：新增 overlay_mist_valley_masked_t1.png ，限定中远山谷/湖面区域遮罩，保护前景路径与纸边。
- 并排对照：side_by_side_cloud_original_vs_masked.png 、 side_by_side_mist_original_vs_masked.png 。
- 连续短动画：cloud_internal_density_loop.gif （6帧循环），展示内部浓淡聚散变化（非单纯整体平移或全局alpha），用于辨认动态感。

仍为静态/隔离候选，无运行时、shader 或生产代码改动。先完成云体一处效果。请基于这些画面继续审阅方向。
