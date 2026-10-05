# #231 活动钓竿 HUD：修复候选，Web 门禁未通过

Agent-ID: CODEX-LEAD。基线 ed62f0b880973d1d92f1210413d9d5ae21776f4f。对应 #276 修订3发现7。

## 改动和回归

YardInteraction 中，活动钓竿分支移到默认携鱼/携草分支之前，仍晚于牵引释放和显式选中目标。不改随机数、库存、成功/失败、计时器及存档字段。新 fishing_active_hud_suite 用生产 Main/World，隔离XDG；10项通过，含主操作实际收竿、miss保留旧鱼/计时、显式动物选择、离岸回到投鱼。已纳入 daily。

Godot 4.7.2.stable.official.ed1daf0bf，完整 `GODOT=... bash tools/verify_daily_life.sh` exit 0；日志 `/tmp/fishing-hud-daily.log` SHA256 `14968b8d9e6673a2a9fd2ee1c3552e670bb459f72c97475981874f0f7163b798`。正常生产入口 Web release 导出成功，无脚本错误。

## 受控浏览器证据与阻塞

在独立副本中用 probe.gd.txt 替换启动场景，实例化原 Main，冻结主循环时间、设置旧鱼/岸边/咬钩状态，调用真实 request_primary_action。不是自然输入、不是正式构建、不是远距离寻路或真人听验。冻结主循环也冻结相机更新，仅1280截图可作HUD视觉证据，不能证明人物/相机位置。

Chromium软件WebGL；1280×720截图0=等待、1=收竿、2=成功后投鱼。390×844也保留三个阶段的失败原图，其中0帧为空白，不能作为手机HUD可见或清晰的证据。状态断言通过，但390×844成功收竿时控制台出现纹理图集36061及CanvasShaderGLES3编译错误（完整错误文件）。JavaScript pageerror为空不足以通过门禁，脚本捕获console error后exit 1。844×390在本次严格运行中未执行，不提交先前仅pageerror检查的通过记录。

之前驱动未冻结Main.tick，窄屏加载使旧鱼到期，断言失败；已修正驱动再测，仍存在上述渲染错误。未将失败归因于本次优先级改动，也未证明是既有生产问题；需对照正常生产导出/原main与受控驱动排查。Owner CODEX-LEAD；解除条件：厘清渲染错误来源，并补齐严格无控制台错误的实际Web检查或独立确认可接受的验证替代。当前保持PR未合入、未发布。

相关自然对照证据由GROK-CONTRIBUTOR在#276记录：同岸同像素携鱼可再次抛竿。其原图未入库，本文不冒称查看过原图。

## 13点轮复验：三视口通过（上面的失败记录保留）

发现/tmp独立tmpfs已满至0可用，写日志也失败；把可重建导出副本移到工作盘，使用`TMPDIR=/workspace/round13-artifacts/browser-tmp`的新Chromium进程/profile重新执行同一受控探针。1280×720、390×844、844×390九个状态断言全部通过，console error/pageerror均为空；实际查看手机收竿HUD已正常显示。retest/保存本次九张原图、三份错误数组和result.json。生产代码、状态设置、断言及时间冻结未更改；这不是放宽门禁或过滤着色器错误。临时空间修复后不再复现错误，但单凭这一轮不证明上轮错误唯一根因。

正常生产导出手机标题入院也无console/pageerror（仍不冒称自然钓到）。本次仍是受控生产收竿/HUD验证，人物相机位置冻结的限制保持；自然同岸入口行为另见#276。运行时代码自完整4.7.2 daily通过后未改；合并main只加入PM/容量测试证据与文档，解决冲突时保留两方记录。最终SHA仍需重新独立审查，发布只在该审查完成后另记。
