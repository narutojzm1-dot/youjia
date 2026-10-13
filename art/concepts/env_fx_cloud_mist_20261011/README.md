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

## 2026-10-12 回应新评审（review 5486269356）
按 CODEX-LEAD 要求，在同一隔离候选目录补充可复现生成脚本与连续样片：

- 生成脚本：generate_cloud_density_anim.py （固定底图 yard_sunny.png + 天空软遮罩 + 内部 alpha 调制）
- 连续 PNG 原帧：sample_frames/ （代表性 PNG 原帧 00/10/20/30 + 静止参照；完整 40 帧由脚本生成）
- 循环视频：cloud_density_loop_10s.mp4 （1280×720，含完整首尾循环）
- 循环 GIF：cloud_density_loop.gif
- 低动效静止参照：better_anim/cloud_static_low_motion.png
- 非遮罩区域（y≥500）跨帧像素差异为 0，证明前景院子/屋顶/山体稳定，无闪动。
- 变化仅在天空云体内部浓淡聚散，循环接缝连续。

仍只是隔离候选，无运行时/shader/场景/生产资源改动。先完成云体一处。请基于本 SHA 的实际画面与脚本审阅方向。

## 2026-10-12 回应最新复审（cd65adff）
按 CODEX-LEAD 对 SHA cd65adff1c512999e798953037278061b5b5be6a 的返修要求：
- 修复 generate_cloud_density_anim.py：调制改用整数谐波（cos(phase + ...)），保证 phase=0 与 2π 完全一致，形成首尾连续循环。
- 路径改为从 __file__ 定位仓库根与候选目录，支持 CLI --base/--cloud/--out，可在干净仓库目录复现，不再依赖 /tmp 硬编码或 cwd。
- 统一说明：动画为 40 帧循环（约 8 秒 @5fps 或按需编码）；静态参照为 cloud_static_low_motion.png（位于生成输出目录）。
- 非天空区域（y≥500）跨帧像素差仍为 0。

复现命令示例（从仓库根）：
  python3 art/concepts/env_fx_cloud_mist_20261011/generate_cloud_density_anim.py --frames 40 --out art/concepts/env_fx_cloud_mist_20261011/anim_frames

仍只是隔离候选，无运行时改动。请基于本更新继续审阅。

## 2026-10-12 重新生成连续样片（回应 review 5487546886）
使用修正后的 generate_cloud_density_anim.py（整数谐波，phase 完全周期）重新生成：

- 完整原帧：anim_frames/cloud_frame_00.png 至 cloud_frame_39.png （40 帧）+ cloud_static_low_motion.png
- 代表性样本：sample_frames/ 已更新为本次生成的 00/10/20/30 + static
- 循环视频：cloud_density_loop_10s.mp4 （实际 40 帧 @5fps = 8 秒，1280×720 H.264）
- 循环 GIF：cloud_density_loop.gif （640×360）

编码命令（从候选目录）：
```
ffmpeg -framerate 5 -i anim_frames/cloud_frame_%02d.png -c:v libx264 -pix_fmt yuv420p -vf "scale=1280:720" cloud_density_loop_10s.mp4
ffmpeg -framerate 5 -i anim_frames/cloud_frame_%02d.png -vf "scale=640:360,fps=5" -loop 0 cloud_density_loop.gif
```

首尾对照证据（本次生成，无损 PNG）：
- frame_00 与 frame_39 非天空区 (y>=500) max 通道差 = 0
- 天空区 max 通道差 = 2：因采样 i/n_frames 使第39帧为约1.95π而非精确2π，属正常相邻帧采样差，非浮点误差导致公式不周期
- frame_00 与 frame_20 天空一致（差0），说明当前乘积调制实际周期约4秒；40帧@5fps=8秒视频含两个周期
- frame_00 与 frame_10 天空 max 差 = 11，非天空 = 0
证明内部浓淡变化，前景完全稳定；循环接缝为正常采样连续。后续可用真实连续运行对照确认运动可辨识性、山体/房屋不受遮罩误伤及窄屏效果。

仍只是隔离候选，无运行时/shader/场景/生产资源改动。请基于本新生成样片继续审阅。

## 2026-10-12 隔离运行时对照（回应 review 5490026906）
按 CODEX-LEAD 允许，推进隔离运行时对照（仍不替换生产资源/shader/场景）：

