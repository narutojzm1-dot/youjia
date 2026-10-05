# #180 马姿态切换尺寸：实际 Web 受控复现

- 执行：CODEX-LEAD 的独立证据子代理 horse180_repro，2026-10-05。
- 生产代码基线：`ba3bb72f9d78ddd2740403fb66a4a380c481e84e`。
- Godot 4.7.2 stable、Chromium 151、1280×720；独立探针场景直接实例化生产 FeltActor，调用生产 CastArt.configure / FeltActor.tick。未修改这些运行时代码，也未合入或发布修复。
- **这是受控组件复现，不是自然游玩、线上复现或 #180 鹅马组合验收完成。** 摄影、相册回放、导演、移动、不同景深位置未覆盖。

## 实际结果

12态均成功，console error / pageerror 均为0。每组依次 graze(idle贴图) → rest(tail贴图) → graze(idle贴图)。0–2正常右朝向；3–5正常左朝向；6–8低动效右朝向；9–11低动效左朝向。截图已人工查看；红线是固定脚底 y=470，蓝线是固定 x=640。

| 实测 | idle | tail | tail→idle |
|---|---:|---:|---:|
| 可见包围框高（屏幕像素） | 98.8087 | 76.5170 | +29.13% |
| 可见包围框宽（屏幕像素） | 105.4431 | 97.0395 | +8.66% |
| actor绝对scale | 0.08845899 | 0.08845899 | 不变 |
| Camera.zoom | (1,1) | (1,1) | 不变 |
| actor.position | (640,470) | (640,470) | 不变 |

`results.json` 是从实际引擎对象取回的数值，屏幕可见尺寸由实际 art_bounds × actor scale 计算，并非截图像素分割测量。截图可见 tail 画的身体更小；回到 idle 时整体轮廓突然增大，脚底仍在同一红线上。这能解释用户所见的一种“偶尔放大”，不声称覆盖所有放大来源。正常动效 probe 固定 breath=0、tick delta=0，以排除呼吸的轻微纵向变化；低动效重复仍有同样跳变。

## 定位与安全边界

CastArt.configure 按 idle alpha高度1117只算一次目标尺寸；tail alpha高度865，但 FeltActor.set_expression 切图只换anchor/bounds，不改 base_scale。结果不是这次测试中的相机zoom变化。更重要的是两幅画宽高差异不同，不能仅把tail等比乘1117/865就宣称修好：那会把tail宽度扩大到约125.3px，比idle105.4px大约19%。

优先资源修订：保持idle作为身份和固定比例基准，让tail的肩高、胸腹/背臀长度、腿长、落脚接触及画面比例与idle一致，再更新真实测得manifest。由ART-DIRECTOR对固定脚底叠图和实际Web切换验收。若短期需要工程止血，应明确评审临时保留idle/暂停不合比例tail切换的体验损失；不要改Camera.zoom、全体动物base_scale或鹅马导演挂点来掩盖资源差异。当前证据不授权自动撤掉姿态资源，也没有实施上述方案。

## 复现

在该基线的独立worktree中，将两个 `.txt` 探针文件复制为根目录 `horse_probe.gd` / `horse_probe.tscn`，只在该临时worktree把project.godot main_scene改为probe。导入并导出Web，HTTP服务8818。browser.py使用Playwright运行12态；按机器实际路径调整输出目录及浏览器。

探针不走生产Main，所以浏览器驱动在 `window.horseReport` 已存在后显式派发 `youjia:first-frame` 关闭加载遮罩；这不计作生产启动首帧测试。驱动直接切换姿态，不冒充自然触发。原始导入/导出日志及导出文件暂存 `/workspace/horse180-evidence/`；浏览器输出包含所有12态，脚本与截图在此留存。

## 最小止血候选（同轮后续，已获Leader明确执行指派）

候选仅删除 CastArt 对 horse_tail 的绑定，源PNG/manifest完整保留，等待同尺度美术修订。马休息继续显示idle，损失当前甩尾贴图变化；其他动物姿态、马移动/休息时长、触发/相机/挂点/摄影不改。

`fixed/` 为同一个受控探针在该候选的12态截图和对象记录（JSON source_sha仍标基础main；其上差异即本PR的CastArt改动）。全部姿态现为idle，12态可见高98.8087px、宽105.4431px一致，脚位/scale/Camera.zoom不变，console/pageerror=0。已人工检查修后rest帧。`interaction_pose_suite.gd` 35/35通过，包括12态实际运行时尺寸和脚位；这只解决此已复现路径，不把全部“马放大”或#180组合验收视为完成。
