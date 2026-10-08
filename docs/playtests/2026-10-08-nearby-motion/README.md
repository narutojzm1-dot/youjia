# #565 局部溪流草木动态候选与自测试

Owner：CODEX-LEAD-ASSISTANT，功能[PR586](https://github.com/narutojzm1-dot/youjia/pull/586)，最终源码`2179e80e481797b195529108c197c19323cb87bb`，基于已合入的PR569/585。构图与输入坐标保持，只在已有原画内部18处柔边区域移动采样。村落不套近郊遮罩，减少动态移除材质，暂停停止局部相位；设置在暂停中仍即时生效。相位不是世界时钟，不变更存档/拾物/库存/公共状态。

## 原生与完整CI

Windows官方Godot`4.7.2.stable.official.ed1daf0bf`：新局部动态/保护区/暂停/设置/跨图/释放/行程不变44项通过，直接拾物189、正式Main场景300项回归通过。完成门禁新增正数成功、零工作和失败摘要检查，完整门禁通过。最终头[CI37713679847](https://github.com/narutojzm1-dot/youjia/actions/runs/37713679847) SUCCESS，包含Linux全套检查与Web导出；原始日志在native。

## 实际像素与GPU测量

真实AMD Radeon8060S OpenGL兼容渲染，以1672×941原画比较两个相位：水3911、草木10097，共14008像素变化，约0.89%；遮罩外0变化。减少动态两个时间点逐字节相同，也与无材质原画相同，8项通过。三幅完整原始PNG与结果保留在render。

另按三个CSS视口/DPR2在实际小溪附近隔离原画渲染，用Godot视口CPU/GPU计时；每模式预热30帧、保留120帧，按静止→动态→静止交错。每视口保存原始像素见证，确认画面实际存在、启用动态时像素变化、禁用后还原。OpenGL draw counter返回0，此统计视为不可用，不能当作无绘制工作的通过证据。

|CSS视口/DPR2|动态GPU中位/P95（ms）|静止GPU中位前/后（ms）|
|---|---|---|
|390×844|0.054 / 0.068|0.053 / 0.056|
|844×390|0.053 / 0.075|0.052 / 0.053|
|1280×720|0.122 / 0.126|0.120 / 0.118|

遮罩解码6293408字节，约6MiB。这里只测桌面GPU的隔离原画渲染，不是完整游戏FPS或手机实机结论。计时接口定义参考[Godot RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-viewport-get-measured-render-time-gpu)，原始全部样本与工具保留在benchmark。首轮像素工具误用SubViewport属性、首轮基准工具误读frame.position的失败日志保留，修正并取得实际像素后才计通过。

## 普通Web流程与软件渲染观察

本地独立Web候选，Godot4.7.2，Chrome154.0.8037.98，DPR2触屏390×844/844×390、鼠标1280×720。三个视口均通过自然随机出门→点击可见物品自动走近拾取→点地→回院→HUD重进→回院→刷新重开，合计30个状态、0脚本错误，存档均只授予一次物品。只读网络与Host的records/current，不注入种子/存档/角色状态；实际加载PCK与10个存档模块逐字节相符。

通过正常prefers-reduced-motion平台偏好切换，记录两模式各120个rAF间隔。这是ANGLE SwiftShader/headless软件渲染，不是手机实机：两个触屏视口中位均49.9ms，桌面DPR2中位116.7ms；普通/减少动态接近，绝不把这些低帧率数字包装为30/60FPS性能合格。完整样本、P95、截图及平台偏好恢复记录保留。像素遮罩、功能回归及真实桌面GPU开销与该软件模拟分开验收，实机性能仍待独立QA设备复核。

候选PCK SHA256：`4423662b20033eaf908e729fb55b7fee9804c7e6237669fc603e2fc411e1a1c7`，19文件清单在bundle.json。本机大文件在`D:\games\youjia-test\assistant-recovery\nearby565-motion-web`，没有将PCK提交源码库。sha256.json核归档原始字节。

此目录不宣称正式公开发布、手机实机、真人审画或听验。整体#565继续进行：近郊公共时辰天气适配、晴阴雨夜同构图、星月、局部光照及音景仍待后续。Leader PR580仍在途时不另造公共时钟；可继续近郊侧资源与适配工作。
