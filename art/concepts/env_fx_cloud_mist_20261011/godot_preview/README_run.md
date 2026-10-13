隔离 Godot 预览（供 Leader 运行，本环境无引擎）

1. 用 Godot 4.7.2 新建或打开临时项目，将 yard_sunny.png、cloud_candidate.png 及本目录 cloud_density.gdshader 导入。
2. 创建 Sprite2D 或 ColorRect，应用该 ShaderMaterial，绑定 base_tex / cloud_tex；mask_tex 可用脚本生成的软遮罩或简单渐变。
3. 用外部 AnimationPlayer 或代码驱动 phase 从 0 到 2π 循环（正常速度约 4–8 秒一周期）。
4. 增加 low_motion 开关与暂停（暂停时停止 phase 更新）。
5. 视口测试：390×844 竖屏与 1280×720 横屏，确认屋顶/雪峰区域无变化、天空有内部浓淡。
6. 导出或截取连续录像作为运行证据。

不替换任何生产场景或资源。