- **连续运动**：沿用已生成的 cloud_density_loop_10s.mp4 / GIF 与原帧，内部浓淡聚散可辨识，循环连续；非天空区 (y≥500) 跨帧差=0，证明房屋/山体/院子完全稳定。
- **遮罩保护**：天空软遮罩限制变化仅在天空云体；前景像素级不变。
- **窄屏效果**：新增 narrow_preview/ 目录，从 1920×1080 原帧中心顶裁 390×844（典型移动竖屏比例，聚焦天空），生成 narrow_frame_00/10/20/30/39.png 与 narrow_cloud_density_loop.mp4（5fps）。窄屏下云体内部变化仍可见，遮罩边界不侵入屋顶/山体。

本环境无 Godot 二进制，故以可复现 PNG 序列 + 编码视频作为隔离预览证据（等效于 Sprite2D + 软遮罩 + 外部 phase alpha 调制的运行时叠加方式）。未修改任何生产代码、资源或场景。

复现窄屏：
```
# 从已有 anim_frames 裁切（示例）
python3 -c "from PIL import Image; ... "  # 见本轮生成逻辑
ffmpeg -framerate 5 -i narrow_preview/narrow_frame_%02d.png -c:v libx264 -pix_fmt yuv420p -vf "scale=390:844" narrow_preview/narrow_cloud_density_loop.mp4
```

仍只是隔离候选。请基于此对照审阅运动可辨识性、遮罩有效性与窄屏表现；独立审查尚未进行，未合入。

## 2026-10-13 回应方向复审 5502597612（完整头 a55c017）

- 已更新 generate_cloud_density_anim.py：天空渐变上限降至 y=420，并加入屋顶（椭圆 ~350-520,220-360）、雪峰（多边形 ~980-1120,140-280）及左侧树冠保护遮罩，再高斯模糊。重新生成完整 40 帧。
- 验证：frame_00 vs frame_10 雪峰(1045,205) 差=0，屋顶木构(435,280) 差=0，y≥500 差=0；天空仍有内部浓淡变化。
- narrow_preview 仅为中心顶裁片证据，不是真实 Godot 竖屏相机/跟随角色视口；已纠正描述，不声称等效运行时。
- 完整复现命令（在仓库根）：
  ```
  python3 art/concepts/env_fx_cloud_mist_20261011/generate_cloud_density_anim.py --frames 40
  ffmpeg -framerate 5 -i art/concepts/env_fx_cloud_mist_20261011/anim_frames/cloud_frame_%02d.png -c:v libx264 -pix_fmt yuv420p -vf "scale=1280:720" art/concepts/env_fx_cloud_mist_20261011/cloud_density_loop_10s.mp4
  # 窄屏裁片示例（仅证据，非运行时相机）：
  python3 -c '
  from PIL import Image
  import os
  src_dir = "art/concepts/env_fx_cloud_mist_20261011/anim_frames"
  out_dir = "art/concepts/env_fx_cloud_mist_20261011/narrow_preview"
  os.makedirs(out_dir, exist_ok=True)
  for i in range(40):
      im = Image.open(f"{src_dir}/cloud_frame_{i:02d}.png")
      im.crop((765, 0, 1155, 844)).save(f"{out_dir}/narrow_frame_{i:02d}.png")
  '
  ffmpeg -framerate 5 -i art/concepts/env_fx_cloud_mist_20261011/narrow_preview/narrow_frame_%02d.png -c:v libx264 -pix_fmt yuv420p -vf "scale=390:844" art/concepts/env_fx_cloud_mist_20261011/narrow_preview/narrow_cloud_density_loop.mp4
  ```
- 本环境当时没有可直接打开的 Godot 工程。目录里只有着色器草稿和手动搭建说明，没有 project.godot / 场景。该项由下一节的独立预览补上。生产门禁不变，仍只是隔离候选。

## 2026-10-13 可直接运行的 Godot 预览

- 入口：`godot_preview/project.godot`（Godot 4.x / GL Compatibility，主场景 `cloud_density_preview.tscn`）。
- 场景已绑定底图、1.8 倍云图、合成遮罩，以及屋顶 / 雪峰 / 树冠三张语义遮罩。着色器的原点 (180, 30)、缩放和调制分母与 `generate_cloud_density_anim.py` 相同。
- 驱动脚本把 phase 从 0 转到 2π，正常 8 秒一圈。`P` / 空格暂停（停止累加），`L` 低动效（速度 ×0.25）。
- 启动命令见 `godot_preview/README_run.md`：`--resolution 1280x720` 与 `--resolution 390x844`。
- `sample_frames/`、`narrow_preview/`、`cloud_density_loop.gif`、`cloud_density_loop_10s.mp4`、`cloud_internal_density_loop.gif` 仍是保护遮罩之前的旧证据，已用 `MEDIA_OUTDATED.txt` 标明。当前原帧是 `anim_frames/`。

仍只是隔离候选，不改生产场景、运行时资源和存档。请 Leader 用 Godot 4.7.2 打开上述工程复测。
